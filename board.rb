require './array'

class Board

  # Defines the 4x4 board of the 2048 game
  # There field is split in 4 rows and 4 columns
  # You can move up, down, right or left, combining
  # pairwise matching neighbors.
  # Display is a rudimentary function to display the field

  def initialize
    # start the field with nil values and populate two of them
    @points = 0
    @fields = [nil]*16
    populate_nil! 2
    display
  end

  def rows
    # splits the field into its rows
    _rows = []
    @fields.each_with_index do |x, i|
      _rows << [] if i % 4 == 0
      _rows.last << x
    end
    _rows
  end

  def cols
    # splits the field into its columns
    _cols = [[], [], [], []]
    @fields.each_with_index do |x, i|
      _cols[i % 4] << x
    end
    _cols
  end

  def up!
    _fields = @fields
    move_vertically!('up')
    populate_nil! 1 if _fields != @fields
    display
  end

  def down!
    _fields = @fields
    move_vertically!('down')
    populate_nil! 1 if _fields != @fields
    display
  end

  def right!
    _fields = @fields
    move_horizontally!('right')
    populate_nil! 1 if _fields != @fields
    display
  end

  def left!
    _fields = @fields
    move_horizontally!('left')
    populate_nil! 1 if _fields != @fields
    display
  end

  def move_horizontally!(direction)
    # Tell the user he's using this method wrong if he does not chose the right direction!
    if ['right', 'left'].index(direction).nil?
      raise ArgumentError, "Direction is either 'left' or 'right', not #{direction}"
    end

    # performs a horizontal movement, see how the rows can simply be added to get the complete field
    _fields = []
    rows.each do |row|
      @points += row.compact_points if direction == 'left'
      @points += row.reverse.compact_points if direction == 'right'
      _fields += row.compact if direction == 'left'
      _fields += row.reverse.compact.reverse if direction == 'right'
    end

    # store the new fields
    @fields = _fields
  end

  def move_vertically!(direction)
    # Tell the user he's using this method wrong if he does not chose the right direction!
    if ['up', 'down'].index(direction).nil?
      raise ArgumentError, "Direction is either 'up' or 'down', not #{direction}"
    end

    # performs a vertical movement
    # since the columns need to be mapped differently, we need to store them
    # first and map them to the field afterwards. this is subject to improvement
    _cols = []
    cols.each do |col|
      @points += col.compact_points if direction == 'up'
      @points += col.reverse.compact_points if direction == 'down'
      _cols << col.compact if direction == 'up'
      _cols << col.reverse.compact.reverse if direction == 'down'
    end

    # map the columns to the field (I do not like this part)
    _fields = []
    # proposal, after index, comes jndex. if you need more, you probably need to refactor your code
    0.upto(3) do |index|
      # so we are adding the i-th element of each column
      # to the array of fields
      0.upto(3) do |jndex|  # I like this jndex idea.
        _fields << _cols[jndex][index]  # append the ith-elem of each column
      end
    end

    # store the new fields
    @fields = _fields
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
      print ' ' + row.join('   ')  + "\n\n"
    end
  end

  def string
    # generates a string out of the field
    _str = []
    cols.each do |col|
      _str << col.join(',')
    end
    _str.join(';')
  end

  def score
    @points
  end

  def done
    _nil = []
    @fields.each_with_index do |elem, index|
      _nil << index if elem.nil?
    end
    _rows_compactable = false
    rows.each do |row|
      _rows_compactable |= row.compactable?
    end
    _cols_compactable = false
    cols.each do |col|
      _cols_compactable |= col.compactable?
    end
    _nil.empty? and not _rows_compactable and not _cols_compactable
  end

end
