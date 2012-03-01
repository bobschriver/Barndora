require 'open-uri'

require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'sqlite3'
require 'singleton'

require './bandcamp_api.rb'

#Various utilities for dealing with the bandcamp site
class BandcampSiteAPI
	include Singleton

	MAX_PAGE = 2

	URL_BASE = "http://bandcamp.com/"
	TAG_URL_BASE = URL_BASE + "tag/"


	def initialize()
		@db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		return self
	end

	def is_tag(tag_name)
		
		tag_url = TAG_URL_BASE + tag_name

		tag_page = Nokogiri::HTML(open(tag_url))
	
		max_page_ast = tag_page.css('span.pagenum')

		return (not max_page_ast.empty?)
	end

	def get_tracks_for_tag(tag_name)
	
		tag_url = TAG_URL_BASE + tag_name
	
		tag_page = Nokogiri::HTML(open(tag_url))
	
		max_page_ast = tag_page.css('span.pagenum')

		max_page = max_page_ast.map{|span| span.text}[-1].to_i
	
		current_count = 0 
		
		begin
			@db.execute("insert into tags (tag) values (\"" + tag_name + "\");")
			tag_id = @db.last_insert_row_id()
		rescue SQLite3::ConstraintException
			tag_id = @db.execute("select tag_id from tags where tag=\"" + tag_name + "\"")[0][0]
			current_count = @db.execute("select count(*) from url_tags where tag_id = #{tag_id}")[0][0] / 40
		end
	
		if max_page > MAX_PAGE
			max_page = MAX_PAGE
		end

		return_urls = Array.new()

		for i in (current_count..max_page)


			curr_url = tag_url + "?page=#{i}&sort_asc=0&sort_field=pop"

			curr_page = Nokogiri::HTML(open(curr_url))

			album_urls = curr_page.css('li.item a').map{|link| link['href']}
			return_urls += album_urls


			@db.transaction do

				album_urls.each do
					|album_url|

			
					begin
						@db.execute("insert into urls (url) values (\"" + album_url + "\");")
					rescue SQLite3::ConstraintException
					end
					
					url_id = @db.execute("select url_id from urls where url=\"" + album_url + "\"")[0][0]
					@db.execute("insert into url_tags (url_id , tag_id) values(#{url_id} , #{tag_id})")

				end
			end
		end

		return return_urls
	end

	def update_track_tags(urls)

		urls.each do
			|url|
			
			puts url

			url_json = BandcampAPI.instance.url_info(url)

	
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


			if tracks.nil?
				puts "Tracks is nil, some sort of problem?"
				next
			end


			@db.transaction do

				url_id = @db.execute("select url_id from urls where url = \'#{url}\'")[0][0]

				tags = @db.execute("select tag_id from url_tags where url_id = #{url_id}").flatten.uniq
				
				

				tracks.each do
					|track|
					track_id = track['track_id']
					


					#curr_tags = @db.execute("select tag_id from track_tags where track_id = #{track_id}").flatten


					#missing_tags = tags - curr_tags
					
					tags.each do
						|tag_id|
						@db.execute("insert into track_tags (track_id , tag_id) values(#{track_id} , #{tag_id})")
					end
				end
			end
		end
	end
end
