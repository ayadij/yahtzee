class Die
  def initialize
    roll
  end

  def roll
    @number = rand(6) + 1
  end

  def to_s
    @number
  end

  attr_reader :number
end



class Player
  def initialize(game)
    @game = game
    @round = Round.new
  end

  def start_turn
    @game.roll
  end

  def refine(reroll_dice)
    @game.roll(reroll_dice)
  end

  def total_score
    @round.grand_total
  end

  def score(move)
    if (move.nil? || !@round.score(move).nil?)
      -1
    else
      @game.end_turn
      @round.make_move(move, @game.dice)
    end
  end

  def print_board
    @round.print
  end

  def finished?
    @round.complete?
  end
end


class Move
  def initialize(move_type)
    @move_type = move_type
  end

  def make(dice)
    raise "Already made this move" if @score
    @score = send(@move_type, dice)
  end

  attr_reader :score

  private

    def ones(dice)
      sum_for(1, dice)
    end

    def twos(dice)
      sum_for(2, dice)
    end

    def threes(dice)
      sum_for(3, dice)
    end

    def fours(dice)
      sum_for(4, dice)
    end

    def fives(dice)
      sum_for(5, dice)
    end

    def sixes(dice)
      sum_for(6, dice)
    end

    def full_house(dice)
      dice.sort!
      dice.uniq.length == 2 && (dice[0] == dice[1]) && (dice[-1] == dice[-2]) ? 25 : 0
    end

    def small_straight(dice) 
      sorted_dice = dice.uniq.sort
      sorted_dice[0..3] == [1, 2, 3, 4] || sorted_dice[0..3] == [2, 3, 4, 5] || sorted_dice[1..4]== [3, 4, 5, 6] ? 30 : 0
    end

    def large_straight(dice)
      [[1,2,3,4,5], [2,3,4,5,6]].include?(dice.sort) ? 40 : 0
    end

    def three_of_a_kind(dice)
      dice.reject{|d| d != dice.sort[2]}.length >= 3 ? sum(dice) : 0
    end

    def four_of_a_kind(dice)
      dice.reject{|d| d != dice.sort[2]}.length >= 4 ? sum(dice) : 0
    end

    def yahtzee(dice)
      dice.uniq.size == 1 ? 50 : 0
    end

    def chance(dice)
      sum(dice)
    end

    def sum_for(dice_value, dice)
      dice.select{|d| d == dice_value}.inject(0) {|sum, val| sum + val}
    end

    def sum(dice)
      dice.inject() {|sum, val| sum + val}     
    end

end






class Round
  UPPER_MOVES = [:ones, :twos, :threes, :fours, :fives, :sixes]
  LOWER_MOVES = [:full_house, :small_straight, :large_straight, :three_of_a_kind, :four_of_a_kind, :yahtzee, :chance]

  def initialize()
    @moves = Hash.new
    (UPPER_MOVES + LOWER_MOVES).each {|m| @moves[m] = Move.new(m)}
  end

  def upper_total_raw
    subtotal(upper_moves)
  end

  def upper_bonus
    upper_total_raw >= 63 ? 35 : 0
  end

  def upper_total
    upper_total_raw + upper_bonus
  end

  def lower_total
    subtotal(lower_moves)
  end

  def grand_total
    lower_total + upper_total
  end

  def score(move)
    raise "No such move \"${move}\"" if @moves[move].nil?
    @moves[move].score
  end

  def make_move(move, dice)
    raise "Illegal move \"${move}\"" if @moves[move].nil?
    @moves[move].make(dice)
  end

  def complete?
    !@moves.any? {|name, move| move.score.nil?}
  end

  def print
    puts "1s\t\t#{score(:ones)}"
    puts "2s\t\t#{score(:twos)}"
    puts "3s\t\t#{score(:threes)}"
    puts "4s\t\t#{score(:fours)}"
    puts "5s\t\t#{score(:fives)}"
    puts "6s\t\t#{score(:sixes)}"
    puts "bonus\t\t#{upper_bonus}"
    puts "upper total\t#{upper_total}"
    puts "3 of a kind\t#{score(:three_of_a_kind)}"
    puts "4 of a kind\t#{score(:four_of_a_kind)}"
    puts "full house\t#{score(:full_house)}"
    puts "small_straight\t#{score(:small_straight)}"
    puts "large_straight\t#{score(:large_straight)}"
    puts "yahtzee\t\t#{score(:yahtzee)}"
    puts "chance\t\t#{score(:chance)}"
    puts "lower total\t#{lower_total}"
    puts "grand total\t#{grand_total}"
  end

  private
  def subtotal(move_set)
    move_set.map {|name, move| move.score}.inject(0){|total, val| total + (val.nil? ? 0 : val)}
  end

  def upper_moves
    @moves.select {|name,move| UPPER_MOVES.include? name}
  end

  def lower_moves
    @moves.select {|name,move| LOWER_MOVES.include? name}
  end

end






class YahtzeeGame
  def initialize(players = 1)
    @dice = Array.new(5) {Die.new}
    @number_of_players = players
    @current_player_number = 0
    @players = Array.new(@number_of_players) { Player.new(self) }
    @rolls = 0
  end

  def roll(reroll_dice = [0,1,2,3,4])
    if (@rolls < 3)
      reroll_dice.map {|n| @dice[n] }.each do | die | die.roll end
      @rolls = @rolls + 1
    else
      raise "You've had 3 rolls - choose a category to score this turn"
    end
  end

  def end_turn
    @rolls = 0
    @current_player_number = (@current_player_number + 1) % @number_of_players
  end

  def current_player
    @players[@current_player_number]
  end

  def current_player_number
    @current_player_number + 1
  end

  def dice
    @dice.map {|d| d.number}
  end

  def over?
    !@players.any? {|p| !p.finished?}
  end
end

key_move_mappings = {"1" => :ones, "2" => :twos, "3" => :threes,
    "4" => :fours, "5" => :fives, "6" => :sixes,
    "s" => :small_straight, "l" => :large_straight,
    "t" => :three_of_a_kind, "f" => :four_of_a_kind,
    "h" => :full_house, "y" => :yahtzee, "?" => :chance};

players = ARGV.first.to_i || 1
players = 1 if (players <= 0)
game = YahtzeeGame.new(players)
puts "Beginning Yahtzee game with #{players} player#{players != 1 ? "s" : ""}"
until (game.over?)
  puts "Player #{game.current_player_number}'s turn"
  player = game.current_player
  player.start_turn
  puts "Your first roll is #{game.dice.join(', ')}.\nEnter the numbers of the dice you want to reroll (e.g. \"12345\" for all dice)"
  command = $stdin.gets
  reroll_dice = Array.new
  command.each_byte {|s| if (s >= 49 && s < 54) then reroll_dice << s-49 end }
  player.refine(reroll_dice)
  puts "Your second roll is #{game.dice.join(', ')}.\nEnter the numbers of the dice you want to reroll (e.g. \"12345\" for all dice)"
  command = $stdin.gets
  reroll_dice.clear
  command.each_byte {|s| if (s >= 49 && s < 54) then reroll_dice << s-49 end }
  player.refine(reroll_dice)
  puts "Your final roll is #{game.dice.join(', ')}.\nEnter your move - one of: 123456tfslh?y"
  score = -1
  score = player.score(key_move_mappings[$stdin.gets.strip]) until (score != -1)
  puts "You scored #{score} in that move"
  player.print_board
end
puts "The winner is player #{game.current_player_number} with a score of #{player.total_score}"
