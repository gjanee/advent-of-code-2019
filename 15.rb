# --- Day 15: Oxygen System ---
#
# Out here in deep space, many things can go wrong.  Fortunately, many
# of those things have indicator lights.  Unfortunately, one of those
# lights is lit: the oxygen system for part of the ship has failed!
#
# According to the readouts, the oxygen system must have failed days
# ago after a rupture in oxygen tank two; that section of the ship was
# automatically sealed once oxygen levels went dangerously low.  A
# single remotely-operated repair droid is your only option for fixing
# the oxygen system.
#
# The Elves' care package included an Intcode program (your puzzle
# input) that you can use to remotely control the repair droid.  By
# running that program, you can direct the repair droid to the oxygen
# system and fix the problem.
#
# The remote control program executes the following steps in a loop
# forever:
#
# - Accept a movement command via an input instruction.
# - Send the movement command to the repair droid.
# - Wait for the repair droid to finish the movement operation.
# - Report on the status of the repair droid via an output
#   instruction.
#
# Only four movement commands are understood: north (1), south (2),
# west (3), and east (4).  Any other command is invalid.  The
# movements differ in direction, but not in distance: in a long enough
# east-west hallway, a series of commands like 4,4,4,4,3,3,3,3 would
# leave the repair droid back where it started.
#
# The repair droid can reply with any of the following status codes:
#
# - 0: The repair droid hit a wall.  Its position has not changed.
# - 1: The repair droid has moved one step in the requested direction.
# - 2: The repair droid has moved one step in the requested direction;
#   its new position is the location of the oxygen system.
#
# You don't know anything about the area around the repair droid, but
# you can figure it out by watching the status codes.
#
# For example, we can draw the area using D for the droid, # for
# walls, . for locations the droid can traverse, and empty space for
# unexplored locations.  Then, the initial state looks like this:
#
#
#    D
#
#
#
# To make the droid go north, send it 1.  If it replies with 0, you
# know that location is a wall and that the droid didn't move:
#
#    #
#    D
#
#
#
# To move east, send 4; a reply of 1 means the movement was
# successful:
#
#    #
#    .D
#
#
#
# Then, perhaps attempts to move north (1), south (2), and east (4)
# are all met with replies of 0:
#
#    ##
#    .D#
#     #
#
#
# Now, you know the repair droid is in a dead end.  Backtrack with 3
# (which you already know will get a reply of 1 because you already
# know that location is open):
#
#    ##
#    D.#
#     #
#
#
# Then, perhaps west (3) gets a reply of 0, south (2) gets a reply of
# 1, south again (2) gets a reply of 0, and then west (3) gets a reply
# of 2:
#
#    ##
#   #..#
#   D.#
#    #
#
# Now, because of the reply of 2, you know you've found the oxygen
# system!  In this example, it was only 2 moves away from the repair
# droid's starting position.
#
# What is the fewest number of movement commands required to move the
# repair droid from its starting position to the location of the
# oxygen system?
#
# --------------------
#
# To explore the area, at each step we attempt to move to a cell that
# has not yet been visited and that is not a wall, while maintaining a
# breadcrumb trail back to the starting point and backtracking
# whenever a position is reached where no forward movement is
# possible.  To ensure we can find the shortest path, the entire space
# must be examined.
#
# As expected, the space is not infinite, but bounded by walls, and in
# fact resembles a maze as shown below.  The droid is at D, the oxygen
# system at O.  Cells with ? are unreachable, but by implication are
# walls.
#
# ?#?#########?###########?#######?#####?#?
# # #         #           #       #     # #
# # # # ##### ##### ##### # ##### ### # # #
# # # #     #       #   # #     #     # # #
# # # ##### # ####### # # ##### ####### # #
# #   # #   # #     # # #     #   #     # #
# # ### # ### # ### # # ##### ### # ##### #
# # #   # #   #   # # #     # #   #   #   #
# # ### # ##### ### ####### # # ##### ### #
# #     # #     #   #       #   #   #     #
# ?#### # # ##### ### ########### ####### #
# #   # #   #   #   #   #             #   #
# # ### ##### # ### # # # ####### # ### ##?
# #     #   # # # # # # # #     # #       #
# # ##### # # # # # # # # # ### ######### #
# #   #   # # #   # # #   # # #       #   #
# ?## ### # # ### # ##### # # ####### # ##?
# #   #   #   #   # #   # #   # #   # #   #
# # ### ######### # # # ##### # # # # ####?
# #   # #       # # # #     # #   # #     #
# ?## # # ##### # # # ### ### ##### ##### #
# # # # #     # # #   #D#   # #       # # #
# # # # ##### # ####### # # # # ##### # # #
# # #   # #   #     #   # #     #   #   # #
# # ### # # ####### # ########### # ##### #
# # #   # # #     # #           # #       #
# # # ### # # ### # ########### # ####### #
# # # #   # #   #           #   # #       #
# # # # ### ### ############# ### ########?
# # # #   #   #     #       #   # #   #   #
# # # ### ### ##### # ##### ### # # # # # #
# # #       #   # #   #   #   # # # #   # #
# # ####### ### # ####### ### # # # ##### #
# #       #   #     #       #   # # #O  # #
# # ##### # ####### # # ######### # ### # #
# #     #   #       # #       #       # # #
# ?#### ##### ############# # ####### # # #
# #   #   #   #   #         # #   #     # #
# # # ### # ### # # ######### # # ####### #
# # #     #     #   #           #         #
# ?#?#####?#####?###?###########?#########?

