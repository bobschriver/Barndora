require 'open-uri'
require 'rubygems'
require 'nokogiri'
require 'sqlite3'


tags_page = Nokogiri::HTML(open("http://bandcamp.com/tags"))

genre_tags = tags_page.css('div#tags_cloud a.tag').map{|link| [link['href'] , link.text]}

location_tags = tags_page.css('div#locations_cloud a.tag').map{|link| [link['href'] , link.text]}

puts("Genre Tags")
puts(genre_tags)

puts("Location Tags")
puts(location_tags)

db = SQLite3::Database.new( "data/bandcamp_tags.db" )
puts(db)


location_tags.each do
	|tag_name_url|

	tag_url = tag_name_url[0]
	tag_name = tag_name_url[1]

	current_count = 0 

	begin
	db.execute("insert into tags (tag) values (\"" + tag_name + "\");")
	tag_id = db.last_insert_row_id()
	rescue SQLite3::ConstraintException
	tag_id = db.execute("select tag_id from tags where tag=\"" + tag_name + "\"")[0][0]
	current_count = db.execute("select count(*) from url_tags where tag_id = #{tag_id}")[0][0] / 40
	end
	
	puts current_count

	puts(tag_id)
	tag_page = Nokogiri::HTML(open(tag_url))

	max_page = tag_page.css('span.pagenum').map{|span| span.text}[-1].to_i

	if max_page > 10
		max_page = 10
	end

	puts("Genre " + tag_name)

	for i in (current_count..max_page)

		puts("Tag #{i} of #{max_page}")
		puts(Time.now)

		curr_url = tag_url + "?page=#{i}&sort_asc=0&sort_field=pop"

		curr_page = Nokogiri::HTML(open(curr_url))

		album_urls = curr_page.css('li.item a').map{|link| link['href']}
		
		puts(Time.now)

		#puts(album_urls)

		insert_tags = db.prepare("insert into url_tags (url_id , tag_id) values (? , ?)")
		insert_url = db.prepare("insert into urls (url) values (?)")
		select_url_id = db.prepare("select url_id from urls where url = ?")


			album_urls.each do
				|album_url|

			
				begin
					db.execute("insert into urls (url) values (\"" + album_url + "\");")
				#insert_url.execute("\"" + album_url + "\"")
				#url_id = db.last_insert_row_id()

				sleep(rand(3) + 1)
				rescue SQLite3::ConstraintException
				#select_url_id.execute("\"" + album_url + "\"")
				end

				url_id = db.execute("select url_id from urls where url=\"" + album_url + "\";")[0][0]
			
				#insert_tags.execute(url_id , tag_id)
				db.execute("insert into url_tags (url_id , tag_id) values(#{url_id} , #{tag_id});")

		end

	end

end
