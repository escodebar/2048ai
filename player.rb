#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'ffi-rzmq'
require 'yaml'

require './board'

def play(host, port)
  # plays the game

  # start the game server
  pid = Process.spawn("ruby game.rb -p #{port} > /dev/null 2>&1")
  puts "Started game server subprocess with pid #{pid}"

  # socket for communication
  context = ZMQ::Context.new(1)
  socket = context.socket(ZMQ::REQ)
  socket.connect("tcp://#{host}:#{port}")

  while true do

    # send a random direction
    request = ['up','down','left','right'].sample
    socket.send_string(request)

    # get the reply
    reply = ''
    socket.recv_string(reply)

    # TODO: security issues here!
    _r = YAML.load(reply)
    print _r

    # think for a second
    sleep 1
  end

end

if __FILE__ == $0

  # parse the program options
  options = { :host => "localhost", :port => 5555 }
  OptionParser.new do |opts|
    # the program banner
    opts.banner = "Usage: player.rb [options]"

    # the program options
    opts.on('-p', '--port PORT', 'Server port') { |v| options[:port] = v}

    # the help option
    opts.on('-h', '--help', 'Print this help') do
      puts opts
      exit
    end
  end.parse!

  play(options[:host], options[:port])
end
