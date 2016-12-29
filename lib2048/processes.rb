require 'ffi-rzmq'
require 'yaml'

require './lib2048'


module Lib2048 end


module Lib2048::Processes
  # Contains the logic related to communication layer and the Objects which are run
  # in the various processes.

  # Some classes

  class Client
    # Plays the game

    # the keys to validate the status
    @@keys = Lib2048::Game::Board.new.to_hash.keys


    def initialize(strategists_classes=[])
      # socket for communication
      @context = ZMQ::Context.new 1
      # initialize the player
      @strategists = if strategists_classes.empty?
                       Lib2048::AI::get_strategists_classes.sample(3).collect do |_class|
                         _class.new
                       end
                     else
                       Lib2048::AI.get_strategists_classes.collect do |_class|
                         if strategists_classes.include? String(strategist_class)
                           strategist_class.new
                         end
                       end - [nil]
                     end
      @player = Lib2048::AI::Player.new @strategists
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
        # if it can be processed
        if !!process_request(request)
          puts @status
          # let the player make a move
          socket.send_string @player.make_a_move(@status)
        else
          # else tell the server to resend the status
          socket.send_string "repeat"
        end
        # stop for a second, it's hammertime
        sleep 1
      end
      # todo: improve this (use 9, see test/?.rb)
      Process.kill(:SIGINT, pid_server) if spawn_server
      # cleanly close the socket
      socket.close
    end
  end


  class Memory
    # Learns the moves using 4 perceptrons

    @@DIRECTIONS = Lib2048::Game::DIRECTIONS

    def initialize(learning_rate)
      # zmq context for communication
      @context = ZMQ::Context.new 1
      # we need 4 perceptrons, one for each direction
      # this generates a hash of the type:
      # :direction => Perceptron instance
      @perceptrons = [@@DIRECTIONS.collect do |direction|
        # create perceptrons with 16 neurons
        # (one for each position in the board).
        [direction, Lib2048::AI::Perceptron.new(learning_rate, 16)]
      end]
    end


    def process_training_unit(unit)
      # in the case of training, the message is a yaml string
      # containing the fields and the expected result
      if (unit.is_a? Hash and
          unit.include? :input and
          unit[:input].is_a? Array and
          unit.include? :result and
          unit[:result].is_a? Fixnum)
        # let's train our 4 perceptrons
        @perceptrons.each do |direction, perceptron|
          # if perceptron is responsible for the resulting direction
          # train it with a 1, if it is not, train it with a -1
          expected_result = direction.eql?(unit[:result]) and 1 or -1
          perceptron.train unit[:input], expected_result
        end
      end
    end


    def process_computing_task(task)
      # in the case of computing, the message is a yaml string
      # containing 
      if (task.is_a? Array and
          task.length.eql? 16)
        # if the task is valid, compute the results of all perceptrons
        # and return the resulting directions with their values (yamld)
        @perceptrons.collect do |direction, perceptron|
          [perceptron.feed_forward(task), direction]
        end.sort.reverse.to_yaml
      else
        # reply with an error if the task wasn't an array of length 16
        "error processing task"
      end
    end


    def run(training_port=nil, feedforward_port=nil)
      # chose two random ports if none are given
      if training_port.nil?
        training_port = Array(9000...10000).sample
      end
      if port_feedworward.nil?
        feedforward_port = Array(10000...11000).sample
      end
      # prepare the sockets for training and feed forward
      training = @context.socket ZMQ::PULL
      training.bind "tcp://*:#{training_port}"
      feedforward = @context.socket ZMQ::REP
      feedforward.bind "tcp://*:#{feedforward_port}"
      # output some useful information
      puts "Memory bound to tcp ports:"
      puts "training: #{training_port}"
      puts "feedforward: #{feedforward_port}"
      # a poller is now prepared which is going to handle the requests
      poller = ZMQ::Poller.new
      poller.register training, ZMQ::POLLIN
      poller.register feedforward, ZMQ::POLIN
      # run forever (this can be probably done better)
      while true
        # poll the sockets to check if we have messages to receive
        poller.poll :blocking
        poller.readables.each do |socket|
          # initialize and get the message
          socket.recv_string(message = '')
          unpacked = YAML.load(message)
          # and handle it differently depending on the type the socket
          if socket === training
            # train the perceptron if the training socket got a message
            puts "training with #{unpacked}"
            process_training_unit unpacked
          elsif socket === feedforward
            # compute the direction to move for a field
            puts "feedforward with #{unpacked}"
            process_computing_task unpacked
          end
        end
      end
    end
  end


  class Server
    # Serves the game

    def initialize
      # socket for communication
      @context = ZMQ::Context.new 1
      # create the board
      @board = Lib2048::Game::Board.new
    end


    def run(port=nil)
      # todo: implement fork here?
      port = Array(6000...7000).sample if port.nil?  # select a random port if none is given
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
        @board = Lib2048::Game::Board.new if @board.game_over?
      end
    end
  end

end
