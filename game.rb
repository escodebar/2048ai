require './array'

class Board

  # Defines the 4x4 board of the 2048 game
  # There field is split in 4 rows and 4 columns
  # You can move up, down, right or left, combining
  # pairwise matching neighbors.
  # Display is a rudimentary function to display the field

  def initialize
    # start the field with nil values and populate two of them
    @fields = [nil]*16
    self.populate_nil! 2
    self.display
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
    self.move_vertically!('up')
    self.populate_nil! 1 if _fields != @fields
    self.display
  end

  def down!
    _fields = @fields
    self.move_vertically!('down')
    self.populate_nil! 1 if _fields != @fields
    self.display
  end

  def right!
    _fields = @fields
    self.move_horizontally!('right')
    self.populate_nil! 1 if _fields != @fields
    self.display
  end

  def left!
    _fields = @fields
    self.move_horizontally!('left')
    self.populate_nil! 1 if _fields != @fields
    self.display
  end

  def move_horizontally!(direction)
    # Tell the user he's using this method wrong if he does not chose the right direction!
    if not ['right', 'left'].index(direction)
      raise ArgumentError, "Direction is either 'left' or 'right'" if not ['right', 'left']
    end

    # performs a horizontal movement, see how the rows can simply be added to get the complete field
    _fields = []
    self.rows.each do |row|
      _fields += row.compact if direction == 'left'
      _fields += row.reverse.compact.reverse if direction == 'right'
    end

    # store the new fields
    @fields = _fields
  end

  def move_vertically!(direction)
    # Tell the user he's using this method wrong if he does not chose the right direction!
    raise ArgumentError, "Direction is either 'up' or 'down'" if not ['up', 'down'].index(direction)

    # performs a vertical movement
    # since the columns need to be mapped differently, we need to store them
    # first and map them to the field afterwards. this is subject to improvement
    _cols = []
    self.cols.each do |col|
      _cols << col.compact if direction == 'up'
      _cols << col.reverse.compact.reverse if direction == 'down'
    end

    # map the columns to the field (I do not like this part)
    _fields = []
    # proposal, after index, comes jndex. if you need more, you probably need to refactor your code
    Array(0..3).each do |index|
      # so we are adding the i-th element of each column
      # to the array of fields
      Array(0..3).each do |jndex|  # I like this jndex idea.
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
      _indices << index if nil == elem
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
    self.rows.each do |row|
      print ' ' + row.join('   ')  + "\n\n"
    end
  end
end
