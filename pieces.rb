class Piece
  attr_reader :position, :color

  def initialize(position, color)
    @position = position
    @color = color
  end

  def move(end_position)
    @position = end_position
  end

  def possible_moves_on_board(possible_moves)
    possible_moves.select do |x,y|
      x >= 0 && x <= 7 && y >= 0 && y <= 7
    end
  end

  def dup
    position_dup = @position.dup
    object_dup = self.class.new(position_dup, self.color)
  end
end

class SlidingPiece < Piece
  attr_reader :move_vector

  def possible_moves
    possible_moves = []
    @move_vector.each do |vector|
      (1..7).each do |index|
        new_vector = [@position[0] + (vector[0] * index),
                      @position[1] + (vector[1] * index)]
        possible_moves << new_vector
      end
    end
    possible_moves = possible_moves_on_board(possible_moves)
  end
end

class Queen < SlidingPiece
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "Q"
    @move_vector = [[1, 1], [1, -1], [-1, 1], [-1, -1],
                    [1, 0], [-1, 0], [0, 1], [0, -1]]
  end
end

class Bishop < SlidingPiece
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "B"
    @move_vector = [[1, 1], [1, -1], [-1, 1], [-1, -1]]
  end
end

class Rook < SlidingPiece
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "R"
    @move_vector = [[1, 0], [-1, 0], [0, 1], [0, -1]]
  end
end

class SteppingPiece < Piece
  attr_reader :move_diff

  def possible_moves
    possible_moves = []
    @move_diff.each do |diff|
      new_move = [@position[0] + diff[0], @position[1] + diff[1]]
      possible_moves << new_move
    end
    possible_moves = possible_moves_on_board(possible_moves)
  end
end

class Knight < SteppingPiece
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "N"
    @move_diff = [[1, 2], [-1, 2], [2, 1], [2, -1],
                  [1, -2], [-1, -2], [-2, -1], [-2, 1]]
  end
end

class King < SteppingPiece
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "K"
    @move_diff = [[1, 1], [1, -1], [-1, 1], [-1, -1],
                    [1, 0], [-1, 0], [0, 1], [0, -1]]
  end
end

class Pawn < Piece
  attr_accessor :move_diff
  attr_reader :mark

  def initialize(position, color)
    super(position, color)
    @mark = "P"
    if color == :black
      @move_diff = [[1,0], [2,0]]
      @capture_diff = [[1,1], [1,-1]]
    else
      @move_diff = [[-1,0], [-2,0]]
      @capture_diff = [[-1,1], [-1,-1]]
    end
  end

  def possible_moves(capturing = false)
    possible_moves = []
    diffs = capturing ? @capture_diff : @move_diff
    diffs.each do |diff|
      new_move = [@position[0] + diff[0], @position[1] + diff[1]]
      possible_moves << new_move
    end
    possible_moves = possible_moves_on_board(possible_moves)
  end

  def move(end_position)
    @position = end_position
    if @move_diff.count == 2
      @move_diff.pop
    end
  end

  def dup
    position_dup = @position.dup
    object_dup = self.class.new(position_dup, self.color)
    object_dup.move_diff = @move_diff.dup
    object_dup
  end

end