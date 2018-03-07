#!/usr/local/bin/ruby -w

#  yahtzee.rb
#
#  Created by James Edward Gray II on 2005-02-15.
#  Copyright (c) 2005 Gray Productions. All rights reserved.

# Namespace for all things Yahtzee.
module Yahtzee
	# An object for managing the rolls of a Yahtzee game.
	class Roll
		#
		# Create an instance of Roll.  Methods can then be used the examine the
		# results of the roll and reroll dice.
		#
		def initialize(  )
			@dice = Array.new(5) { rand(6) + 1 }
		end
		
		# Examine the individual dice of a Roll.
		def []( index )
			@dice[index]
		end
	
		# Count occurrences of a set of pips.
		def count( *pips )
			@dice.inject(0) do |total, die|
				if pips.include?(die) then total + 1 else total end
			end
		end
	
		# Add all occurrences of a set of pips, or all the dice.
		def sum( *pips )
			if pips.size == 0
				@dice.inject(0) { |total, die| total + die }
			else
				@dice.inject(0) do |total, die|
					if pips.include?(die) then total + die else total end
				end
			end
		end
	
		#
		# Examines Roll for a pattern of dice, returning true if found.  
		# Patterns can be of the form:
		#
		#     roll.matches?(1, 2, 3, 4)
		#
		# Which validates a sequence, regardless of the actual pips on the dice.
		#
		# You can also use the form:
		# 
		#     roll.matches?(*%w{x x x y y})
		#
		# To validate repetitions.
		#
		# The two forms can be mixed in any combination and when they are, both
		# must match completely.
		#
		def matches?( *pattern )
			digits, letters = pattern.partition { |e| e.is_a?(Integer) }
			matches_digits?(digits) and matches_letters?(letters)
		end
	
		# Reroll selected _dice_.
		def reroll( *dice )
			if dice.size == 0
				@dice = Array.new(5) { rand(6) + 1 }
			else
				indices = [ ]
				pool    = @dice.dup
				dice.each do |d|
					i = pool.index(d) or raise ArgumentError, "Dice not found."
					indices << i
					pool[i] = -1
				end
			
				indices.each { |i| @dice[i] = rand(6) + 1 }
			end
		end
	
		# To make printing out rolls easier.
		def to_s(  )
			"#{@dice[0..-2].join(',')} and #{@dice[-1]}"
		end
	
		private
	
		# Verifies matching of sequence patterns.
		def matches_digits?( digits )
			return true if digits.size < 2
		
			digits.sort!
			test = @dice.uniq.sort
			loop do
				(0..(@dice.length - digits.length)).each do |index|
					return true if test[index, digits.length] == digits
				end
		
				digits.collect! { |d| d + 1 }
				break if digits.last > 6	
			end
		
			false
		end
	
		# Verifies matching of repetition patterns.
		def matches_letters?( letters )
			return true if letters.size < 2
		
			counts = Hash.new(0)
			letters.each { |l| counts[l] += 1 }
			counts = counts.values.sort.reverse
		
			pips = @dice.uniq
			counts.each do |c|
				return false unless match = pips.find { |p| count(p) >= c }
				pips.delete(match)
			end
		
			true
		end
	end

	# A basic score tracking object.
	class Scorecard
		# Create an instance of Scorecard.  Add categories and totals, track
		# score and display results as needed.
		def initialize(  )
			@categories = [ ]
		end
	
		# Add one or more categories to this Scorecard.  Order is maintained.
		def add_categories( *categories )
			categories.each do |cat|
				@categories << [cat, 0]
			end
		end
	
		#
		# Add a total, with a block to calculate it from passed a
		# categories Hash.
		#
		def add_total( name, &calculator )
			@categories << [name, calculator]
		end
		
		#
		# The primary score action method.  Adds _count_ points to the category
		# at _index_.
		#
		def count( index, count )
			@categories.assoc(category(index))[1] += count
		end
	
		# Lookup the score of a given category.
		def []( name )
			@categories.assoc(name)[1]
		end
		
		# Lookup a category name, by _index.
		def category( index )
			id = 0
			@categories.each_with_index do |(name, count_or_calc), i|
				next unless count_or_calc.is_a?(Numeric)
				id += 1
				return @categories[i][0] if id == index
			end

			raise ArgumentError, "Invalid category."
		end
		
		# Support for easy printing.
		def to_s(  )
			id = 0
			@categories.inject("") do |disp, (name, count_or_calc)|
				if count_or_calc.is_a?(Numeric)
					id += 1
					disp + "%3d: %-20s %4d\n" % [id, name, count_or_calc]
				else
					disp + "     %-20s %4d\n" %
						[name, count_or_calc.call(to_hash)]
				end
			end
		end
	
		# Convert category listing to a Hash.
		def to_hash(  )
			@categories.inject(Hash.new) do |hash, (name, count_or_calc)|
				hash[name] = count_or_calc if count_or_calc.is_a?(Numeric)
				hash
			end
		end
	end
