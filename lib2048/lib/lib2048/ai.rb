module Lib2048::AI

  # Helpful mathematical methods

  def self.sigmoid(z=[])
    # returns the sigmoid for each element of the vector z
    z.collect { |z_i| 1 / Math.exp(-z_i) }
  end

  def self.scalar_product(x=[], y=[])
    # todo: raisen an exception if the vectors aren't the same size
    x.zip(y).inject(0) do |sum, (x_i, y_i)|
      sum + x_i * y_i
    end
  end

  ## Some classes

  # The Players

  class Player
    # Plays the game

    @@DIRECTIONS = Lib2048::Game::DIRECTIONS

    def initialize(strategists=[])
      @strategists = strategists
    end


    def make_a_move(status)
      # the player makes a move
      unless @strategists.empty?
        consult_strategists status
      else
        # If no stategist around, the clueless player sends a random direction
        @@DIRECTIONS.sample
      end
    end


    def consult_strategists(status)
      # store the directions in a hash to make the voting a simple task
      directions = @@DIRECTIONS.each.inject({}) do |_directions, direction|
        _directions[direction] = 0
        _directions
      end

      # what directions chose our strategists? let them vote!
      @strategists.each do |strategist|
        # sum 1 to every direction chosen our strategists
        strategist.choice(status[:fields]).each do |direction|
          directions[direction] += 1
        end

        # subtract 1 to every direction vetoed by our strategists
        strategist.veto(status[:fields]).each do |direction|
          directions[direction] -= 1
        end
      end

      # you see how 'a' and 'b' are changed in to puth the directions with
      # the greatest number of votes in first position?
      directions.sort { |a, b| b[1] <=> a[1] }.collect { |direction, votes| direction }.first
    end

  end


  # Neural Network components

  class Network

    def initialize(opts={})

      # stores the propagated activations
      @front_propagation = []
      @back_propagation = []

      # starts the layers of the neural network
      @layers = 1.upto(opts.fetch(:nr_layers, 8)).collect do |index|
        # every layer of the neural network has one more neuron than
        # activation signals to process the activation bias of each
        # layer of the neural network
        Layer.new(
          opts.fetch(:learn_speed, 0.01),
          opts.fetch(:nr_activations, 16) + 1
        )
      end

      # once processed by the neurons in the layers, the activation
      # signal is weighted into several output signals. this sets
      # random initial weights
      @weights = 1.upto(opts.fetch(:nr_outputs, 6)).collect do |index|
        (0...opts.fetch(:nr_activations)).collect { rand * 2 - 1 }
      end
    end

    def propagate!(activation)
      # propagates the activation signal through the layers
      @front_propagation = @layers.collect.inject(activation) do |_act, layer|
        layer.propagate _act
      end
    end

    def propagated
      # returns nil if empty
      @front_propagation.last
    end

    def hypothesis!(activation)
      # returns the hypothesis of neuronal network for a given activation signal

      # propagate the activation before concluding to a hypothesis
      propagate! activation

      # compute the hypothesis using the processed activation signal
      # notice that the propagated signal is stored in @activations
      @weights.collect do |weights|
        # @weights is an Array of weights, i.e.: [weights, weights, ...]
        AI.sigmoid(AI.scalar_product(weights, propagated))
      end
    end

    def back_propagate!(activation, expected_outcome)
      # trains the neural network, the exclamation mark comes from hypothesis!

      # compute the uncertainty in respect to the expected outcome
      delta = expected_outcome.zip(hypothesis!(activation)) do |y_i, h_i|
        y_i - h_i
      end

      # now propagate it through all the layers (beginning at the end) and reversing the result
      @back_propagation = @layers.reverse.each.inject(delta) do |_delta, layer|
        # train the layer with the _delta
        layer.back_propagate _delta
      end.reverse

    end

    def partials
      # returns the partial derivatives
      @front_propagation.zip(@back_propagation).collect do |(a_j, delta_i)|
        AI.scalar_product(a_j, delta_i) / m
      end
    end



    #def cost(activation, expected_signal)
    #  # computes the cost function of the network
    #  #expected_signal.zip(hypothesis(activation)).collect { |y_i, h_i| y_i - h_i }
    #end

  end

  class Layer

    def initialize(learn_speed=0.01, number_weights=16)
      # we need 'number_weights' neurons in each layer.
      # we're adding one more weight to the neurons
      # since we're going to add a bias unit x_0 = 1 to
      # the standard input
      @neurons = 1.upto(number_weights).collect do |index|
        Neuron.new learn_speed, number_weights + 1
      end
    end

    def propagate(activation)
      # computes the output of a layer of neurons
      @neurons.collect do |neuron|
        # let's add the bias unit to the activation
        neuron.activate([1] + activation)
      end
    end

    def back_propagate(activation, delta)
      # trains the layer of neurons
      @neurons.zip(activation).collect do |neuron_i, activation_i|
        neuron_i.back_propagate activation_i, delta
      end
    end

    def cost(activation, expected)
      # iterate through all the neurons in the layer collecting
      # their cost function for the given activation and add the
      # rest
    end

    def delta(activation, expected, last=False)
      # unless it's the last one compute
      # scalar product (weights, usual delta) .* activation .* (1 - activation)
    end

  end


  class Neuron

    attr_writer :weights

    def initialize(learn_speed=0.01, number_weights=16)
      @speed = learn_speed
      @weights = (0...number_weights).collect { rand * 2 - 1 }
    end


    def activate(activation)
      # activates the neuron with the activation signal
      AI.sigmoid(AI.scalar_product(@weights, activation))
    end


    def back_propagate(activation, delta)
      # trains the neuron with the given activation and uncertainty
      theta_delta = AI.scalar_product(@weights, delta)

      # compute the next delta
      activation.collect do |a_i|
        theta_delta * a_i * (1 - a_i)
      end
    end

    def cost(activation, expected)
      activation.zip(expected).inject(0) do |sum, (a, y)|
        # this is equivalent to to
        # cost(t) = y_t * log(h(x_t)) + (1 - y_t) * log(1 - h(x_t))
        sum +
        (y * Math.log10(activate a) +
        (1 - y) * Math.Log10(1 - activate(a))) / activation.length
      end
    end

    def delta(activation, expected)
      # todo: compute the deltas
      activation.zip(expected).collect do |a_i, y_i|
        a_i - y_i
      end
    end

  end

end
