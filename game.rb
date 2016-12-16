require 'rubygems'
require 'ffi-rzmq'

require './board'


# TODO: what is the equivalent of __name__ == '__main__' in ruby?
# TODO: readout the parameters (like socket to use etc)

puts "Starting 2048 game server..."
context = ZMQ::Context.new(1)
socket = context.socket(ZMQ::REP)
socket.bind("tcp://*:5555")

b = Board.new

while true do

  b = Board.new if b.done

  # get the request
  request = ''
  rc = socket.recv_string(request)

  # handle the request
  reply = if ['up', 'down', 'left', 'right'].index(request).nil?
            # Bad request, reply!
            "Bad request, try up, down, left or right!"
          else
            # move the fields in the requseted direction
            eval("b.#{request}!")
            "#{b.string}::#{b.score}"
          end

  # answer with the field
  socket.send_string(reply)

end
