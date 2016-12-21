require 'ffi-rzmq'
require 'test/unit'
require 'yaml'

require './the2048gameprocesses'
require './the2048game'

class GameTest < Test::Unit::TestCase

  def setup
    # chose two random ports
    @host = 'localhost'
    @ports = Array(6000...7000).sample 2

    # socket for communication
    @context = ZMQ::Context.new 1

    # start the server and the client
    @server = fork { The2048GameProcesses::Server.new.run @ports.first }
    @client = fork { The2048GameProcesses::Client.new.run @host, @ports.last, false }
  end


  def teardown

    # todo: send exit message to processes and timeout

    # the server and the client, dash-nine-em'!
    Process.kill 9, @server
    Process.kill 9, @client
  end


  def server_socket
    "tcp://#{@host}:#{@ports.first}"
  end

  def client_socket
    "tcp://*:#{@ports.last}"
  end


  def test_server_connection
    socket = @context.socket ZMQ::REP
    rc = socket.connect server_socket
    assert_equal 0, rc, "Server socket connection assertion"
    puts "Successfully connected to server on socket #{server_socket}"

    rc = socket.close
    assert_equal 0, rc, "Server socket closing assertion"
    puts "Successfully closed socket to server"
  end


  def test_client_connection
    socket = @context.socket ZMQ::REQ
    rc = socket.bind client_socket
    assert_equal 0, rc, "Client connection assertion"
    puts "Successfully bound socket for client on #{client_socket}"

    rc = socket.close
    assert_equal 0, rc, "Client socket closing assertion"
    puts "Closed socket for client cleanly"
  end


  def test_communication
    # generate and connect / bind the sockets
    to_game_server = @context.socket ZMQ::REP
    to_game_client = @context.socket ZMQ::REQ
    to_game_server.connect server_socket
    to_game_client.bind client_socket

    puts "MiM connected to server on socket #{server_socket}"
    puts "MiM bound for client to socket #{client_socket}"

    # handle the request
    puts "Handling the request"
    request = ""
    assert_not_equal 0, to_game_server.recv_string(request), "Request (board status) size assertion"
    assert YAML.load(request).is_a?(Hash), "Request (board status) type assertion"
    puts "Received a valid request from the server"

    assert_not_equal 0, to_game_client.send_string(request), "Request (board status) size assertion"
    puts "Forwarded request to client"

    # handle the reply
    puts "Handling the reply"
    reply = ""
    assert_not_equal 0, to_game_client.recv_string(reply), "Reply (move direction) size assertion"
    assert ['left', 'right', 'up', 'down'].include?(reply), "Reply (move direction) invalid assertion"
    puts "Received a valid reply from the client"
    assert_not_equal 0, to_game_server.send_string(reply), "Reply (move direction) size assertion"
    puts "Forwarded reply to server"

    # cleanly close the sockets
    to_game_server.close
    to_game_client.close
  end

end
