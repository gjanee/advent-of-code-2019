# --- Day 19: Tractor Beam ---
#
# Unsure of the state of Santa's ship, you borrowed the tractor beam
# technology from Triton.  Time to test it out.
#
# When you're safely away from anything else, you activate the tractor
# beam, but nothing happens.  It's hard to tell whether it's working
# if there's nothing to use it on.  Fortunately, your ship's drone
# system can be configured to deploy a drone to specific coordinates
# and then check whether it's being pulled.  There's even an Intcode
# program (your puzzle input) that gives you access to the drone
# system.
#
# The program uses two input instructions to request the X and Y
# position to which the drone should be deployed.  Negative numbers
# are invalid and will confuse the drone; all numbers should be zero
# or positive.
#
# Then, the program will output whether the drone is stationary (0) or
# being pulled by something (1).  For example, the coordinate X=0, Y=0
# is directly in front of the tractor beam emitter, so the drone
# control program will always report 1 at that location.
#
# To better understand the tractor beam, it is important to get a good
# picture of the beam itself.  For example, suppose you scan the 10x10
# grid of points closest to the emitter:
#
#        X
#   0->      9
#  0#.........
#  |.#........
#  v..##......
#   ...###....
#   ....###...
# Y .....####.
#   ......####
#   ......####
#   .......###
#  9........##
#
# In this example, the number of points affected by the tractor beam
# in the 10x10 area closest to the emitter is 27.
#
# However, you'll need to scan a larger area to understand the shape
# of the beam.  How many points are affected by the tractor beam in
# the 50x50 area closest to the emitter?  (For each of X and Y, this
# will be 0 through 49.)

Program = open("19.in").read.scan(/-?\d+/).map(&:to_i)

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

def within_beam?(x, y)
  first_coord = true
  run {|io,v|
    if io == :input
      v = (first_coord ? x : y)
      first_coord = !first_coord
      v
    else
      return v == 1
    end
  }
end

puts (0..49).map {|y|
  (0..49).count {|x| within_beam?(x, y) }
}.reduce(:+)

# --- Part Two ---
#
# You aren't sure how large Santa's ship is.  You aren't even sure if
# you'll need to use this thing on Santa's ship, but it doesn't hurt
# to be prepared.  You figure Santa's ship might fit in a 100x100
# square.
#
# The beam gets wider as it travels away from the emitter; you'll need
# to be a minimum distance away to fit a square of that size into the
# beam fully.  (Don't rotate the square; it should be aligned to the
# same axes as the drone grid.)
#
# For example, suppose you have the following tractor beam readings:
#
# #.......................................
# .#......................................
# ..##....................................
# ...###..................................
# ....###.................................
# .....####...............................
# ......#####.............................
# ......######............................
# .......#######..........................
# ........########........................
# .........#########......................
# ..........#########.....................
# ...........##########...................
# ...........############.................
# ............############................
# .............#############..............
# ..............##############............
# ...............###############..........
# ................###############.........
# ................#################.......
# .................########*OOOOOOOOO.....
# ..................#######OOOOOOOOOO#....
# ...................######OOOOOOOOOO###..
# ....................#####OOOOOOOOOO#####
# .....................####OOOOOOOOOO#####
# .....................####OOOOOOOOOO#####
# ......................###OOOOOOOOOO#####
# .......................##OOOOOOOOOO#####
# ........................#OOOOOOOOOO#####
# .........................OOOOOOOOOO#####
# ..........................##############
# ..........................##############
# ...........................#############
# ............................############
# .............................###########
#
# In this example, the 10x10 square closest to the emitter that fits
# entirely within the tractor beam has been marked O.  Within it, the
# point closest to the emitter (highlighted with *) is at X=25, Y=20.
#
# Find the 100x100 square closest to the emitter that fits entirely
# within the tractor beam; within that square, find the point closest
# to the emitter.  What value do you get if you take that point's X
# coordinate, multiply it by 10000, then add the point's Y coordinate?
# (In the example above, this would be 250020.)
#
# --------------------
#
# We minimize the number of probes, partially because they are slow
# and partially to take advantage of some geometric analysis.  We
# assume that the beam is formed by two rays emanating from the origin
# whose rough edges are due solely to aliasing.  A corollary of this
# assumption is that as y increases, the x coordinates of the edges of
# the beam increase monotonically.
#
# Let alpha (beta) be the angle the lower (upper) ray makes with the
# positive y axis as diagrammed below.  Consider a square nestled into
# the beam as far as possible, i.e., making contact with both rays.
# Let d be the diagonal length of the square; for us, d = 100*sqrt(2).
# Let y_target be the y coordinate where the square makes contact with
# the lower ray.
#
# x
# ^
# |               beta
# |             -/
# |           -/
# |         -/+--+
# |       -/  |\d|
# |     -/    | \|      alpha
# |   -/      +--+  ---/
# | -/          ---/
# |         ---/
# |     ---/
# | ---/
# +---------------------------> y
#                ^
#                |
#         y_target
#
# Then by the law of sines,
#
#   sin(3*pi/4-beta)    sin(beta-alpha)
# ------------------- = ---------------
# y_target/cos(alpha)          d
#
# or
#
#            sin(3*pi/4-beta)*cos(alpha)
# y_target = --------------------------- d
#                  sin(beta-alpha)
#
# Even with this analysis, we must probe a range of values around
# y_target because the error due to aliasing is considerable.  At the
# range of our solution (approximately y_target=1200), an error due to
# aliasing of +/-1 on each beam edge, or +/-2 overall, results in a
# y_target error of +/-12.  Further, there are subtle effects that can
# cause a square to skip y values where it fits inside the beam.
# Consider this example, from early on in our beam:
#
#          .....#####.........................
#          ......#AAAA........................
#          ......#AAAA........................
#          .......AXXXB.......................
#          .......AXXXB#......................
# pinch -> ........BBBB#......................
#          ........BBBB##.....................
#          .........######....................
#          .........#######...................
#          ..........######...................
#          ...........######..................
#          ...........#######.................
#          ............######.................
#          ............#######................
#          .............#######...............
#
# A 4x4 square fits in the beam at y=pinch-1 (marked with A) and
# y=pinch+1 (marked with B), but not at y=pinch.  So we add a margin
# of 3 probes for safety, and test y_target+/-15.

include Math

def beam_edge(y, angle, side)
  # Returns the x coordinate of the side=:left or side=:right edge
  # cell of the beam at row y.
  if side == :left
    d1, d2 = -1, 1
  else
    d1, d2 = 1, -1
  end
  x = (y*tan(angle)).to_i
  x += d1 until !within_beam?(x, y)
  x += d2 until within_beam?(x, y)
  x
end

def estimate(y_target, alpha, beta)
  # Refines estimates for the arguments.
  alpha = atan2(beam_edge(y_target, alpha, :left), y_target)
  beta = atan2(beam_edge(y_target, beta, :right)+1, y_target)
  y_target = (sin(3*PI/4-beta)*cos(alpha)/sin(beta-alpha)*100*sqrt(2)).to_i
  [y_target, alpha, beta]
end

y_target, alpha, _ = estimate(*estimate(50, PI/6, PI/4))

def square_fits?(x, y)
  [[0,0], [0,-99], [99,0], [99,-99]].all? {|dx,dy| within_beam?(x+dx, y+dy) }
end

puts (y_target-15..y_target+15).flat_map {|y|
  x = beam_edge(y, alpha, :left)
  l = []
  while square_fits?(x, y)
    l << [x,y-99]
    x += 1
  end
  l
}.min_by {|x,y| x*x+y*y }.reduce {|x,y| x*10000+y }
