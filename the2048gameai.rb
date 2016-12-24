require './the2048game' # some strategist require a board to think


module The2048GameAI

  ## Some useful functions

  def self.get_strategists_classes
    # returns all the classes which inherit from strategist
    The2048GameAI.constants.collect do |c|
      _class = The2048GameAI.const_get(c)
      _class if _class < Strategist
    end - [nil]  # << see what I'm doing here? I am removing all the nils!
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

    @@DIRECTIONS = The2048Game::DIRECTIONS

    def initialize
      @board = StrategyBoard.new
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
      @@DIRECTIONS.sample samples
    end

    def veto(fields=[], samples=1)
      # selects a veto randomly
      @@DIRECTIONS.sample samples
    end
  end


  class RandomStrategist < Strategist
    # A smart random strategist with some sense for logics
    # If he choses a direction he won't veto it

    def initialize
      # todo: call the initializer of the super class in order to get the directions
      @possible_vetos = []
    end

    def choice(fields=[], samples=1)
      # Selects a direction randomly
      _chosen = @@DIRECTIONS.sample samples

      # keep the others for the possible veto
      @possible_vetos = @@DIRECTIONS - _chosen

      _chosen
    end

    def veto(fields=[], samples=1)
      # if a decision upon the choice was made (see def choice), the veto list
      # should be populated and a sample of it can be taken
      @possible_vetos.length > 0 and @possible_vetos.sample(samples) or []
      # note: the random stategist has no veto before he did not make a choice
    end
  end


  class PointMaximizer < Strategist
    # This choses the move which gives the maximum score

    def choice(fields=[], samples=1)
      # generate the board with the given set of fields
      @board = StrategyBoard.new fields

      # for each choice, compute the points of the move
      @@DIRECTIONS.collect do |direction|
        [@board.dup.move!(direction), direction]
      # then sort it by the weight and pick the best scores (and finally remove the points)
      end.sort.slice(0...samples).collect { |weight, direction | direction }
    end

    def veto(fields=[], samples=1)
      # if a move gives no points it is totally vetoed!
      @@DIRECTIONS.inject([]) do |vetos, direction|
        _score = @board.dup.move! direction
        vetos << direction if @board.dup.move!(direction).eql? 0
      end.sample samples
    end
  end


  class Sweeper < Strategist
    # A sweeper tries to free as many fields as possible

    def choice(fields=[], samples=1)
      @board = StrategyBoard.new fields
      # which move frees the most fields?
      @@DIRECTIONS.collect do |direction|

        # since move changes the board, we need to duplicate it!
        board = @board.dup
        board.move! direction

        # after moving the board, compute and return its
        # emptyness along with the direction of the move
        [board.fields.each.inject(0) do |emptyness, field|
          emptyness + 1 if field.nil?
          emptyness
        end, direction]
      # then sort it by the emptyness and pick the best scores (and finally remove the emptyness)
      end.sort.slice(0..samples).collect { |emptyness, direction| direction }
    end

    def veto(fields=[], samples=1)
      @board = StrategyBoard.new fields
      (@@DIRECTIONS.collect do |direction|

        # since move changes the board, we need to duplicate it!
        board = @board.dup

        # compute the emptyness of the board before the move
        emptyness_before = board.fields.each.inject(0) do |emptyness, field|
          emptyness + 1 if fields.nil?
          emptyness
        end

        # make a move in 'direction'
        board.move! direction

        # compute the emptyness of the board after the move
        emptyness_after = board.fields.each.inject(0) do |emptyness, field|
          emptyness + 1 if fields.nil?
          emptyness
        end

        direction if emptyness_before < emptyness_after
      end - [nil]).slice 0..samples
    end
  end

end
