module Lib2048::Strategies

  ## Some useful functions

  def self.get_strategists_classes
    # returns all the classes which inherit from strategist
    Lib2048::Strategies.constants.collect do |c|
      _class = Lib2048::Strategies.const_get(c)
      _class if _class < Strategist
    end - [nil]  # << see what I'm doing here? I am removing all the nils!
  end

  ## Some classes

  # The Customized Boards

  class StrategyBoard < Lib2048::Game::Board
    # Adds some strategy features to the standard board

    def fields_with_cartesian_coordinates
      # returns the fields with cartesian coordinates

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

      @fields.each.with_index.inject([]) do |collection, (elem, index)|
        radius = index_to_radius index
        angle = index_to_angle index
        collection << { r: radius, phi: angle, field: elem}
      end
    end


    def non_nil_fields
      # returns all fields which are non nil
      @fields - [nil]
    end


    def gravity
      # returns the center of gravity of the field
      # todo
    end


    def emptyness
      # returns the number of empty fields
      @fields.count nil
    end


    def max
      # returns the value of the biggest field
      @fields.max
    end


    def fields_with_pairs
      # returns the values of the fields with a valid pair
      unless non_nil_fields.length == non_nil_fields.uniq.length
        non_nil_fields.uniq.collect do |field|
          field if @fields.count(field) > 1
        end - [nil]
      end
    end


    def paired_fields_in_cols
      # returns the fields with neighboring equivalent fields in columns
      unless non_nil_fields.length == non_nil_fields.uniq.length

        # let's see how many fields of the same value are neighboring
        # but let's check only for the ones we know have pairs
        fields_with_pairs.collect do |value|

          # first let's check the columns of the board for vertically neighboring
          # pairs of fields. the column and rows of the pairs are stored in an array
          # example field for pairs of value 2
          #     nil   nil   nil     2
          #       8     2   nil     2
          #       8     2   nil   nil
          #     nil   nil     4     4
          # pairs => [[[1, 1], [2, 1]], [[0, 3], [1, 3]]]

          # collect all the coordinates of the neighboring fields
          pairs = cols.each_with_index.inject([]) do |coordinates, (col, col_nr)|
            # compare every pair of fields to the seaken value and add the coordinates of both
            # fields of the pair if they match (and match the value)
            coordinates + col.each_cons(2).with_index.collect do |pair, row_nr|
              [[row_nr, col_nr], [row_nr + 1, col_nr]] if pair == [value]*2
            end - [nil]
          end

          # finally return the pairs found for the value
          [value, pairs]
        end.to_h
      end
    end


    def paired_fields_in_rows
      # returns the fields with neighboring equivalent fields in rows
      unless non_nil_fields.length == non_nil_fields.uniq.length
        # et pour les rowmands, c'est la même chose
        fields_with_pairs.collect do |value|
          pairs = rows.each_with_index.inject([]) do |coordinates, (row, row_nr)|
            coordinates + row.each_cons(2).with_index.collect do |pair, col_nr|
              [[row_nr, col_nr], [row_nr, col_nr + 1]] if pair == [value]*2
            end - [nil]
          end
          [value, pairs]
        end.to_h
      end
    end


    def greatest_pair_distance
      # returns the distance between the fields with the same value
      # todo
    end

  end


  # The Strategists

  class Strategist

    @@DIRECTIONS = Lib2048::Game::DIRECTIONS

    def choice(fields=[], samples=1)
      raise NotImplementedError, "I just pretend to be a Strategist, ask one of my subclasses"
    end

    def veto(fields=[], samples=1)
      raise NotImplementedError, "I just pretend to be a Strategist, ask one of my subclasses"
    end
  end


  class CompletelyRandom < Strategist
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
      board = StrategyBoard.new fields

      # for each choice, compute the points of the move
      @@DIRECTIONS.collect do |direction|
        [board.dup.move!(direction), direction]
      # then sort it by the weight and pick the best scores (and finally remove the points)
      end.sort.reverse.slice(0...samples).collect { |weight, direction | direction }
    end

    def veto(fields=[], samples=1)
      # generate the board with the given set of fields
      board = StrategyBoard.new fields

      # if a move gives no points it is totally vetoed!
      @@DIRECTIONS.collect.inject([]) do |vetos, direction|
        _score = board.dup.move! direction
        vetos << direction if _score.eql? 0
        vetos
      end.sample samples
    end
  end


  class Sweeper < Strategist
    # A sweeper tries to free as many fields as possible

    def choice(fields=[], samples=1)
      board = StrategyBoard.new fields
      # which move frees the most fields?
      @@DIRECTIONS.collect do |direction|

        # since move changes the board, we need to duplicate it!
        board = board.dup
        board.move! direction

        # after moving the board, compute and return its
        # emptyness along with the direction of the move
        [board.emptyness, direction]
      # then sort it by the emptyness and pick the best scores (and finally remove the emptyness)
      end.sort.reverse.slice(0...samples).collect { |emptyness, direction| direction }
    end

    def veto(fields=[], samples=1)
      board = StrategyBoard.new fields
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


  class Perceptrons < Strategist
    # Uses TrainedPerceptrons as strategy

    def initialize
      # create a perceptron for each direction
      @perceptrons = @@DIRECTIONS.collect { |direction| [direction, Lib2048::AI::Perceptron.new] }
    end

    def load!(weights={})
      # todo: raise exception if weights doesn't include all directions
      @perceptrons.each do |direction, perceptron|
        perceptron.weights = weights[direction]
      end
    end

    def choice(fields=[], samples=1)
      # compute the values for every perceptron (i.e. for each direction)
      @perceptrons.collect do |direction, perceptron|
        [perceptron.feed_forward(fields), direction]
      # then sort them by highest value
      end.sort.reverse.slice(0..samples).collect { |value, direction| direction }
    end

    def veto(fields=[], samples=1)
      # compute the values for every perceptron (i.e. for each direction)
      @perceptrons.collect do |direction, perceptron|
        [perceptron.feed_forward(fields), direction]
      # then sort them by lowest value
      end.sort.slice(0..samples).collect { |value, direction| direction }
    end

  end

end
