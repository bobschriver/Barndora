require 'sqlite3'
require 'json'

require './bandcamp_api.rb'

db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		
urls = db.execute("select * from urls")

urls.each do
	|url|
	
	url_json = BandcampAPI.instance.url_info(url[1])


	if url_json.has_key? 'track_id' 
		tracks = [BandcampAPI.instance.track_info(url_json['track_id'])]
	elsif url_json.has_key? 'album_id'
		tracks = BandcampAPI.instance.album_info(url_json['album_id'])['tracks']
	else
		next
	end

	puts "URL " + url[0].to_s + " " + url[1].to_s
	puts "Tracks " + tracks.length.to_s

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
