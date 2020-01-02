# --- Day 21: Springdroid Adventure ---
#
# You lift off from Pluto and start flying in the direction of Santa.
#
# While experimenting further with the tractor beam, you accidentally
# pull an asteroid directly into your ship!  It deals significant
# damage to your hull and causes your ship to begin tumbling
# violently.
#
# You can send a droid out to investigate, but the tumbling is causing
# enough artificial gravity that one wrong step could send the droid
# through a hole in the hull and flying out into space.
#
# The clear choice for this mission is a droid that can jump over the
# holes in the hull - a springdroid.
#
# You can use an Intcode program (your puzzle input) running on an
# ASCII-capable computer to program the springdroid.  However,
# springdroids don't run Intcode; instead, they run a simplified
# assembly language called springscript.
#
# While a springdroid is certainly capable of navigating the
# artificial gravity and giant holes, it has one downside: it can only
# remember at most 15 springscript instructions.
#
# The springdroid will move forward automatically, constantly thinking
# about whether to jump.  The springscript program defines the logic
# for this decision.
#
# Springscript programs only use Boolean values, not numbers or
# strings.  Two registers are available: T, the temporary value
# register, and J, the jump register.  If the jump register is true at
# the end of the springscript program, the springdroid will try to
# jump.  Both of these registers start with the value false.
#
# Springdroids have a sensor that can detect whether there is ground
# at various distances in the direction it is facing; these values are
# provided in read-only registers.  Your springdroid can detect ground
# at four distances: one tile away (A), two tiles away (B), three
# tiles away (C), and four tiles away (D).  If there is ground at the
# given distance, the register will be true; if there is a hole, the
# register will be false.
#
# There are only three instructions available in springscript:
#
# - AND X Y sets Y to true if both X and Y are true; otherwise, it
#   sets Y to false.
# - OR X Y sets Y to true if at least one of X or Y is true;
#   otherwise, it sets Y to false.
# - NOT X Y sets Y to true if X is false; otherwise, it sets Y to
#   false.
#
# In all three instructions, the second argument (Y) needs to be a
# writable register (either T or J).  The first argument (X) can be
# any register (including A, B, C, or D).
#
# For example, the one-instruction program NOT A J means "if the tile
# immediately in front of me is not ground, jump."
#
# Or, here is a program that jumps if a three-tile-wide hole (with
# ground on the other side of the hole) is detected:
#
# NOT A J
# NOT B T
# AND T J
# NOT C T
# AND T J
# AND D J
#
# The Intcode program expects ASCII inputs and outputs.  It will begin
# by displaying a prompt; then, input the desired instructions one per
# line.  End each line with a newline (ASCII code 10).  When you have
# finished entering your program, provide the command WALK followed by
# a newline to instruct the springdroid to begin surveying the hull.
#
# If the springdroid falls into space, an ASCII rendering of the last
# moments of its life will be produced.  In these, @ is the
# springdroid, # is hull, and . is empty space.  For example, suppose
# you program the springdroid like this:
#
# NOT D J
# WALK
#
# This one-instruction program sets J to true if and only if there is
# no ground four tiles away.  In other words, it attempts to jump into
# any hole it finds:
#
# .................
# .................
# @................
# #####.###########
#
# .................
# .................
# .@...............
# #####.###########
#
# .................
# ..@..............
# .................
# #####.###########
#
# ...@.............
# .................
# .................
# #####.###########
#
# .................
# ....@............
# .................
# #####.###########
#
# .................
# .................
# .....@...........
# #####.###########
#
# .................
# .................
# .................
# #####@###########
#
# However, if the springdroid successfully makes it across, it will
# use an output instruction to indicate the amount of damage to the
# hull as a single giant integer outside the normal ASCII range.
#
# Program the springdroid with logic that allows it to survey the hull
# without falling into space.  What amount of hull damage does it
# report?
#
# --------------------
#
# This puzzle is really underspecified; perhaps it is more obvious to
# those familiar with video games.  Running the Intcode program with
# an incorrect springscript program prints a helpful graphic display,
# but nevertheless extra hints were required to understand what the
# puzzle is looking for.  To clarify:
#
# - The Intcode program simulates the droid moving left to right over
#   ground tiles.
# - The droid will encounter exactly one, 4-tile hole pattern.
#   Infinite ground tiles both precede and follow the pattern.
# - Because there is nothing to delimit the pattern, the pattern
#   always starts with a hole tile.
# - The droid evaluates the same jump-or-not function (the puzzle
#   solution) at every step, even before encountering the pattern; the
#   function must be a boolean function of ABCD, the four tiles in
#   front of the droid.
# - When the droid jumps, it advances 4 tiles.  Thus, it jumps to the
#   last tile it can see.  Corollary: for any input ABCD for which the
#   droid's function returns true, D must be ground.
# - The droid must be prepared to handle every possible hole pattern
#   that it is possible for the droid to traverse (see next).
# - We apparently need not consider the 4-tile pattern "...." since it
#   is too wide for the droid to jump across.
#
# Observe that the droid always jumps into the pattern.  Consider:
#
# ####PPPP####
# 123456789111
#          012
#
# The droid gets its first glimpse of the pattern at position 1.  It
# can't jump at this position because, as noted previously, the first
# tile in a pattern is always a hole.  Sometime over the course of
# positions 2-4 the droid must jump to positions 6-8.  From that point
# the droid must continue to navigate across the remainder of the
# pattern.
#
# Note that a simple function such as just f=D (always jump if there's
# ground on the other side) won't work.  Consider:
#
# #####.##.###
# 123456789111
#          012
#
# If the droid were to jump at position 1, it would land at
# position 5, but there it would get stuck.  As a result, we must
# effectively also consider the empty pattern "####", and the droid
# must not jump on observing that pattern.
#
# There are seven 4-tile hole patterns to consider (not including
# "####"):
#
# .###
# .##.
# .#.#
# .#..
# ..##
# ..#.
# ...#
#
# Considering the droid's options up to three positions before the
# pattern, we annotate when the droid must jump (only one J in row),
# may jump (more than one J in row), or must not jump (X):
#
# JJJ.###
# JJX.##.
# JXJ.#.#
# JXX.#..
# XJJ..##
# XJX..#.
# XXJ...#
#
# Considering the view from each position where there is a J above,
# the unique inputs for which the function either may or must return
# true are:
#
# ##.#
# #.##
# .###
# .#.#
# #..#
# ..##
# ...#
#
# Plugging these into a 4-variable Boolean truth table, and creating a
# Karnaugh map using an online service (http://32x8.com), yields the
# simplification:
#
# (NOT A OR NOT B OR NOT C) AND D
#
# In words: jump if possible, if there is at least one hole to be
# jumped over.  (Since the truth table includes a mixture of inputs on
# which the droid may jump versus must jump, it is not obvious that a
# Karnaugh map will work; but it does in this case.)  Curiously, we
# stumbled on this simplification that doesn't examine B at all:
#
# (NOT A OR NOT C) AND D

