# --- Day 17: Set and Forget ---
#
# An early warning system detects an incoming solar flare and
# automatically activates the ship's electromagnetic shield.
# Unfortunately, this has cut off the Wi-Fi for many small robots
# that, unaware of the impending danger, are now trapped on exterior
# scaffolding on the unsafe side of the shield.  To rescue them,
# you'll have to act quickly!
#
# The only tools at your disposal are some wired cameras and a small
# vacuum robot currently asleep at its charging station.  The video
# quality is poor, but the vacuum robot has a needlessly bright LED
# that makes it easy to spot no matter where it is.
#
# An Intcode program, the Aft Scaffolding Control and Information
# Interface (ASCII, your puzzle input), provides access to the cameras
# and the vacuum robot.  Currently, because the vacuum robot is
# asleep, you can only access the cameras.
#
# Running the ASCII program on your Intcode computer will provide the
# current view of the scaffolds.  This is output, purely
# coincidentally, as ASCII code: 35 means #, 46 means ., 10 starts a
# new line of output below the current one, and so on.  (Within a
# line, characters are drawn left-to-right.)
#
# In the camera output, # represents a scaffold and . represents open
# space.  The vacuum robot is visible as ^, v, <, or > depending on
# whether it is facing up, down, left, or right respectively.  When
# drawn like this, the vacuum robot is always on a scaffold; if the
# vacuum robot ever walks off of a scaffold and begins tumbling
# through space uncontrollably, it will instead be visible as X.
#
# In general, the scaffold forms a path, but it sometimes loops back
# onto itself.  For example, suppose you can see the following view
# from the cameras:
#
# ..#..........
# ..#..........
# #######...###
# #.#...#...#.#
# #############
# ..#...#...#..
# ..#####...^..
#
# Here, the vacuum robot, ^ is facing up and sitting at one end of the
# scaffold near the bottom-right of the image.  The scaffold continues
# up, loops across itself several times, and ends at the top-left of
# the image.
#
# The first step is to calibrate the cameras by getting the alignment
# parameters of some well-defined points.  Locate all scaffold
# intersections; for each, its alignment parameter is the distance
# between its left edge and the left edge of the view multiplied by
# the distance between its top edge and the top edge of the view.
# Here, the intersections from the above image are marked O:
#
# ..#..........
# ..#..........
# ##O####...###
# #.#...#...#.#
# ##O###O###O##
# ..#...#...#..
# ..#####...^..
#
# For these intersections:
#
# - The top-left intersection is 2 units from the left of the image
#   and 2 units from the top of the image, so its alignment parameter
#   is 2 * 2 = 4.
# - The bottom-left intersection is 2 units from the left and 4 units
#   from the top, so its alignment parameter is 2 * 4 = 8.
# - The bottom-middle intersection is 6 from the left and 4 from the
#   top, so its alignment parameter is 24.
# - The bottom-right intersection's alignment parameter is 40.
#
# To calibrate the cameras, you need the sum of the alignment
# parameters.  In the above example, this is 76.
#
# Run your ASCII program.  What is the sum of the alignment parameters
# for the scaffold intersections?
#
# --------------------
#
# The camera output looks like this:
#
# ....................############^....
# ....................#................
# ................#######..............
# ................#...#.#..............
# ................#...#.#..............
# ................#...#.#..............
# ................#.#####..............
# ................#.#.#................
# ..........#############..............
# ..........#.....#.#.#.#..............
# ..........#.....#.#.#.#..............
# ..........#.....#.#.#.#..............
# ..........#.....#####.#..............
# ..........#.......#...#..............
# #####.....#.......#...#############..
# #...#.....#.......#...............#..
# #...#.....#.......#...............#..
# #...#.....#.......#...............#..
# #...#.....#.......#############...#..
# #.........#...................#...#..
# ###########...................#...#..
# ..............................#...#..
# ........................#######...#..
# ........................#.........#..
# ......................###########.#..
# ......................#.#.......#.#..
# ......................#.#...#######..
# ......................#.#...#...#....
# ......................#############..
# ........................#...#...#.#..
# ........................#...#####.#..
# ........................#.........#..
# ........................#.........#..
# ........................#.........#..
# ........................#############
# ..................................#.#
# ..................................#.#
# ..................................#.#
# ..................................#.#
# ..................................#.#
# ..............................#####.#
# ..............................#.....#
# ..............................#.....#
# ..............................#.....#
# ..............................#######

Program = open("17.in").read.scan(/-?\d+/).map(&:to_i)

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

directions = [[0,-1], [0,1], [-1,0], [1,0]]
orientations = ["^", "v", "<", ">"] # correspond to the above

