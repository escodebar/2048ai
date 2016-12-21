require 'ffi-rzmq'
require 'yaml'

require './the2048game.rb'
require './the2048gameai.rb'

module The2048GameProcesses
  # Contains the logic related to communication layer and the Objects which are run
  # in the various processes.

  # Some classes

  class Server
    # Serves the game

    def initialize()
      # socket for communication
      @context = ZMQ::Context.new 1

      # create the board
      @board = The2048Game::Board.new
    end


    def run(port=nil)
      # todo: implement fork here?

      # select a random port if none is given
      port = Array(6000...7000).sample if port.nil?
      tcp = "tcp://*:#{port}"
      socket = @context.socket(ZMQ::REQ)
      socket.bind tcp
      puts "Game server running and bound to #{tcp}"
      puts "Waiting for REQ"

      # the request validation logic is separated from the rest of the script
      # and put into its own function (called validates). To simplify this task
      # we're going to use closures!
      reply = ''

      while true
        # send the current status of the board to the client and get its reply
        socket.send_string @board.to_yaml
        socket.recv_string reply

        # exit if requested
        break if reply.eql? 'exit'

        # move the fields in the requested direction
        @board.move!(reply) unless reply.eql? 'repeat'

        # check if the game is over and start a new one if needed
        @board = The2048Game::Board.new if @board.game_over?
      end

    end

  end


  class Client
    # Plays the game

    # the keys to validate the status
    @@keys = The2048Game::Board.new.to_hash.keys


    def initialize

      # socket for communication
      @context = ZMQ::Context.new 1

      # initialize the player
      @player = The2048GameAI::Player.new

      # the objects attributes
      @status = {}
    end


    def process_request(request)
      # validates the request and stores the status if valid

      # reset the present and load new one
      @status = {}
      new_status = YAML.load request

      # nested method as shortcut
      def has_keys?(hash)
        # checks if the hash has the given list of labels
        @@keys.inject(true) { |total, key| total &= hash.include? key }
      end

      # if the new status is a valid hash, set it as status
      if new_status.is_a?(Hash) and has_keys?(new_status)
        @status = new_status
      end
    end


    def run(host='localhost', port=nil, spawn_server=false)
      # plays the game

      # todo: implement fork here?

      # prepare the socket
      port = Array(6000...7000).sample if port.nil?
      tcp = "tcp://#{host}:#{port}"
      socket = @context.socket ZMQ::REP if socket.nil?
      socket.connect tcp
      puts "Game client running and connected to #{tcp}"
      puts "Ready to give REP"

      # start the game server if needed
      # todo: improve by fork instead of spawn?
      pid_server = Process.spawn "ruby game_server -p #{port} >&1 2>&1" if spawn_server
      puts "Started game server with PID #{pid_server}" if spawn_server

      while true

        # get the request
        request = ''
        socket.recv_string(request)

        puts request

        # if it can be processed
        if !!process_request(request)
          # let the player make a move
          socket.send_string @player.make_a_move(@status)
        else
          # else tell the server to resend the status
          socket.send_string "repeat"
        end

        # stop for a second, it's hammertime
        sleep 1
      end

      # todo: improve this (see tests.rb)
      Process.kill(:SIGINT, pid_server) if spawn_server

      # cleanly close the socket
      socket.close
    end

  end

end