Program = open("21.in").read.scan(/-?\d+/).map(&:to_i)

def run(&block)
  # Runs the program to completion; yields to the associated block for
  # input and output.
  p = Program.clone
  ip = 0
  rb = 0 # relative base
  loc = lambda {|i|
    case (p[ip]/10**(i+1))%10
    when 0
      p[ip+i]
    when 1
      ip+i
    when 2
      p[ip+i]+rb
    end
  }
  param = lambda {|i| p[loc[i]] || 0 }
  while true
    case p[ip]%100
    when 1
      p[loc[3]] = param[1] + param[2]
      ip += 4
    when 2
      p[loc[3]] = param[1] * param[2]
      ip += 4
    when 3
      p[loc[1]] = yield(:input, nil)
      ip += 2
    when 4
      yield(:output, param[1])
      ip += 2
    when 5
      ip = (param[1] != 0 ? param[2] : ip+3)
    when 6
      ip = (param[1] == 0 ? param[2] : ip+3)
    when 7
      p[loc[3]] = (param[1] < param[2] ? 1 : 0)
      ip += 4
    when 8
      p[loc[3]] = (param[1] == param[2] ? 1 : 0)
      ip += 4
    when 9
      rb += param[1]
      ip += 2
    when 99
      break
    end
  end
end

