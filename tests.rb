require 'test/unit'
require 'ffi-rzmq'

class GameTest < Test::Unit::TestCase

  def setup
    # chose two random ports
    @host = 'localhost'
    @ports = Array(6000...7000).sample 2

    # socket for communication
    @context = ZMQ::Context.new 1
  end

  def teardown
    # teardown something?
  end

  def test_man_in_the_middle

    # start the server and connect
    pid_server = Process.spawn "ruby game_server -p #{@ports.first} >/dev/null 2>&1"
    # do asertion here

    to_game_server = @context.socket ZMQ::REP
    to_game_server.connect "tcp://#{@host}:#{@ports.first}" # do asertion here

    print "Connected to socket tcp://#{@host}:#{@ports.first} with PID #{pid_server} \n"

    # start the client and connect
    pid_client = Process.spawn "ruby game_client -p #{@ports.last} >/dev/null 2>&1"
    # do asertion here

    to_game_client = @context.socket ZMQ::REQ
    to_game_client.bind "tcp://*:#{@ports.last}" # do asertion here

    print "Bound to socket tcp://*:#{@ports.last} with PID #{pid_server} \n"

    # deal the request
    request = ''
    to_game_server.recv_string request # do asertion here
    to_game_client.send_string request # do asertion here

    print "Man in the middle!"

    # deal the reply
    reply = ''
    to_game_client.recv_string reply # do asertion here
    to_game_server.send_string reply # do asertion here

    # cleanly close the sockets
    to_game_client.close
    to_game_server.close

    # stops the server and the client
    Process.kill(:SIGINT, pid_server) # do asertion here
    Process.kill(:SIGINT, pid_client) # do asertion here
  end

end
