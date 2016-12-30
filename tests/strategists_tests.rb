require 'test/unit'

require 'lib2048'

class StrategistsTest < Test::Unit::TestCase

  def setup
    # setup the strategists
    @strategists = Lib2048::AI::get_strategists_classes.collect do |strategist_class|
      strategist_class.new
    end

    # setup the board
    @board = Lib2048::Game::Board.new
  end


  def teardown
    # do we need to tear down something here? probably not!
  end


  def test_strategists_choices_type
    @strategists.each do |strategist|
      # give the board's status to the strategist
      choices = strategist.choice @board.fields
      assert choices.is_a?(Array), "#{strategist.class} choices is not an 'Array'"
      assert (choices.collect { |choice| choice.class } - [String]).empty?, "#{strategist.class}'s choices are not 'String's"
    end
  end


  def test_strategists_veto_type
    @strategists.each do |strategist|
      # give the board's status to the strategist
      vetos = strategist.veto @board.fields
      assert vetos.is_a?(Array), "#{strategist.class} vetos is not an 'Array'"
      assert (vetos.collect { |veto| veto.class } - [String]).empty?, "#{strategist.class}'s vetos are not 'String's"
    end
  end


  def test_random_strategist
    # create the random strategist
    strategist = Lib2048::AI::RandomStrategist.new
    # check 100 times if the random strategist vetos his own choice
    contradiction = 100.times.inject(false) do |previously_contradicted|
      previously_contradicted or strategist.choice.eql? strategist.veto
    end
    assert !contradiction, "#{strategist.class}'s vetos his own choice"
  end


  def test_point_maximizer
    # create the point maximizer
    strategist = Lib2048::AI::PointMaximizer.new

    # first, let's test the choices

    # we're testing some fields whose choice we know
    fields_set = {
      ['up', 'down'] => [
         8, 4, 4, 8,
         4, 2, 2, 4,
        32, 4, 4, 8,
        32, 2, 2, 4
      ],
      ['left', 'right'] => [
        4, 8, 32, 32,
        2, 4,  2,  4,
        2, 4,  2,  4,
        4, 8,  4,  8
      ]
    }

    # test the strategies choices
    fields_set.keys.each do |directions|
      # compute the strategists choice
      choices = strategist.choice fields_set[directions], 2
      assert directions.sort.eql?(choices.sort), "#{strategist.class} fails choosing #{directions.join(' & ')}, got #{choices}"
    end

    # now, let's test the vetos

    # let's define some boards, for which we know the resulting veto
    fields_set = {
      ['up', 'down'] => [
        16, 16, 16, 16,
         8,  8,  8,  8,
         4,  4,  4,  4,
         2,  2,  2,  2
      ],
      ['left', 'right'] => [
        2, 4, 8, 16,
        2, 4, 8, 16,
        2, 4, 8, 16,
        2, 4, 8, 16
      ]
    }

    fields_set.keys.each do |directions|
      # compute the strategists veto
      vetos = strategist.veto fields_set[directions], 2
      assert directions.sort.eql?(vetos.sort), "#{strategist.class} fails vetoing #{directions.join(' & ')}, got #{vetos}"
    end
  end


  def test_sweeper
    # create the point maximizer
    strategist = Lib2048::AI::Sweeper.new

    # we're testing some fields whose choice we know
    fields_set = {
      ['up', 'down'] => [
        4, 8, 32, 32,
        2, 4,  2,  4,
        2, 4,  2,  4,
        4, 8,  4,  8
      ],
      ['left', 'right'] => [
         8, 4, 4, 8,
         4, 2, 2, 4,
        32, 4, 4, 8,
        32, 2, 2, 4
      ]
    }

    # test the strategies choices
    fields_set.keys.each do |directions|
      # compute the strategists choice
      choices = strategist.choice fields_set[directions], 2
      assert directions.sort.eql?(choices.sort), "#{strategist.class} fails choosing #{directions.join(' & ')}, got #{choices}"
    end

    # and now the veto!
    fields_set = {
      ['up', 'down'] => [
        nil, nil, nil, nil,
          8,   8,  32,  32,
          4,   4,   2,   4,
        nil, nil, nil, nil,
      ],
      ['left', 'right'] => [
        nil, 4, 2, nil,
        nil, 2, 4, nil,
        nil, 4, 2, nil,
        nil, 2, 4, nil
      ]
    }

  end

end