def add(a, b)
  [a[0]+b[0],a[1]+b[1]]
end

grid = Hash.new(".")
pos = [0,0]
robot_pos = nil
run {|io,v|
  if io == :output
    robot_pos = pos if orientations.member?(v.chr)
    if v == 10
      pos = [0,pos[1]+1]
    else
      grid[pos] = v.chr
      pos = [pos[0]+1,pos[1]]
    end
  end
}

puts grid.keys.select {|p|
  grid[p] == "#" && directions.all? {|d| grid[add(p,d)] == "#" }
}.map {|x,y| x*y }.reduce(:+)

# --- Part Two ---
#
# Now for the tricky part: notifying all the other robots about the
# solar flare.  The vacuum robot can do this automatically if it gets
# into range of a robot.  However, you can't see the other robots on
# the camera, so you need to be thorough instead: you need to make the
# vacuum robot visit every part of the scaffold at least once.
#
# The vacuum robot normally wanders randomly, but there isn't time for
# that today.  Instead, you can override its movement logic with new
# rules.
#
# Force the vacuum robot to wake up by changing the value in your
# ASCII program at address 0 from 1 to 2.  When you do this, you will
# be automatically prompted for the new movement rules that the vacuum
# robot should use.  The ASCII program will use input instructions to
# receive them, but they need to be provided as ASCII code; end each
# line of logic with a single newline, ASCII code 10.
#
# First, you will be prompted for the main movement routine.  The main
# routine may only call the movement functions: A, B, or C.  Supply
# the movement functions to use as ASCII text, separating them with
# commas (",", ASCII code 44), and ending the list with a newline
# (ASCII code 10).  For example, to call A twice, then alternate
# between B and C three times, provide the string A,A,B,C,B,C,B,C and
# then a newline.
#
# Then, you will be prompted for each movement function.  Movement
# functions may use L to turn left, R to turn right, or a number to
# move forward that many units.  Movement functions may not call other
# movement functions.  Again, separate the actions with commas and end
# the list with a newline.  For example, to move forward 10 units,
# turn left, move forward 8 units, turn right, and finally move
# forward 6 units, provide the string 10,L,8,R,6 and then a newline.
#
# Finally, you will be asked whether you want to see a continuous
# video feed; provide either y or n and a newline.  Enabling the
# continuous video feed can help you see what's going on, but it also
# requires a significant amount of processing power, and may even
# cause your Intcode computer to overheat.
#
# Due to the limited amount of memory in the vacuum robot, the ASCII
# definitions of the main routine and the movement functions may each
# contain at most 20 characters, not counting the newline.
#
# For example, consider the following camera feed:
#
# #######...#####
# #.....#...#...#
# #.....#...#...#
# ......#...#...#
# ......#...###.#
# ......#.....#.#
# ^########...#.#
# ......#.#...#.#
# ......#########
# ........#...#..
# ....#########..
# ....#...#......
# ....#...#......
# ....#...#......
# ....#####......
#
# In order for the vacuum robot to visit every part of the scaffold at
# least once, one path it could take is:
#
# R,8,R,8,R,4,R,4,R,8,L,6,L,2,R,4,R,4,R,8,R,8,R,8,L,6,L,2
#
# Without the memory limit, you could just supply this whole string to
# function A and have the main routine call A once.  However, you'll
# need to split it into smaller parts.
#
# One approach is:
#
# - Main routine: A,B,C,B,A,C
#   (ASCII input: 65, 44, 66, 44, 67, 44, 66, 44, 65, 44, 67, 10)
# - Function A:   R,8,R,8
#   (ASCII input: 82, 44, 56, 44, 82, 44, 56, 10)
# - Function B:   R,4,R,4,R,8
#   (ASCII input: 82, 44, 52, 44, 82, 44, 52, 44, 82, 44, 56, 10)
# - Function C:   L,6,L,2
#   (ASCII input: 76, 44, 54, 44, 76, 44, 50, 10)
#
# Visually, this would break the desired path into the following
# parts:
#
# A,        B,            C,        B,            A,        C
# R,8,R,8,  R,4,R,4,R,8,  L,6,L,2,  R,4,R,4,R,8,  R,8,R,8,  L,6,L,2
#
# CCCCCCA...BBBBB
# C.....A...B...B
# C.....A...B...B
# ......A...B...B
# ......A...CCC.B
# ......A.....C.B
# ^AAAAAAAA...C.B
# ......A.A...C.B
# ......AAAAAA#AB
# ........A...C..
# ....BBBB#BBBB..
# ....B...A......
# ....B...A......
# ....B...A......
# ....BBBBA......
#
# Of course, the scaffolding outside your ship is much more complex.
#
# As the vacuum robot finds other robots and notifies them of the
# impending solar flare, it also can't help but leave them squeaky
# clean, collecting any space dust it finds.  Once it finishes the
# programmed set of movements, assuming it hasn't drifted off into
# space, the cleaning robot will return to its docking station and
# report the amount of space dust it collected as a large, non-ASCII
# value in a single output instruction.
#
# After visiting every part of the scaffold at least once, how much
# dust does the vacuum robot report it has collected?
#
# --------------------
#
# We make some simplifying assumptions regarding robot movement (some
# of these are in the puzzle statement, but we list them here to be
# explicit):
#
# - The robot starts at an endpoint of the scaffolding.
# - The robot is not facing away from the scaffolding (i.e., a 180
#   degree turn is not required).
# - The robot always travels straight through intersections.
# - The robot ends at an endpoint of the scaffolding.
# - By doing so, the entire scaffolding is traversed.
# - By doing so, the puzzle can be solved (i.e., the path can be
#   optimized to satisfy the puzzle constraints).
# - There is no ambiguity (e.g., no scaffolding side-by-side).
#
# With these assumptions, there is exactly one path for the robot to
# take which is easily computed, and the real meat of this puzzle is
# finding a compact representation of that path.

