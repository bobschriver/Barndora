require 'socket'
require 'rubygems'

#yeah this is a bad way of storing my api key whatevs
require './api_key.rb'
require './bandcamp_api.rb'

require 'bundler/setup'

require 'sqlite3'
require 'em-websocket'
require 'json'

class WebsocketServer < EM::WebSocket::Connection
	def initialize(*options)
		#Need to initialize our base class
		super({})

		@db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		
		#Define our methods, I guess this is necessary?
		@onopen    = method(:onopen)
		@onmessage = method(:onmessage)
		@onclose   = method(:onclose)
	end

	def onopen()
	 	puts "Socket opened" 
	end

	def onmessage(msg)
		if msg.eql? "next"  
			
			tag_query = "select tag_id from tags"

			#If we don't have any tags defined, just select them all
			if not defined?(@tags).nil? and not @tags.empty?
				tag_query += " where tag in (\'#{@tags.join('\',\'')}\');"
			end

			tag_ids = @db.execute(tag_query)

			#Need to select all tracks with those tags	
			track_id_query = "select track_id from track_tags where tag_id in (\'#{tag_ids.join('\',\'')}\');"
			track_ids = @db.execute(track_id_query)

			puts "Found #{track_ids.length} tracks"

			#Here is where we would put any sort of weighted choice on tracks, rather than random sampling
			#Currently, tracks with more tags in the desired tags will show up more
			track_id = track_ids.sample[0] 
			
			#Get the track info
			track = BandcampAPI.instance.track_info(track_id)
			puts track	

			#Need to return the album info
			album_id = track['album_id']
			album = BandcampAPI.instance.album_info(album_id)
			puts album
			
			track['album_name'] = album['title']
			track['album_url'] = album['url']	
			
			if not track.has_key? 'large_art_url'
				if album.has_key? 'large_art_url'
					track['large_art_url'] = album['large_art_url']
				end
			end

			#Need to return the band info
			band_id = track['band_id']
			band = BandcampAPI.instance.band_info(band_id)
			puts band
			
			track['band_name'] = band['name']
			track['band_url'] = band['url']

			puts "Track " + track['title'] + " Album " + track['album_name'] + " Band " + track['band_name']

			@prev_track = track_id

			send track.to_json.to_s
	
		else
			#Lets assume for now that something bad isn't in tags
			@tags = msg.split(',')
		end
	end

	def onclose()
		  puts "WebSocket closed" 
	end
end
