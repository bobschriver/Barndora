require './api_key.rb'

require 'rubygems'
require 'bundler/setup'

require 'singleton'
require 'em-websocket'
require 'json'
require 'net/http'
require 'uri'

class BandcampAPI 
	include Singleton

	API_BASE = "http://api.bandcamp.com/api/"
	BAND_INFO_URL_BASE = API_BASE + "band/3/info?key=#{$key}&band_id="
	ALBUM_INFO_URL_BASE = API_BASE + "album/2/info?key=#{$key}&album_id="
	TRACK_INFO_URL_BASE = API_BASE + "track/1/info?key=#{$key}&track_id="
	URL_INFO_URL_BASE = API_BASE + "url/1/info?key=#{$key}&url="

	def initialize()
	end

	def band_info(band_id)
		band_info_url = BAND_INFO_URL_BASE + band_id.to_s
		return get_json(band_info_url)
	end
	
	def album_info(album_id)
		album_info_url = ALBUM_INFO_URL_BASE + album_id.to_s
		return get_json(album_info_url)
	end

	def track_info(track_id)
		track_info_url = TRACK_INFO_URL_BASE + track_id.to_s
		return get_json(track_info_url)
	end

	def url_info(url)
		url_info_url = URL_INFO_URL_BASE + url
		return get_json(url_info_url)
	end

	def get_json(url)	
		response = Net::HTTP.get_response(URI.parse(url))
   		data = response.body
		result = JSON.parse(data)   

		return result
	end
end
