require './array'

class Board

  # Defines the 4x4 board of the 2048 game
  # There field is split in 4 rows and 4 columns
  # You can move up, down, right or left, combining
  # pairwise matching neighbors.
  # Display is a rudimentary function to display the field

  attr_reader :fields

  def initialize(fields=[nil]*16)
    # start the field with nil values and populate two of them
    @fields = fields
    populate_nil! 2 if (fields - [nil]).empty?
    display

    # initializes the total and the score of the last move
    @last_move = 0
    @total_score = 0
  end


  def rows
    # splits the field into rows
    _rows = []
    @fields.each_with_index do |x, i|
      _rows << [] if i % 4 == 0
      _rows.last << x
    end
    _rows
  end


  def cols
    # splits the field into columns
    _cols = [[], [], [], []]
    @fields.each_with_index do |x, i|
      _cols[i % 4] << x
    end
    _cols
  end


  def compactables(direction)
    # in order to write more compact code, let's split here the 4 different cases, which lead
    # to the same type of object (a list of integers to compact). treating these 4 cases as
    # compactables leads to simpler code
    case direction
      when 'left'
        rows
      when 'right'
        # when we compact to the right, it is like compacting to the left we just need
        # to reverse each row
        rows.collect { |row| row.reverse }
      when 'up'
        # when we compact upwards, it is like compacting rows, we just deal with the
        # columns instead
        cols
      when 'down'
        # compacting downwards is like doing it the opposite way, reversing each
        # column first
        cols.collect { |col| col.reverse }
      else
        raise ArgumentError, "Unknown direction #{direction}, chose amongst: up, down, right, left"
    end
  end


  def method_missing(m, *args, &block)
    # let's add some shortcuts like up!, down!, right! and left!
    direction = String(m).gsub('!', '')
    if ['left', 'right', 'up', 'down'].include?(direction)
      move!(direction)
      display
    else
      raise NoMethodError, "undefined method `#{m}` for #{self.inspect}"
    end
  end


  def move!(direction)
    # Tell the user he's using this method wrong if he does not chose a correct direction
    unless ['left', 'right', 'up', 'down'].include?(direction)
      raise ArgumentError, "Unknown direction #{direction}, chose amongst: up, down, right, left"
    end

    # reset some inner values and store the field
    @last_move = 0
    _fields = @fields

    # depending on the direction, the compactables  will be rows, columns, or their reverses
    # let's deal with compactables and not care about what their nature is, just compact them!
    _compacted = compactables(direction).collect do |compactable|
      # I monkey patched these methods into the array class. take a look at array.rb
      @last_move += compactable.compact_2048_points
      compactable.compact_2048
    end

    # compacting certainly gave a heap of points, let's add them to the total score to keep the
    # happy player happy and playing happyly
    @total_score += @last_move

    # now we deal again with the 4 different cases to map the compactables back to their prior form
    # as rows or columns in order to be flatteden correctly into the field
    @fields = case direction
                when 'left'
                  _compacted.flatten
                when 'right'
                  # now this is easy, reverse each compactable to get the right sequence
                  _compacted.collect { |compactable| compactable.reverse }.flatten
                when 'up'
                  # think of the compactables as a vector of lists. each list represents a column
                  # all of a sudden the columns are rows in a matrix, which can be easily transposed
                  # into its correct shape. compactables can just be transposed
                  _compacted.transpose.flatten
                when 'down'
                  # boah, 'up' was spooky, but let's use this for 'down' as well! so the only thing
                  # we need to do is reverse each compactable first before transposing the matrix
                  _compacted.collect { |compactable| compactable.reverse }.transpose.flatten
                else
                  raise ArgumentError, "Get out of here! now!! or I'll call the feds!!11one"
                end

    # don't forget to populate some random nil fields if there was a change
    populate_nil! 1 unless @fields.eql?(_fields)

    # return the value of the move
    @last_move
  end


  def populate_nil!(nr)
    # populates a number of nil fields with values
    # get the indices of the nil positions
    _indices = []
    @fields.each_with_index do |elem, index|
      _indices << index if elem.nil?
    end
    # select two nil samples and populate them
    _indices.sample(nr).each do |index|
      # assign a 2 or with a small probability a 4
      @fields[index] = 2
      @fields[index] = 4 if rand < 0.1
    end
  end


  def display
    # displays the board
    print "\n"
    rows.each do |row|
      print ' ' + row.collect { |field| field.to_s.rjust(4, " ")}.join('|')  + "\n\n"
    end
  end


  def done?
    # checks if the game is over
    _nil = []
    @fields.each_with_index do |elem, index|
      _nil << index if elem.nil?
    end
    _rows_compactable = false
    rows.each do |row|
      _rows_compactable |= row.compactable_2048?
    end
    _cols_compactable = false
    cols.each do |col|
      _cols_compactable |= col.compactable_2048?
    end
    _nil.empty? and !_rows_compactable and !_cols_compactable
  end


  def to_yaml
    # returns a yaml dict with the values of the board
    {
      'fields' => @fields,
      'last_move' => @last_move,
      'score' => @total_score
    }.to_yaml
  end

end
