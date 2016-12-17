class Array

  # ninja is going to hate me for this, but I'm Monkey-patching
  # the Array class to fit my needs. I'm adding this compacting
  # function with contains the logic of the 2048 game! Ruby does
  # not come with this method! ... And skeletons don't come...
  # with beards! [http://poignant.guide/book/chapter-7.html]

  def compact_2048
    # compacts an array of integers as given by the 2048 game logic

    # remove nil elemenst, we're adding them afterwards
    _clean = self - [nil]

    # This is so unruby!
    i = 0
    while i < _clean.length do
      # So... if the next element is equal to this element
      if _clean[i] == _clean[i+1]
        # We override this element by the double of its value
        # and set the value of the next to nil. We add them
        # together: [4, nil] <= [2, 2] (read from right to left)
        # Both 2s get added together to a 4, behind remains a
        # nil element indicating a shifted neighbor
        _clean[i..i+1] = [_clean[i]*2, nil]
        # to skip the nil neighbor, increment the index
        i += 1
      end
      i += 1
    end
    _clean -= [nil]
    _clean + [nil] * (self.length - _clean.length)
  end

  def compact_2048_points
    # computes the points by compacting the array by the 2048 game logic
    _clean = self - [nil]

    # This is so unruby!
    _points = []
    i = 0
    while i < _clean.length do
      # So... if the next element is equal to this element
      if _clean[i] == _clean[i+1]
        # the sum of both fields is counted
        _points << _clean[i]*2
        # to skip the nil neighbor, increment the index
        i += 1
      end
      i += 1
    end

    _sum = 0
    _points.each do |_p|
      _sum += _p
    end
    _sum
  end

  def compactable_2048?
    # determines if the row is compactable
    self != compact_2048
  end
end
