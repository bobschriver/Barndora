require 'rubygems'
require 'bundler/setup'

require 'sqlite3'

require './bandcamp_site_api.rb'

db = SQLite3::Database.new( "data/bandcamp_tags.db" )
		
urls = db.execute("select * from urls").select{|url_info| url_info[0] > 75348 and url_info[0] < 80000}.map{|url_info| url_info[1]}


BandcampSiteAPI.instance.update_track_tags(urls)