require "set"

Program = open("15.in").read.scan(/-?\d+/).map(&:to_i)

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

OPEN, WALL, OXYGEN = 0, 1, 2
Directions = [[0,-1], [0,1], [-1,0], [1,0]]

def add(a, b)
  [a[0]+b[0],a[1]+b[1]]
end

def movement_command(from, to)
  if from[0] == to[0]
    from[1] < to[1] ? 2 : 1
  else
    from[0] < to[0] ? 4 : 3
  end
end

grid = { [0,0] => OPEN }
pos = [0,0]
next_pos = nil
oxygen_pos = nil
path = []
run {|io,v|
  if io == :input
    next_pos = Directions.map {|d| add(pos, d) }
      .select {|p| !grid.member?(p) }
      .first
    if next_pos.nil?
      break if path.length == 0
      next_pos = path.pop
    end
    movement_command(pos, next_pos)
  else
    if v == 0
      grid[next_pos] = WALL
    else
      if !grid.member?(next_pos)
        if v == 1
          grid[next_pos] = OPEN
        else
          grid[next_pos] = OXYGEN
          oxygen_pos = next_pos
        end
        path << pos
      end
      pos = next_pos
    end
  end
}

def flood_fill(grid, start, &block)
  # Performs a breadth first walk of the open spaces in `grid`
  # starting from `start`, stopping when the associated block, which
  # is passed the nth boundary (i.e., the set of cells distance n from
  # the start), returns true.  Returns n.
  n = 0
  seen = Set.new([start])
  boundary = Set.new([start])
  loop do
    n += 1
    next_boundary = Set.new(
      boundary.flat_map {|p|
        Directions.map {|d| add(p, d) }
          .select {|np| !seen.member?(np) && grid[np] != WALL }
      }
    )
    return n if yield(next_boundary)
    seen.merge(next_boundary)
    boundary = next_boundary
  end
end

puts flood_fill(grid, [0,0]) {|b| b.member?(oxygen_pos) }

# --- Part Two ---
#
# You quickly repair the oxygen system; oxygen gradually fills the
# area.
#
# Oxygen starts in the location containing the repaired oxygen system.
# It takes one minute for oxygen to spread to all open locations that
# are adjacent to a location that already contains oxygen.  Diagonal
# locations are not adjacent.
#
# In the example above, suppose you've used the droid to explore the
# area fully and have the following map (where locations that
# currently contain oxygen are marked O):
#
#  ##
# #..##
# #.#..#
# #.O.#
#  ###
#
# Initially, the only location which contains oxygen is the location
# of the repaired oxygen system.  However, after one minute, the
# oxygen spreads to all open (.) locations that are adjacent to a
# location containing oxygen:
#
#  ##
# #..##
# #.#..#
# #OOO#
#  ###
#
# After a total of two minutes, the map looks like this:
#
#  ##
# #..##
# #O#O.#
# #OOO#
#  ###
#
# After a total of three minutes:
#
#  ##
# #O.##
# #O#OO#
# #OOO#
#  ###
#
# And finally, the whole region is full of oxygen after a total of
# four minutes:
#
#  ##
# #OO##
# #O#OO#
# #OOO#
#  ###
#
# So, in this example, all locations contain oxygen after 4 minutes.
#
# Use the repair droid to get a complete map of the area.  How many
# minutes will it take to fill with oxygen?

puts flood_fill(grid, oxygen_pos) {|b| b.length == 0 } - 1
