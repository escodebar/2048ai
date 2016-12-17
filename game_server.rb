#!/usr/bin/env ruby

require 'optparse'
require 'rubygems'
require 'ffi-rzmq'
require 'yaml'

require './board'


def run(port)
  # runs the game

  # socket for communication
  puts "Starting 2048 game server..."
  context = ZMQ::Context.new(1)
  socket = context.socket(ZMQ::REP)
  socket.bind("tcp://*:#{port}")

  # create the board
  board = Board.new

  # we need a place to store the request
  request = ''

  while 0 < socket.recv_string(request)

    # get the requested move direction
    break if request.eql?('exit')

    # handle the request
    reply = if ['up', 'down', 'left', 'right'].index(request).nil?
              # Bad request, reply!
              { 'error' => "Bad request '#{request}', try up, down, left or right!" }.to_yaml
            else
              # move the fields in the requseted direction
              eval("board.#{request}!")
              board.to_yaml
            end

    # send the reply
    socket.send_string(reply)

    # check if the game is over and start a new one if needed
    board = Board.new if board.done?

  end

  # cleanly close the socket
  socket.close
end


if __FILE__ == $0

  # parse the program options
  options = { :port => 5555 }
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

  # run the game listening on the given port
  run(options[:port])
end
