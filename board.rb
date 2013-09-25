require './pieces.rb'
require 'colorize'
require 'debugger'

class MoveError < RuntimeError
end

class Board
  attr_accessor :grid

  def initialize
    @grid = Array.new(8) { Array.new(8) }
    generate_pieces
  end

  def print_board
    puts "\#" * 16
    puts "\#    abcdefgh  \#"
    puts "\#    ________  \#"
    @grid.each_with_index do |row, index|
      print "\# #{index + 1} |"
      row.each do |piece|
        if piece
          if piece.color == :white
            print piece.mark.white.on_light_red
          else
            print piece.mark.black.on_light_red
          end
        else
          print "_"
        end
      end
      print "| \#"
      puts
    end
    puts "\#    #{[8254].pack('U*') * 8}  \#"
    puts "\#    abcdefgh  \#"
    puts "\#" * 16
  end

  def generate_pieces
    @grid[0][0] = Rook.new([0,0], :black)
    @grid[0][1] = Knight.new([0,1], :black)
    @grid[0][2] = Bishop.new([0,2], :black)
    @grid[0][3] = Queen.new([0,3], :black)
    @grid[0][4] = King.new([0,4], :black)
    @grid[0][5] = Bishop.new([0,5], :black)
    @grid[0][6] = Knight.new([0,6], :black)
    @grid[0][7] = Rook.new([0,7], :black)

    8.times do |index|
      @grid[1][index] = Pawn.new([1,index], :black)
    end

    @grid[7][0] = Rook.new([7,0], :white)
    @grid[7][1] = Knight.new([7,1], :white)
    @grid[7][2] = Bishop.new([7,2], :white)
    @grid[7][3] = Queen.new([7,3], :white)
    @grid[7][4] = King.new([7,4], :white)
    @grid[7][5] = Bishop.new([7,5], :white)
    @grid[7][6] = Knight.new([7,6], :white)
    @grid[7][7] = Rook.new([7,7], :white)

    8.times do |index|
      @grid[6][index] = Pawn.new([6,index], :white)
    end
  end

  def get_piece_at_position(position)
    @grid[position[0]][position[1]]
  end

  def position_empty?(position)
    @grid[position[0]][position[1]].nil?
  end

  def position_on_board?(position)
    x, y = position[0], position[1]
    x >= 0 && x <= 7 && y >= 0 && y <= 7
  end

  def piece_in_the_way?(from_pos, to_pos)
    vector = [to_pos[0] - from_pos[0], to_pos[1] - from_pos[1]]
    vector.map! do |element|
      return 0 if element == 0
      element / element.abs
    end
    positions_between = []
    position = from_pos
    while position != to_pos
      next_position = position.zip(vector).map { |x,y| x+y }
      break if next_position == to_pos
      break if !position_on_board?(position)
      positions_between << next_position
      position = next_position
    end
    positions_between.each do |position|
      if !position_empty?(position)
        return true
      end
    end
    return false
  end

  def move(from_pos, to_pos)
    piece = get_piece_at_position(from_pos)
    raise MoveError, "No piece at that position" if piece.nil?
    if valid_move?(from_pos, to_pos) && !check?(piece.color)
      @grid[from_pos[0]][from_pos[1]] = nil
      piece.move(to_pos)
      @grid[to_pos[0]][to_pos[1]] = piece
    elsif check?(piece.color)
      raise MoveError, "This leaves #{piece.color} in check!"
    end
    true
  end

  def valid_move?(from_pos, to_pos)
    piece = get_piece_at_position(from_pos)
    if piece.is_a?(Pawn)
      valid_pawn_move?(piece, from_pos, to_pos)
    else
      valid_nonpawn_move?(piece, from_pos, to_pos)
    end
  end

  def valid_pawn_move?(piece, from_pos, to_pos)
    if !position_empty?(to_pos) && @grid[to_pos[0]][to_pos[1]].color == piece.color
      raise MoveError, "Can't capture own piece"
      # get new move
    elsif !position_empty?(to_pos) && !piece.possible_moves(true).include?(to_pos)
      raise MoveError, "That piece cannot move there."
      #get new move
    elsif position_empty?(to_pos) && !piece.possible_moves.include?(to_pos)
      raise MoveError, "That piece cannot move there."
      # get new move
    end
    return true
  end

  def valid_nonpawn_move?(piece, from_pos, to_pos)
    if !position_empty?(to_pos) && @grid[to_pos[0]][to_pos[1]].color == piece.color
      raise MoveError, "Can't capture own piece"
      # get new move
    elsif piece.is_a?(SlidingPiece) && piece_in_the_way?(from_pos, to_pos)
      raise MoveError, "Piece in the way"
      # get new move
    elsif !piece.possible_moves.include?(to_pos)
      raise MoveError, "That piece cannot move there."
      # get new move
    end
    return true
  end

  def check?(current_color)
    opp_color = current_color == :white ? :black : :white
    opp_pieces = get_pieces(opp_color)
    my_king_position = get_king_position(current_color)
    valid_move = false
    opp_pieces.each do |opp_piece|
      begin
        return true if valid_move?(opp_piece.position, my_king_position)
      rescue MoveError
      end
    end
    return valid_move
  end

  def checkmate?(current_color)
    my_pieces = get_pieces(current_color) #get all of my pieces
    possible_moves = []
    my_pieces.each do |piece|
      piece.possible_moves.each do |possible_move|
        begin
          valid_move?(piece.position, possible_move)
        rescue MoveError
          next
        end
        possible_moves << [piece.position, possible_move]
      end
    end
    possible_moves.all? do |possible_move|
      dupped_board = dup_board
      begin
        dupped_board.move(possible_move[0], possible_move[1])
      rescue MoveError
        return true
      end
      return false
    end
  end

  def dup_board
    dupped_grid = Array.new(8) { Array.new(8) }
    iterate_board do |piece, position|
      copy_position = position.dup
      next if piece.nil?
      dupped_piece = piece.dup
      dupped_grid[copy_position[0]][copy_position[1]] = dupped_piece
    end
    dupped_board = Board.new
    dupped_board.grid = dupped_grid
    dupped_board
  end

  def iterate_board(&prc)
    8.times do |row|
      8.times do |column|
        position = [row, column]
        piece = get_piece_at_position(position)
        prc.call(piece, position)
      end
    end
  end

  def get_king_position(color)
    iterate_board do |piece, position|
      if piece.is_a?(King) && piece.color == color
        return piece.position
      end
    end
  end

  def get_pieces(opponent_color)
    opp_pieces = []
    iterate_board do |piece, position|
      if !piece.nil? && piece.color == opponent_color
          opp_pieces << piece
      end
    end
    return opp_pieces
  end

end

# b = Board.new
# b.print_board