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
		super({})

		@db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		
		@onopen    = method(:onopen)
		@onmessage = method(:onmessage)
		#@onerror   = method(:onerror)
		@onclose   = method(:onclose)
	end

	def onopen()
	 	puts "Socket opened" 
	end

	def onmessage(msg)
		if msg.eql? "next"  
			
			tag_query = "select tag_id from tags"

			if not defined?(@tags).nil? and not @tags.empty?
				tag_query += " where tag in (\'#{@tags.join('\',\'')}\');"
			end

			tag_ids = @db.execute(tag_query)

			url_id_query = "select url_id from url_tags where tag_id in (\'#{tag_ids.join('\',\'')}\');"
			url_ids = @db.execute(url_id_query)

			puts "Found #{url_ids.length} results"

			url_id = url_ids.sample[0]

			unescaped_url = @db.execute("select url from urls where url_id = #{url_id.to_s}")[0][0]
			url = URI.escape(unescaped_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
			
			result = BandcampAPI.instance.url_info(url)
			
			if result.has_key? 'track_id'
				track_id = result['track_id']
			
				track = BandcampAPI.instance.track_info(track_id)
			else
				album_id = result['album_id']
				
				album = BandcampAPI.instance.album_info(album_id)
				
				track = album['tracks'].sample
				
				track['album_name'] = album['title']
			       	track['album_url'] = album['url']	
			end

			band_id = track['band_id']
			
			band = BandcampAPI.instance.band_info(band_id)

			track['band_name'] = band['name']
			track['band_url'] = band['url']

			if track.has_key? 'album_name'

				album_id = track['album_id']
				
				album = BandcampAPI.instance.album_info(album_id)

				track['album_name'] = album['title']
			       	track['album_url'] = album['url']	
	
			end

			puts track

			send track.to_json.to_s
	
		else
			@tags = msg.split(',')
		end
	end

	def onclose()
		  puts "WebSocket closed" 
	end

	def onerror()
	end
end
