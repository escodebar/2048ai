require './board' # some strategist require a board to think

module The2048GameStrategy

  class Strategist

    # A strategist with no strategy

    def initialize(fields)
      @fields = fields
      @board = The2048Game::Board.new fields
    end

    def choice(samples=1)
      # he has no strategy, he has no choice
      nil
    end

    def veto(samples=1)
      # he has no strategy, he has no veto
      nil
    end
  end


  class TotallyRandomStrategist < Strategist
    # A strategist with a random strategy

    def choice(samples=1)
      # Selects a direction randomly
      @board.directions.sample samples
    end

    def veto(samples=1)
      # selects a veto randomly
      @board.directions.sample samples
    end
  end


  class RandomStrategist < Strategist
    # A smart random strategist with some sense for logics

    def initialize(fields)
      super.initialize(fields)
      @possible_vetos = []
    end

    def choice(samples=1)
      # Selects a direction randomly
      _chosen = @board.directions.sample samples

      # keep the others for the possible veto
      @possible_vetos = @board.directions - chosen

      _chosen
    end

    def veto(samples=1)
      # if a decision upon the choice was made (see def choice), the veto list
      # should be populated and a sample of it can be taken
      @possible_vetos.sample samples if @possible_vetos.length > 0
    end
  end


  class PointMaximizer < Strategist
    # This choses the move which gives the maximum score

    def choice(samples=1)
      # for each choice, compute the score of the move
      @board.directions.collect do |direction|
        [@board.dup.move!(direction), direction]
      # then sort it by the value of the move and pick the best scores
      end.sort { |a, b| a[1] <=> b[1] }.slice 0...samples
    end

    def veto(samples=1)
      # if a move gives no points it is totally vetoed!
      @board.directions.inject([]) do |vetos, direction|
        _score = @board.dup.move! direction
        vetos << direction if @board.dup.move!(direction).eql? 0
      end.sample samples
    end
  end


  class Sweeper < Strategist
    # A sweeper tries to free as many fields as possible

    def choice(samples=1)
      # which move frees the most fields?
      @board.directions.collect do |choice|
        _board = @board.dup.move! choice 
        [_board.fields.inject(0) { |empty, field| empty + 1 if field.nil? }]
      end.sort { |a, b| a[1] <=> b[i] }.slice 0..samples
    end

    def veto(samples=1)
      _empty = _boards.fields.inject(0) { |empty, field| empty + 1 if field.nil? }
      # which move 
      @board.directions.collect do |choice|
        __empty = @board.dup.move!(choice).fields.inject(0) { |empty, field| empty + 1 if field.nil? }
        choice if _empty > __empty
      end.sample(samples)
    end
  end

end
