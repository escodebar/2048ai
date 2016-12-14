class Board

  def initialize
    # start the field with nil values
    @fields = [nil]*16
    # pick two random fields and set them to either 2 or 4
    Array(0..15).sample(2).each do |index|
      # assign a 2 or with a small probability a 4
      @fields[index] = rand > 0.1 and 2 or 4
    end
  end

  def rows
    _rows = []
    @fields.each_with_index do |x, i|
      _rows << [] if i % 4 == 0
      _rows.last << x
    end
    _rows
  end

  def cols
    _cols = [[], [], [], []]
    @fields.each_with_index do |x, i|
      _cols[i % 4] << x
    end
    _cols
  end

  def move_left
    _fields = []
    self.rows.each do |row|
      _fields += row.compact
    end
    @fields = _fields
  end

  def move_right
    _fields = []
    self.rows.each do |row|
      _fields += row.reverse.compact.reverse
    end
    @fields = _fields
  end

  def move_up
    _fields = []
    self.col.each do |col|
      _fields += col.compact
    end
    @fields = _fields
  end

  def move_down
    _fields = []
    self.col.each do |col|
      _fields += col.reverse.compact.reverse
    end
    @fields = _fields
  end

end
