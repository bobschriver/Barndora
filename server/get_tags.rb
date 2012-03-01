require 'open-uri'

require 'rubygems'
require 'bundler/setup'

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

genre_tags.each do
	|tag_name_url|

	tag_url = tag_name_url[0]
	tag_name = tag_name_url[1]

	get_tracks_for_tag(tag_name)
end


