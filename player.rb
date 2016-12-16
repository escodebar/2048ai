require 'rubygems'
require 'ffi-rzmq'

context = ZMQ::Context.new(1)

pid = Process.spawn("ruby game.rb")
puts "Starting game server subprocess with pid #{pid}"

socket = context.socket(ZMQ::REQ)
socket.connect("tcp://localhost:5555")

while true do

  # send a random direction
  request = ['up','down','left','right'].sample
  socket.send_string(request)

  # get the reply
  reply = ''
  socket.recv_string(reply)

  print reply.split('::').last

  sleep 1

end
