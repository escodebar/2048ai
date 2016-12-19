require 'test/unit'
require 'ffi-rzmq'

class GameTest < Test::Unit::TestCase

  def setup
    # chose two random ports
    host = 'localhost'
    ports = Array(6000...7000).sample 2

    # socket for communication
    context = ZMQ::Context.new 1

    # start the server and connect
    @pid_server = Process.spawn "ruby game_server -p #{ports.first} > /dev/null 2>&1"
    @to_game_server = context.socket ZMQ::REP
    @to_game_server.connect "tcp://#{host}:#{ports.first}"

    print "Connected to socket tcp://#{host}:#{ports.first} with PID #{@pid_server} \n"

    # start the client and connect
    @pid_client = Process.spawn "ruby game_client -p #{ports.last} > /dev/null 2>&1"
    @to_game_client = context.socket ZMQ::REQ
    @to_game_client.bind "tcp://*:#{ports.last}"

    print "Bound to socket tcp://*:#{ports.last} with PID #{@pid_server} \n"
  end

  def teardown
    # stops the server and the client

    # TODO: use the process ids to stop both processes
  end

  def test_man_in_the_middle
    # let's play man in the middle!
    print "Man in the middle"

    # deal the request
    request = ''
    @to_game_server.recv_string request
    print "Received request '#{request}' from server"
    @to_game_client.send_string request
    print "Sent request '#{request}' to client"

    # deal the reply
    reply = ''
    @to_game_client.recv_string reply
    print "Received reply '#{reply}' from client"
    @to_game_server.send_string reply
    print "Sent reply '#{reply}' to server"

    assert(true, "The asertion didn't work")
  end

end
