require './board' # some strategist require a board to think

class Strategist
  # A strategist with no strategy

  def initialize(fields)
    @fields = fields
    @board = Board.new(fields)
    @choices = ["left", "right", "up", "down"]
  end

  def choice(nr_of_choices=1)
    # he has no strategy, he has no choice
    nil
  end

  def veto(nr_of_vetos=1)
    # he has no strategy, he has no veto
    nil
  end
end


class TotallyRandomStrategist < Strategist
  # A strategist with a random strategy

  def choice(nr_of_choices=1)
    # Selects a direction randomly
    @choices.sample(nr_of_choices)
  end

  def veto(nr_of_vetos=1)
    # selects a veto randomly
    @choices.sample(nr_of_vetos)
  end
end


class RandomStrategist < Strategist
  # A smart random strategist with some sense for logics

  def initialize(fields)
    super.initialize(fields)
    @possible_vetos = []
  end

  def choice(nr_of_choices=1)
    # Selects a direction randomly
    _chosen = @choices.sample(nr_of_choices)

    # keep the others for the possible veto
    @possible_vetos = @choices - chosen

    _chosen
  end

  def veto(nr_of_vetos=1)
    # if a decision upon the choice was made (see def choice), the veto list
    # should be populated and a sample of it can be taken
    @possible_vetos.sample(nr_of_vetos) if @possible_vetos.length > 0
  end
end


class PointMaximizer < Strategist
  # This choses the move which gives the maximum score

  def choice(nr_of_choices=1)
    # for each choice, compute the score of the move
    @choices.collect do |choice|
      [@board.dup.move!(choice), choice]
    # then sort it by the value of the move and pick the best scores
    end.sort { |a, b| a[1] <=> b[1] }.slice(0...nr_of_choices)
  end

  def veto(nr_of_vetos=1)
    # if a move gives no points it is totally vetoed!
    _vetos = @choices.collect do |choice|
      _score = @board.dup.move!(choice)
      [_score, choice] if _score.eql? 0
    end - [nil]
    _vetos.sample(nr_of_vetos)
  end
end


class Sweeper < Strategist
  # A sweeper tries to free as many fields as possible

  def choice(nr_of_choices=1)
    # which move frees the most fields?
    @choices.collect do |choice|
      _board = @board.dup.move! choice 
      [_board.fields.inject(0) { |empty, field| empty + 1 if field.nil? }]
    end.sort { |a, b| a[1] <=> b[i] }.slice 0..nr_of_choices
  end

  def veto(nr_of_vetos=1)
    _empty = _boards.fields.inject(0) { |empty, field| empty + 1 if field.nil? }
    # which move 
    @choices.collect do |choice|
      __empty = @board.dup.move!(choice).fields.inject(0) { |empty, field| empty + 1 if field.nil? }
      choice if _empty > __empty
    end.sample(nr_of_vetos)
  end
end

