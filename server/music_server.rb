require 'socket'
require 'rubygems'

#yeah this is a bad way of storing my api key whatevs
require './api_key.rb'

require 'bundler/setup'

require 'sqlite3'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'uri'
require 'net/http'


db = SQLite3::Database.new( "data/bandcamp_tags.db" )

EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 2015) do |ws|
	  

	  ws.onopen do
	 	puts "Socket opened" 
	  end

	  ws.onmessage do |msg|
		
		if msg.eql? "next"  
			
			
			tag_query = "select tag_id from tags"

			if not defined?(@tags).nil? and not @tags.empty?
				tag_query += " where tag in (\'#{@tags.join('\',\'')}\');"

			end

			tag_ids = db.execute(tag_query)

			url_id_query = "select url_id from url_tags where tag_id in (\'#{tag_ids.join('\',\'')}\');"
			url_ids = db.execute(url_id_query)

			puts "Found #{url_ids.length} results"


			url_id = url_ids.sample[0]

			unescaped_url = db.execute("select url from urls where url_id = #{url_id}")[0][0]
			url = URI.escape(unescaped_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
			url_api_base = "http://api.bandcamp.com/api/url/1/info?key=#{$key}&url="
			url_api_url = url_api_base + url

			resp = Net::HTTP.get_response(URI.parse(url_api_url))
   			data = resp.body
			result = JSON.parse(data)   

			if result.has_key? 'track_id'
				track_id = result['track_id']
				track_api_base = "http://api.bandcamp.com/api/track/1/info?key=#{$key}&track_id="
				track_api_url = track_api_base + track_id.to_s

				track_response = Net::HTTP.get_response(URI.parse(track_api_url))
				track_data = track_response.body
				track = JSON.parse(track_data)
			else
				album_id = result['album_id']
				album_api_base = "http://api.bandcamp.com/api/album/2/info?key=#{$key}&album_id="
				album_api_url = album_api_base + album_id.to_s

				album_response = Net::HTTP.get_response(URI.parse(album_api_url))
				album_data = album_response.body
				album = JSON.parse(album_data)

				track = album['tracks'].sample
			end

			puts track

			ws.send track['streaming_url']
	
		else
			@tags = msg.split(',')
		end
	end

	  ws.onclose do
		  puts "WebSocket closed" 
	end
end
