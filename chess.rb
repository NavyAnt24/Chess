require 'yaml'
require './board.rb'

class Chess
  COLS = "abcdefgh"

  def initialize
    @board = Board.new
  end

  def play
    current_player = :white
    other_player = :black
    until @board.checkmate?(current_player)
      @board.print_board
      puts "It's #{current_player}'s turn."
      puts "You are in check!" if @board.check?(current_player)
      begin
        puts "What piece would you like to move? (e.g. f2)"
        move_from = get_algebraic
        raise MoveError, "That's not your piece." unless my_own_piece(move_from, current_player)
        puts "Where would you like to move to? (e.g. f2)"
        move_to = get_algebraic

        @board.move(move_from, move_to)
      rescue MoveError => e
        puts "#{e.message} Enter another move.".red
        retry
      end
      current_player, other_player = other_player, current_player
    end
    @board.print_board
    if @board.stalemate
      puts "Stalemate!"
    else
      puts "Checkmate!".red.blink
    end
  end

  def my_own_piece(location, current_color)
    if @board.get_piece_at_position(location).nil?
      raise MoveError, "There is no piece there!"
    else
      @board.get_piece_at_position(location).color == current_color
    end
  end

  def get_algebraic
    input = gets.chomp
    debugger if input == "debug"
    if input == "save"
      File.open("chess.yml", 'w') do |f|
        f.write(self.to_yaml)
      end
    end

    col, row = input.split("")
    col = COLS.index(col)
    row = 8 - row.to_i
    [row, col]
  end
end



# if __FILE__ == $PROGRAM_NAME
#   g = Chess.new
#   g.play
# end

g = YAML.load_file('chess.yml')
g.play