script = <<END
NOT A J
NOT B T
OR T J
NOT C T
OR T J
AND D J
WALK
END

def solve(script)
  s = script.chars.map(&:ord)
  run {|io,v|
    if io == :input
      s.shift
    else
      # ignore the graphical output and return the final value only
      return v if v >= 128
    end
  }
end

puts solve(script) if ARGV[0] != "test"

# --- Part Two ---
#
# There are many areas the springdroid can't reach.  You flip through
# the manual and discover a way to increase its sensor range.
#
# Instead of ending your springcode program with WALK, use RUN.  Doing
# this will enable extended sensor mode, capable of sensing ground up
# to nine tiles away.  This data is available in five new read-only
# registers:
#
# - Register E indicates whether there is ground five tiles away.
# - Register F indicates whether there is ground six tiles away.
# - Register G indicates whether there is ground seven tiles away.
# - Register H indicates whether there is ground eight tiles away.
# - Register I indicates whether there is ground nine tiles away.
#
# All other functions remain the same.
#
# Successfully survey the rest of the hull by ending your program with
# RUN.  What amount of hull damage does the springdroid now report?
#
# --------------------
#
# Despite the expanded view, the droid still jumps 4 tiles.
#
# We found the solution below by starting with the previous solution
# (on the theory that to navigate a 9-tile hole pattern one must first
# navigate a 4-tile pattern), then manually examining how it needed to
# be extended.  Referring to the diagram with Js and Xs above, where
# there are multiple jump options, we are effectively using the
# expanded view to decide which option to use.  Our solution is:
#
# (NOT A OR NOT B OR NOT C) AND D AND (E OR H)
#
# Interestingly, B must be examined here.
#
# Finding this solution was greatly aided by developing a test
# facility.  Run this program with two command line arguments: "test";
# and a function to test written in postfix notation (e.g.,
# "A NOT B NOT C NOT OR OR D AND").  The hole patterns the function
# failed on will be printed, along with a graphical indication of
# where.
#
# A subtle point that caused much confusion: there are hole patterns
# that do not include "....", yet are still untraversable by the
# droid.  An example is ".##.#..##".  As with "....", it seems we are
# not required to consider such patterns.

script = <<END
NOT A J
NOT B T
OR T J
NOT C T
OR T J
AND D J
NOT E T
NOT T T
OR H T
AND T J
RUN
END

if ARGV[0] != "test"
  puts solve(script)
  exit
end

# The remainder of this program is the test facility.

N = 9

def reachable?(pattern, i)
  # Returns true if pattern[i] is a ground tile and can be reached by
  # the droid via some combination of steps and jumps.
  i == 0 || (pattern[i] == "#" &&
    (reachable?(pattern, i-1) || reachable?(pattern, i-4)))
end

def patterns(length)
  # Each hole pattern of length N is padded with N+1 ground tiles on
  # either side.
  (0...2**(length-1))
    .map {|v| ("%0*b" % [length-1, v]).tr("01", "#.") }
    .map {|s| ("#"*(length+1)) + "." + s + ("#"*(length+1)) }
    .select {|p| reachable?(p, p.length-1) }
end

def evaluate(function, view)
  stack = []
  function.split.each do |t|
    case t
    when /^[A-Z]$/
      stack << (view[t.ord-"A".ord] == "#")
    when "NOT"
      stack << !stack.pop
    when "AND"
      v1 = stack.pop
      v2 = stack.pop
      stack << (v1 && v2)
    when "OR"
      v1 = stack.pop
      v2 = stack.pop
      stack << (v1 || v2)
    end
  end
  stack[0]
end

def simulate(function, pattern)
  # Returns true/false on success/failure and the history of the
  # droid's positions.
  history = []
  i = 0
  while i < pattern.length-N
    history << i
    return [false, history] if pattern[i] == "."
    if evaluate(function, pattern[i+1,N])
      i += 4
    else
      i += 1
    end
  end
  [true, history << i]
end

patterns(N).each do |p|
  success, history = simulate(ARGV[1], p)
  if !success
    puts p
    s = " "*p.length
    history.each do |i|
      s[i] = "|"
    end
    s[history[-1]] = "v"
    puts s
  end
end