end

# Console game interface.
if __FILE__ == $0
	# Assemble Scorecard.
	score = Yahtzee::Scorecard.new()
	UPPER = %w{Ones Twos Threes Fours Fives Sixes}
	UPPER_TOTAL = lambda do |cats|
		cats.inject(0) do |total, (cat, count)|
			if UPPER.include?(cat) then total + count else total end
		end
	end
	score.add_categories(*UPPER)
	score.add_total("Bonus") do |cats|
		upper = UPPER_TOTAL.call(cats)
		if upper >= 63 then 35 else 0 end
	end
	score.add_total("Upper Total") do |cats|
		upper = UPPER_TOTAL.call(cats)
		if upper >= 63 then upper + 35 else upper end
	end
	LOWER = [ "Three of a Kind", "Four of a Kind", "Full House",
			  "Small Straight", "Large Straight", "Yahtzee", "Chance" ]
	bonus_yahtzees = 0
	LOWER_TOTAL = lambda do |cats|
		cats.inject(bonus_yahtzees) do |total, (cat, count)|
			if LOWER.include?(cat) then total + count else total end
		end
	end
	score.add_categories(*LOWER[0..-2])
	score.add_total("Bonus Yahtzees") { bonus_yahtzees }
	score.add_categories(LOWER[-1])
	score.add_total("Lower Total", &LOWER_TOTAL)
	score.add_total("Overall Total") do |cats|
		upper = UPPER_TOTAL.call(cats)
		if upper >= 63
			upper + 35 + LOWER_TOTAL.call(cats)
		else
			upper + LOWER_TOTAL.call(cats)
		end
	end
	
	# Game.
	puts "\nWelcome to Yahtzee!"
	scratches = (1..13).to_a
	13.times do
		# Rolling...
		roll = Yahtzee::Roll.new
		rolls = 2
		while rolls > 0
			puts "\nYou rolled #{roll}."
			print "Action:  (c)heck score, (s)core, (q)uit or #s to reroll?  "
			choice = STDIN.gets.chomp
			case choice
			when /^c/i
				puts "\nScore:\n#{score}"
			when /^s/i
				break
			when /^q/i
				exit
			else
				begin
					pips = choice.gsub(/\s+/, "").split(//).map do |n|
						Integer(n)
					end
					roll.reroll(*pips)
					rolls -= 1
				rescue
					puts "Error:  That not a valid reroll."
				end
			end
		end
		
		# Scoring...
		loop do
			if roll.matches?(*%w{x x x x x}) and score["Yahtzee"] == 50
				bonus_yahtzees += 100
				
				if scratches.include?(roll[0])
					score.count(roll[0], roll.sum(roll[0]))
					scratches.delete(choice)
					puts "Bonus Yahtzee scored in #{score.category(roll[0])}."
					break
				end
				
				puts "Bonus Yahtzee!  100 points added.  " +
				     "Score in lower section as a wild-card."
				bonus_yahtzee = true
			else
				bonus_yahtzee = false
			end
			
			print "\nScore:\n#{score}\n" +
			      "Where would you like to count your #{roll} " +
			      "(# of category)?  "
			begin
				choice = Integer(STDIN.gets.chomp)
				raise "Already scored." unless scratches.include?(choice)
				case choice
				when 1..6
					score.count(choice, roll.sum(choice))
				when 7
					if roll.matches?(*%w{x x x}) or bonus_yahtzee
						score.count(choice, roll.sum())
					end
				when 8
					if roll.matches?(*%w{x x x x}) or bonus_yahtzee
						score.count(choice, roll.sum())
					end
				when 9
					if roll.matches?(*%w{x x x y y}) or bonus_yahtzee
						score.count(choice, 25)
					end
				when 10
					if roll.matches?(1, 2, 3, 4) or bonus_yahtzee
						score.count(choice, 30)
					end
				when 11
					if roll.matches?(1, 2, 3, 4, 5) or bonus_yahtzee
						score.count(choice, 40)
					end
				when 12
					if roll.matches?(*%w{x x x x x})
						score.count(choice, 50)
					end
				when 13
					score.count(choice, roll.sum)
				end
				scratches.delete(choice)
				break
			rescue
				puts "Error:  Invalid category choice."
			end
		end
	end
	
	print "\nFinal Score:\n#{score}\nThanks for playing.\n\n"
end