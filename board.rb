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
    populate_nil! 2
    display

    # initializes the total and the score of the last move
    @last_move = 0
    @total_score = 0
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


  def method_missing(m, *args, &block)
    # let us add some shortcuts like up!, down!, right! and left!
    direction = String(m).gsub('!', '')
    if !['up', 'down', 'left', 'right'].index(direction).nil?
      # store the state of the fields
      _fields = @fields
      move_vertically!(direction) if !['up', 'down'].index(direction).nil?
      move_horizontally!(direction) if !['left', 'right'].index(direction).nil?
      # increment the score, populate some empty fields randomly and display the board
      @total_score += @last_move
      populate_nil! 1 if _fields != @fields
      display
    else
      raise NoMethodError, "undefined method `#{m}` for #{self.inspect}"
    end
  end


  def move_horizontally!(direction)
    # Tell the user he's using this method wrong if he does not chose the right direction!
    if ['right', 'left'].index(direction).nil?
      raise ArgumentError, "Direction is either 'left' or 'right', not #{direction}"
    end
    # performs a horizontal movement, see how the rows can simply be added to get the complete field
    _fields = []
    rows.each do |row|
      @last_move = row.compact_points if direction == 'left'
      @last_move = row.reverse.compact_points if direction == 'right'
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
      @last_move = col.compact_points if direction == 'up'
      @last_move = col.reverse.compact_points if direction == 'down'
      _cols << col.compact if direction == 'up'
      _cols << col.reverse.compact.reverse if direction == 'down'
    end
    # map the columns to the field (I do not like this part)
    _fields = []
    _cols.transpose.each do |col|
      _fields += col
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


  def done?
    # checks if the game is over
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
