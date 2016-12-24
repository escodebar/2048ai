require 'test/unit'

require './the2048game'
require './the2048gameai'

class StrategistsTest < Test::Unit::TestCase

  def setup
    # setup the strategists
    @strategists = The2048GameAI::get_strategists_classes.collect do |strategist_class|
      strategist_class.new
    end

    # setup the board
    @board = The2048Game::Board.new
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

end
