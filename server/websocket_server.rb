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
		command , args = msg.split(':')
			
		puts "Command " + command + " Args " + args

		if command.eql? "next"  

			rating = args.to_i

			if not defined?(@prev_track).nil?
				current_rating_query = "select rating from track_ratings where track_one = #{@prev_track} and track_two = #{@curr_track}"

				current_rating = @db.execute(current_rating_query)


				#Could probably do an insert or update sql thing here
				if current_rating.empty?
					insert_rating_query = "insert into track_ratings (track_one , track_two , rating) values(#{@prev_track} , #{@curr_track} , #{rating})"

					puts insert_rating_query

					@db.execute(insert_rating_query)
				else
					new_rating = (rating + current_rating[0][0].to_i) / 2

					update_rating_query = "update track_ratings set rating = #{new_rating} where track_one = #{@prev_track} and track_two = #{@curr_track}"

					puts update_rating_query

					@db.execute(update_rating_query)
				end


			end

			if not defined?(@curr_track).nil?
				@prev_track = @curr_track
			end

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
			
			if track_ids.empty?
				error = Hash.new
				error['error_type'] = 'no_results'
				error['error_message'] = "Sorry, those tags are too hip. I can't find any tracks that match them!"

				return error
			end

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
			if band.has_key? 'url'
				track['band_url'] = band['url']
			else
				track['band_url'] = 'http://' + band['subdomain'] + '.bandcamp.com'
			end

			puts "Track " + track['title'] + " Album " + track['album_name'] + " Band " + track['band_name']

			@curr_track = track_id

			send track.to_json.to_s
	
		elsif command.eql? 'tags'
			
			#We should probably reset the current track here
			
			#Lets assume for now that something bad isn't in tags
			@tags = args.split(',')

		end
	end

	def onclose()
		  puts "WebSocket closed" 
	end
end
