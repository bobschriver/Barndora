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
	
		@prev_tags = nil
		@prev_tag_selector = nil
	end

	def onopen()
	 	puts "Socket opened" 
	end

	def onmessage(msg)
		command , args = msg.split(':')
			
		#puts "Command " + command + " Args " + args

		if command.eql? "next"  

			rating = args.to_i

			update_ratings(rating)

			#Need to check if we have the same tags here
			tag_ids = get_tags()
			
			if tag_ids.empty?
				return
			end

			track_ids = get_tracks(tag_ids)

			if track_ids.empty?
				return
			end

			#Here is where we would put any sort of weighted choice on tracks, rather than random sampling
			#Currently, tracks with more tags in the desired tags will show up more
				
			weighted_track_ids = Array.new
			if not defined?(@prev_track).nil?
				get_ratings_query = "select track_two, rating , num_ratings from track_ratings where track_one = #{@prev_track}"

				curr_ratings = @db.execute(get_ratings_query)

				if not curr_ratings.empty?
					
					puts "WHOAH FOUND A MATCH FOR RATINGS"
					ratings_intersection = curr_ratings.keep_if {|current_rating| track_ids.include?(current_rating[0])}

					puts ratings_intersection

					weighted_track_ids = ratings_intersection.map{|current_rating| Array.new(current_rating[0] , current_rating[1])}.flatten

					puts weighted_track_ids
			
				end
			end
			track_ids = track_ids + weighted_track_ids

			puts "Found #{track_ids.length}"

			track_id = track_ids.sample[0] 
			
			#Get the track info
			track = BandcampAPI.instance.track_info(track_id)


			#Need to return the album info
			album_id = track['album_id']
			album = BandcampAPI.instance.album_info(album_id)
			
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
			
			track['band_name'] = band['name']
			
			if band.has_key? 'url'
				track['band_url'] = band['url']
			else
				track['band_url'] = 'http://' + band['subdomain'] + '.bandcamp.com'
			end

			track['message_type'] = 'track'

			#puts "Track " + track['title'] 
			#puts "Album " + track['album_name'] 
			#puts "Band " + track['band_name']

			@curr_track = track_id

			send track.to_json.to_s
	
		elsif command.eql? 'tags'
			
			#We should probably reset the current track here
			
			#Lets assume for now that something bad isn't in tags
			@tags = args.gsub! /"/ , ''

			puts @tags

			if @tags.nil?
				@tag_selector = 'UNION'
				@tags = args.split(',')
			else
				@tag_selector = 'INTERSECT'
				@tags = @tags.split(',')
			end

		elsif command.eql? 'about'
			message = Hash.new

			message['message_type'] = 'normal'

			message['message'] = "Bandora is a cross between <a href='http://bandcamp.com'>Bandcamp</a> and <a href='httP://pandora.com'>Pandora</a>."
			message['message'] += "</br>"
			message['message'] += "The source for this project is on <a href='https://github.com/bobschriver/Barndora'>github</a>!"

			send message.to_json.to_s

		elsif command.eql? 'get_tags'

			message = Hash.new

			message['message_type'] = 'normal'
			message['message'] = ""

			tags_query = "select tag from tags"

			tags = @db.execute(tags_query)

			tags.each do
				|tag|

				message['message'] += "<a href='#' onclick=\"add_tag('#{tag[0].to_s}')\">#{tag[0].to_s}</a> "
				#message['message'] += tag[0].to_s + " - "
			end

			send message.to_json.to_s

		elsif command.eql? 'help'
			message = Hash.new

			message['message_type'] = 'normal'

			message['message'] = "rock,California = get tracks tagged rock OR California"
			message['message'] += "</br>&quot;rock,California&quot; = get tracks tagged rock AND California"

			send message.to_json.to_s

		end
	end


	def update_ratings(rating)
		if not defined?(@prev_track).nil?
			current_rating_query = "select rating,num_ratings from track_ratings where track_one = #{@prev_track} and track_two = #{@curr_track}"

			rating_info = @db.execute(current_rating_query)


			#Could probably do an insert or update sql thing here
			if rating_info.empty?
				insert_rating_query = "insert into track_ratings (track_one , track_two , rating , num_ratings) values(#{@prev_track} , #{@curr_track} , #{rating} , #{1})"

				puts insert_rating_query

				@db.execute(insert_rating_query)
			else
				current_rating = rating_info[0][0]
				num_ratings = rating_info[0][1]

				new_rating = (rating + current_rating.to_i) / num_ratings

				update_rating_query = "update track_ratings set rating = #{new_rating} , num_ratings = #{num_ratings + 1} where track_one = #{@prev_track} and track_two = #{@curr_track}"

				puts update_rating_query

				@db.execute(update_rating_query)
			end
		end

		if not defined?(@curr_track).nil?

			#Don't update the previous track unless they liked it. In this way we work off the last track they liked
			if rating > 0
				@prev_track = @curr_track
			end
		end


	end

	def get_tags()
		tag_query = "select tag_id from tags"

		#If we don't have any tags defined, just select them all
		if not defined?(@tags).nil? and not @tags.empty?
			tag_query += " where tag in (\'#{@tags.join("\' , \'")}\')"
		end
			
		puts tag_query

		tag_ids = @db.execute(tag_query)

		if tag_ids.empty?
			error = Hash.new
			error['message_type'] = 'error'
			error['error_message'] = "Sorry, those genres are too hip. I don't have any of those genres indexed!"
		
			puts "Couldn't find tags"

			send error.to_json.to_s
		
			@tags = @prev_tags
		end

		return tag_ids
	end

	def get_tracks(tag_ids)
		if @tags.eql? @prev_tags and @tag_selector.eql? @prev_tag_selector

			track_ids = @prev_tracks
		else
			@prev_tags = @tags
			@orev_tag_selector = @tag_selector

			track_id_query = ""

			#Need to select all tracks with those tags
			tag_ids.each do 
				|tag_id|
				track_id_query += "select track_id from track_tags where tag_id = #{tag_id[0]}"

				if not tag_id.eql? tag_ids[-1]
					track_id_query += " #{@tag_selector} "
				end
			end

			puts track_id_query			
			
			track_ids = @db.execute(track_id_query)
			

			if track_ids.empty?
				error = Hash.new
				error['message_type'] = 'error'
				error['error_message'] = "Sorry, those tags are too hip. I can't find any tracks that match them!"

				puts "Couldnt find tracks"

				send error.to_json.to_s
			else	
				@prev_tracks = track_ids
			end
		end

		return track_ids
	end

	def onclose()
		  puts "WebSocket closed" 
	end
end
