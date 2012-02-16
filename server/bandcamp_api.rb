require './api_key.rb'

require 'rubygems'
require 'bundler/setup'

require 'singleton'
require 'json'
require 'net/http'
require 'uri'
require 'sqlite3'

class BandcampAPI 
	include Singleton

	API_BASE = "http://api.bandcamp.com/api/"
	BAND_INFO_URL_BASE = API_BASE + "band/3/info?key=#{$key}&band_id="
	ALBUM_INFO_URL_BASE = API_BASE + "album/2/info?key=#{$key}&album_id="
	TRACK_INFO_URL_BASE = API_BASE + "track/1/info?key=#{$key}&track_id="
	URL_INFO_URL_BASE = API_BASE + "url/1/info?key=#{$key}&url="

	
	def initialize()
		@db = SQLite3::Database.new( "data/bandcamp_tags.db" )
	end

	def band_info(band_id)
		band_info = @db.execute("select * from band_info where band_id = #{band_id.to_s}")

		if band_info.empty?
			band_info_url = BAND_INFO_URL_BASE + band_id.to_s
			band_info_json = get_json(band_info_url)

	
			name = (band_info_json.has_key? 'name') ? band_info_json['name'] : 'NULL'
			subdomain = (band_info_json.has_key? 'subdomain') ? band_info_json['subdomain']	: 'NULL'
			url = (band_info_json.has_key? 'url') ? band_info_json['url'] : 'NULL'
			offsite_url = (band_info_json.has_key? 'offsite_url') ? band_info_json['offsite_url'] : 'NULL'	
			
			query = "insert into band_info (band_id , name , subdomain , url , offsite_url) values(? , ? , ? , ? , ?)"

			puts query

			band_insert = @db.prepare(query)

			band_insert.execute(band_id , name , subdomain , url , offsite_url)
		else
			band_info_json = Hash.new
		
			band_info_json['band_id'] = band_info[0][0]
			band_info_json['name'] = band_info[0][1]
			band_info_json['subdomain'] = band_info[0][2]
			
			if band_info[0][3].nil?
				band_info_json['url'] = band_info[0][3]
			end

			if band_info[0][4].nil?
				band_info_json['offsite_url'] = band_info[0][4]
			end
		end

		return band_info_json
	end
	
	def album_info(album_id)
		album_info = @db.execute("select * from album_info where album_id = #{album_id.to_s}")
	


		if album_info.empty?
			album_info_url = ALBUM_INFO_URL_BASE + album_id.to_s
			album_info_json =  get_json(album_info_url)
			
			title = (album_info_json.has_key? 'title') ? album_info_json['title'] : 'NULL'
			release_date = (album_info_json.has_key? 'release_date') ? album_info_json['release_date'] : 'NULL'
			downloadable = (album_info_json.has_key? 'downloadable') ? album_info_json['downloadable'] : 'NULL'
			url = (album_info_json.has_key? 'url') ? album_info_json['url'] : 'NULL'

			tracks = (album_info_json.has_key? 'tracks') ? album_info_json['tracks'].map{|track| track['track_id']}.join(',') : 'NULL'

			small_art_url = (album_info_json.has_key? 'small_art_url') ? album_info_json['small_art_url'] : 'NULL'
			large_art_url = (album_info_json.has_key? 'large_art_url') ? album_info_json['large_art_url'] : 'NULL'
			artist = (album_info_json.has_key? 'artist') ? album_info_json['artist'] : 'NULL'
			band_id = (album_info_json.has_key? 'band_id') ? album_info_json['band_id'] : 'NULL'

			query = "insert into album_info (album_id , title , release_date , downloadable , url , tracks , small_art_url , large_art_url , artist , band_id) values(? , ? , ? , ? , ? , ? , ? , ? , ? , ?)"

			puts query

			album_insert = @db.prepare(query)
			
			album_insert.execute(album_id.to_s , title , release_date , downloadable , url , tracks , small_art_url , large_art_url , artist , band_id.to_s)
		

		else
			album_info_json = Hash.new

			album_info_json['album_id'] = album_info[0][0]
			album_info_json['release_date'] = album_info[0][1]
			album_info_json['downloadable'] = album_info[0][2]
			album_info_json['url'] = album_info[0][3]
			album_info_json['tracks'] = album_info[0][4].split(',').map{|track_id| {'track_id' => track_id}}
			album_info_json['small_art_url'] = album_info[0][5]
			album_info_json['large_art_url'] = album_info[0][6]
			album_info_json['band_id'] = album_info[0][7]
			album_info_json['title'] = album_info[0][8]

			if not album_info[9].nil?
				album_info_json['artist'] = album_info[0][9]
			end
		end

		return album_info_json
	end

	def track_info(track_id)
		
		track_info = @db.execute("select * from track_info where track_id = #{track_id.to_s}")

		if track_info.empty?
			track_info_url = TRACK_INFO_URL_BASE + track_id.to_s
			track_info_json =  get_json(track_info_url)
			
			track_id = (track_info_json.has_key? 'track_id') ? track_info_json['track_id'] : 'NULL'
			release_date = (track_info_json.has_key? 'release_date') ? track_info_json['release_date'] : 'NULL'
			downloadable = (track_info_json.has_key? 'downloadable') ? track_info_json['downloadable'] : 'NULL'
			url = (track_info_json.has_key? 'url') ? track_info_json['url'] : 'NULL'
			streaming_url = (track_info_json.has_key? 'streaming_url') ? track_info_json['streaming_url'] : 'NULL'
			lyrics = (track_info_json.has_key? 'lyrics') ? track_info_json['lyrics'] : 'NULL'
			small_art_url = (track_info_json.has_key? 'small_art_url') ? track_info_json['small_art_url'] : 'NULL'
			large_art_url = (track_info_json.has_key? 'large_art_url') ? track_info_json['large_art_url'] : 'NULL'
			band_id = (track_info_json.has_key? 'band_id') ? track_info_json['band_id'] : 'NULL'
			album_id = (track_info_json.has_key? 'album_id') ? track_info_json['album_id'] : 'NULL'
			duration = (track_info_json.has_key? 'duration') ? track_info_json['duration'] : 'NULL'
	
			
			query = "insert into track_info (track_id, release_date, downloadable, url, streaming_url, lyrics, small_art_url, large_art_url, band_id, album_id, duration) values (? , ? , ? , ? , ? , ? , ? , ? , ? , ? , ?)"
			puts query

			track_insert = @db.prepare(query)

			track_insert.execute(track_id , release_date , downloadable , url , streaming_url , lyrics , small_art_url , large_art_url , band_id , album_id , duration)
		else

			#TODO Look into a better way of doing this
			

			track_info_json =  Hash.new

			track_info_json['track_id'] = track_info[0][0]
			
			if not track_info[0][1].nil?
				track_info_json['release_date'] = track_info[0][1]
			end

			if not track_info[0][2].nil?
				track_info_json['downloadable'] = track_info[0][2]
			end

			if not track_info[0][3].nil?
				track_info_json['url'] = track_info[0][3]
			end

			if not track_info[0][4].nil?
				track_info_json['streaming_url'] = track_info[0][4]
			end

			if not track_info[0][5].nil?
				track_info_json['lyrics'] = track_info[0][5]
			end

			if not track_info[0][6].nil?
				track_info_json['small_art_url'] = track_info[0][6]
			end

			if not track_info[0][7].nil?
				track_info_json['large_art_url'] = track_info[0][7]
			end

			if not track_info[0][8].nil?
				track_info_json['band_id'] = track_info[0][8]
			end


			if not track_info[0][9].nil?
				track_info_json['album_id'] = track_info[0][9]
			end
		end

		return track_info_json
	end

	def url_info(url)
		url_info = @db.execute("select * from url_info where url= \'#{url.to_s}\'")


		if url_info.empty?
			url_info_url = URL_INFO_URL_BASE + url
			url_info_json = get_json(url_info_url)
		
			band_id = (url_info_json.has_key? 'band_id') ? url_info_json['band_id'] : 'NULL'
			album_id = (url_info_json.has_key? 'album_id') ? url_info_json['album_id'] : 'NULL'
			track_id = (url_info_json.has_key? 'track_id') ? url_info_json['track_id'] : 'NULL'
			
			query = "insert into url_info (url , band_id , album_id , track_id) values (\'#{url}\' , #{band_id} , #{album_id} , #{track_id})"

			puts query

			@db.execute(query)
		else

			url_info_json = Hash.new()

			url_info_json['band_id'] = url_info[0][1]
			if not url_info[0][2].nil?
				url_info_json['album_id'] = url_info[0][2]
			end

			if not url_info[0][3].nil?
				url_info_json['track_id'] = url_info[0][3]
			end
		end

		return url_info_json
	end

	def get_json(url)	
		response = Net::HTTP.get_response(URI.parse(url))
   		data = response.body
		result = JSON.parse(data)   

		return result
	end
end
