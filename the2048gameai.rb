require './the2048game' # some strategist require a board to think


module The2048GameAI

  ## Some useful functions

  def self.get_strategists_classes
    The2048GameAI.constants.collect do |c|
      _class = The2048GameAI.const_get(c)
      _class if _class < Strategist
    end - [nil]
  end

  ## Some classes

  # The Players

  class Player
    # Plays the game

    def initialize(strategists=[])
      @strategists = strategists
    end


    def make_a_move(status)
      # the player makes a move
      unless @strategists.empty?
        consult_strategists status
      else
        # If no stategist around, the clueless player sends a random direction
        The2048Game::DIRECTIONS.sample
      end
    end


    def consult_strategists status
      @strategists.each do |strategist|
      end
      The2048Game::DIRECTIONS.sample
    end

  end


  # The Customized Boards

  class StrategyBoard < The2048Game::Board
    # Adds some strategy features to the standard board

    def fields_with_cartesian_coordinates
      def index_to_cart_coord(index)
        # turns the index of the element into cartesian coordinates
        #   x -------------------------------->
        # y .---------------------------------.
        # | | [1, 1] [2, 1] [3, 1] ... [n, 1] |
        # | | [1, 2] [2, 2]                   |
        # | | [1, 3]
        # | | ...
        # v | [1, m]
        #
        [index % 4, index / 4]
      end

      @fields.each.with_index.inject([]) do |collection, (elem, index)|
        coordinates = index_to_cart_coord index
        collection << { x: coordinates[0], y: coordinates[1], field: elem}
      end

    end


    def fields_with_radial_coordinates
      # returns the fields with radial coordinates

      def index_to_radius(index)
        # there are 3 possible radii:
        # - innermost fields have a radius of 1
        # - border fields have a radius of 2
        # - edge fields have a radius of 3

        # let's assume for now that the field is as innermost field
        radius = 1

        # add + 1 to the radius if the field is in one of the outer columns
        # (index + 1) % 4 will be 0 or 1 for the outer columns, dividing this
        # result by 2 leads to either a 0 for outer columns or 1 for inner columns
        radius += 1 unless (((index + 1) % 4) / 2)

        # add + 1 to the radius if the field is in one of the outer rows
        # do the same as before, but with row numbers (which is the index divided by 4)
        radius += 1 unless ((((index / 4) + 1) % 4) / 2)
      end

      def index_to_radius(index)
        # turns the index into an angle
        # TODO
      end

      @fields.each.with_index.inject([]) do |collection, (elem, index)|
        radius = index_to_radius index
        angle = index_to_angle index
        collection << { r: radius, phi: angle, field: elem}
      end

    end

    def gravity
      # returns the center of gravity of the field
      # TODO
    end


    def emptyness
      # returns the number of empty fields
      @fields.inject(0) { |sum, field| sum + (elem.nil and 1 or 0) }
    end

  end


  # The Strategists

  class Strategist
    # A strategist with no strategy
    def initialize
      @directions = StrategyBoard.new.directions
    end

    def choice(fields=[], samples=1)
      raise NotImplementedError, "I just pretend to be a Strategist, ask one of my subclasses"
    end

    def veto(fields=[], samples=1)
      raise NotImplementedError, "I just pretend to be a Strategist, ask one of my subclasses"
    end
  end


  class TotallyRandomStrategist < Strategist
    # A strategist with a total random strategy

    def choice(fields=[], samples=1)
      # Selects a direction randomly
      @directions.sample samples
    end

    def veto(fields=[], samples=1)
      # selects a veto randomly
      @directions.sample samples
    end
  end


  class RandomStrategist < Strategist
    # A smart random strategist with some sense for logics
    # If he choses a direction he won't veto it

    def initialize
      # todo: call the initializer of the super class in order to get the directions
      @directions = StrategyBoard.new.directions
      @possible_vetos = []
    end

    def choice(fields=[], samples=1)
      # Selects a direction randomly
      _chosen = @directions.sample samples

      # keep the others for the possible veto
      @possible_vetos = @directions - _chosen

      _chosen
    end

    def veto(fields=[], samples=1)
      # if a decision upon the choice was made (see def choice), the veto list
      # should be populated and a sample of it can be taken
      @possible_vetos.sample samples if @possible_vetos.length > 0
      # note: the random stategist has no veto before he did not make a choice
    end
  end


  class PointMaximizer < Strategist
    # This choses the move which gives the maximum score

    def choice(fields=[], samples=1)
      # for each choice, compute the score of the move
      @board = StrategyBoard.new fields
      @directions.collect do |direction|
        [@board.dup.move!(direction), direction]
      # then sort it by the value of the move and pick the best scores
      end.sort { |a, b| a[1] <=> b[1] }.slice 0...samples
    end

    def veto(fields=[], samples=1)
      # if a move gives no points it is totally vetoed!
      @board.directions.inject([]) do |vetos, direction|
        _score = @board.dup.move! direction
        vetos << direction if @board.dup.move!(direction).eql? 0
      end.sample samples
    end
  end


  class Sweeper < Strategist
    # A sweeper tries to free as many fields as possible

    def choice(fields=[], samples=1)
      # which move frees the most fields?
      @board.directions.collect do |choice|
        _board = @board.dup.move! choice 
        [_board.fields.inject(0) { |empty, field| empty + 1 if field.nil? }]
      end.sort { |a, b| a[1] <=> b[i] }.slice 0..samples
    end

    def veto(fields=[], samples=1)
      _empty = _boards.fields.inject(0) { |empty, field| empty + 1 if field.nil? }
      # which move 
      @board.directions.collect do |choice|
        __empty = @board.dup.move!(choice).fields.inject(0) { |empty, field| empty + 1 if field.nil? }
        choice if _empty > __empty
      end.sample(samples)
    end
  end

end
