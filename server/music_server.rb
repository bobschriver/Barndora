require 'socket'
require 'rubygems'

require './websocket_server.rb'

require 'bundler/setup'

require 'sqlite3'
require 'eventmachine'



EM.run do
	EM.start_server('0.0.0.0' , '2015' , ::WebsocketServer)
end

