require 'sqlite3'
require 'json'

require './bandcamp_api.rb'

db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		
urls = db.execute("select * from urls")

urls.each do
	|url|
	
	if url[0] > 50000
		exit
	end

	if url[0] < 48920
		next
	end

	url_json = BandcampAPI.instance.url_info(url[1])

	


	if url_json.has_key? 'track_id' 
		tracks_info = BandcampAPI.instance.track_info(url_json['track_id'])
		if tracks_info.has_key? 'error'
			puts "Some sort of error!"
			next
		end

		tracks = [tracks_info]

	elsif url_json.has_key? 'album_id'
		album_info = BandcampAPI.instance.album_info(url_json['album_id'])

		if album_info.has_key? 'error'
			puts "Some sort of error!"
			next
		end

		tracks = album_info['tracks']
	else
		next
	end

	puts tracks

	if tracks.nil?
		puts "Tracks is nil, some sort of problem?"
		next
	end

	puts "URL " + url[0].to_s + " " + url[1].to_s	
	puts "Number of tracks" + tracks.length.to_s
	tracks.map{|track| puts track['track_id']}

	db.transaction do

		tags = db.execute("select tag_id from url_tags where url_id = #{url[0]}").uniq
		

		tracks.each do
			|track|
			track_id = track['track_id']
		
			#Need to insert all these tags into a new track_tags table
			tags.each do
				|tag_id|
				db.execute("insert into track_tags (track_id , tag_id) values(#{track_id} , #{tag_id})")
			end
		end
	end
	sleep(1)
end