# Phase 1: compute the path.

def left_turn(dir)
  [dir[1], -dir[0]]
end

def right_turn(dir)
  [-dir[1], dir[0]]
end

path = []
pos = robot_pos
dir = directions[orientations.index(grid[robot_pos])]
n = 0
while true
  next_pos = add(pos, dir)
  if grid[next_pos] == "#"
    pos = next_pos
    n += 1
  else
    path << n.to_s if n > 0
    n = 0
    if grid[add(pos, left_turn(dir))] == "#"
      dir = left_turn(dir)
      path << "L"
    elsif grid[add(pos, right_turn(dir))] == "#"
      dir = right_turn(dir)
      path << "R"
    else
      break
    end
  end
end
path = path.join(",") + "," # add trailing comma for pattern matching next

# Phase 2: compact the path.

# Our approach to finding a compact enough representation is as
# follows.  Given 1) an incomplete main routine that describes some
# initial part of the path, 2) the remainder of the path still to be
# compacted, and 3) a (possibly partial) set of function definitions,
# we first try to use an existing function.  Failing that, we try to
# define a new function whose body is up to 20 characters (because
# every part of the path must be described by some function).  With
# success, we recurse on the reduced remaining path; otherwise,
# backtrack.
#
# Another solver employed this brilliant regular expression, which we
# record here for posterity:
#
# ^(.{1,21})\1*(.{1,21})(?:\1|\2)*(.{1,21})(?:\1|\2|\3)*$
#
# While this works for our puzzle input, and while it is tempting to
# use a one-line implementation, it has two limitations: there is no
# guarantee that it will break the path into functions at comma
# boundaries, and it doesn't check that the main routine meets the
# length constraint.  Still, who thought a regular expression could do
# so much?
#
# Our approach finds the following representation (compare with the
# camera output earlier):
#
# main: A,B,A,C,B,A,B,C,C,B
# A: L,12,L,12,R,4
# B: R,10,R,6,R,4,R,4
# C: R,6,L,12,L,12

def compact(main, remainder, functions)
  # N.B.: the main routine and function bodies have trailing commas.
  if remainder.length == 0
    return (main.length <= 21 ? [main, functions] : nil)
  end
  functions.each_with_index do |body,f|
    if remainder.start_with?(body)
      name = ("A".ord+f).chr
      r = compact(main+name+",", remainder[body.length..-1], functions)
      return r if !r.nil?
    end
  end
  return nil if functions.length == 3
  name = ("A".ord+functions.length).chr
  (1..20).select {|i| remainder[i] == "," }.each do |i|
    r = compact(main+name+",", remainder[i+1..-1],
      functions+[remainder[0..i]])
    return r if !r.nil?
  end
  return nil
end

main, functions = compact("", path, [])
raise "failed to find compact representation" if main.nil?

# Phase 3: move the robot.

while functions.length < 3
  functions << ","
end
commands = ([main] + functions).map {|s| s[0..-2] }.join("\n") + "\nn\n"

Program[0] = 2

i = -1
last_v = nil
run {|io,v|
  if io == :input
    i += 1
    commands[i].ord
  else
    # The program outputs quite a bit... we care only about the final
    # value.
    last_v = v
  end
}
puts last_v
