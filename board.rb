require './pieces.rb'
require 'colorize'
require 'debugger'

class MoveError < RuntimeError
end

class Board
  attr_accessor :grid, :stalemate

  def initialize
    @grid = Array.new(8) { Array.new(8) }
    generate_pieces
  end

  def print_board
    puts "\#" * 16
    puts "\#    abcdefgh  \#"
    puts "\#    ________  \#"
    @grid.each_with_index do |row, index|
      print "\# #{8 - index} |"
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
    generate_base_row(:black)
    generate_pawns(:black)
    generate_base_row(:white)
    generate_pawns(:white)
  end

  def generate_pawns(color)
    row = color == :black ? 1 : 6
    8.times do |index|
      @grid[row][index] = Pawn.new([row,index], color)
    end
  end

  def generate_base_row(color)
    row = color == :black ? 0 : 7
    @grid[row][0] = Rook.new([row,0], color)
    @grid[row][1] = Knight.new([row,1], color)
    @grid[row][2] = Bishop.new([row,2], color)
    @grid[row][3] = Queen.new([row,3], color)
    @grid[row][4] = King.new([row,4], color)
    @grid[row][5] = Bishop.new([row,5], color)
    @grid[row][6] = Knight.new([row,6], color)
    @grid[row][7] = Rook.new([row,7], color)
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
      if element == 0
        0
      else
        element / element.abs
      end
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
    if valid_move?(from_pos, to_pos) && try_move(from_pos, to_pos)
      @grid[from_pos[0]][from_pos[1]] = nil
      piece.move(to_pos)
      @grid[to_pos[0]][to_pos[1]] = piece
      if piece.is_a?(Pawn)
        pawn_promotion(piece)
      end
    else
      raise MoveError, "This leaves #{piece.color} in check!"
    end
    true
  end

  def pawn_promotion(piece)
    if  (piece.color == :white && piece.position[0] == 0) ||
        (piece.color == :black && piece.position[0] == 7)
      begin
        puts "What kind of piece would you like? (R, N, B, Q)"
        input = gets.chomp.upcase
        case input
        when "R"
          new_piece = Rook.new(piece.position, piece.color)
        when "N"
          new_piece = Knight.new(piece.position, piece.color)
        when "B"
          new_piece = Bishop.new(piece.position, piece.color)
        when "Q"
          new_piece = Queen.new(piece.position, piece.color)
        else
          raise Exception
        end
      rescue
        retry
      end
      @grid[piece.position[0]][piece.position[1]] = new_piece
    end
  end


  def try_move(from_pos, to_pos)
    dupped_board = dup_board
    dupped_piece = dup_board.grid[from_pos[0]][from_pos[1]]

    dupped_board.grid[from_pos[0]][from_pos[1]] = nil
    dupped_piece.move(to_pos)
    dupped_board.grid[to_pos[0]][to_pos[1]] = dupped_piece

    return false if dupped_board.check?(dupped_piece.color)
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
    elsif !position_empty?(to_pos) && !piece.possible_moves(true).include?(to_pos)
      raise MoveError, "That piece cannot move there."
    elsif position_empty?(to_pos) && !piece.possible_moves.include?(to_pos)
      raise MoveError, "That piece cannot move there."
    elsif piece_in_the_way?(from_pos, to_pos)
      raise MoveError, "Piece in the way"
    end
    return true
  end

  def valid_nonpawn_move?(piece, from_pos, to_pos)
    if !position_empty?(to_pos) && @grid[to_pos[0]][to_pos[1]].color == piece.color
      raise MoveError, "Can't capture own piece"
    elsif piece.is_a?(SlidingPiece) && piece_in_the_way?(from_pos, to_pos)
      raise MoveError, "Piece in the way"
    elsif !piece.possible_moves.include?(to_pos)
      raise MoveError, "That piece cannot move there."
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
    current_check = check?(current_color)
    my_pieces = get_pieces(current_color)
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

    all_in_check = possible_moves.all? do |possible_move|
      checkmate = false
      dupped_board = self.dup_board
      begin
        dupped_board.move(possible_move[0], possible_move[1])
      rescue MoveError
        checkmate = true
      else
      end
      checkmate
    end

    if current_check && all_in_check
      return true
    elsif all_in_check
      @stalemate = true
      return true
    end
  end

  # def stalemate
  #   @stalemate = true
  # end

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
# b.move