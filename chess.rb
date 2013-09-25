require './board.rb'

class Chess
  COLS = "abcdefgh"

  def initialize
    @board = Board.new
  end

  def play
    current_player = :black
    until @board.checkmate?(:black) || @board.checkmate?(:white)
      @board.print_board
      puts "It's #{current_player}'s turn."
      begin
        puts "What piece would you like to move? (e.g. f2)"
        move_from = get_algebraic
        puts "Where would you like to move to? (e.g. f2)"
        move_to = get_algebraic

        @board.move(move_from, move_to)
      rescue MoveError => e
        puts e.message
        retry
      end
      current_player = current_player == :white ? :black : :white
    end
    @board.print_board
    puts "Checkmate!"
  end

  def get_algebraic
    col, row = gets.chomp.split("")
    col = COLS.index(col)
    row = row.to_i - 1
    [row, col]
  end
end



if __FILE__ == $PROGRAM_NAME
  g = Chess.new
  g.play
end