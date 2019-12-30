# --- Day 24: Planet of Discord ---
#
# You land on Eris, your last stop before reaching Santa.  As soon as
# you do, your sensors start picking up strange life forms moving
# around: Eris is infested with bugs!  With an over 24-hour roundtrip
# for messages between you and Earth, you'll have to deal with this
# problem on your own.
#
# Eris isn't a very large place; a scan of the entire area fits into a
# 5x5 grid (your puzzle input).  The scan shows bugs (#) and empty
# spaces (.).
#
# Each minute, the bugs live and die based on the number of bugs in
# the four adjacent tiles:
#
# - A bug dies (becoming an empty space) unless there is exactly one
#   bug adjacent to it.
# - An empty space becomes infested with a bug if exactly one or two
#   bugs are adjacent to it.
#
# Otherwise, a bug or empty space remains the same.  (Tiles on the
# edges of the grid have fewer than four adjacent tiles; the missing
# tiles count as empty space.)  This process happens in every location
# simultaneously; that is, within the same minute, the number of
# adjacent bugs is counted for every tile first, and then the tiles
# are updated.
#
# Here are the first few minutes of an example scenario:
#
# Initial state:
# ....#
# #..#.
# #..##
# ..#..
# #....
#
# After 1 minute:
# #..#.
# ####.
# ###.#
# ##.##
# .##..
#
# After 2 minutes:
# #####
# ....#
# ....#
# ...#.
# #.###
#
# After 3 minutes:
# #....
# ####.
# ...##
# #.##.
# .##.#
#
# After 4 minutes:
# ####.
# ....#
# ##..#
# .....
# ##...
#
# To understand the nature of the bugs, watch for the first time a
# layout of bugs and empty spaces matches any previous layout.  In the
# example above, the first layout to appear twice is:
#
# .....
# .....
# .....
# #....
# .#...
#
# To calculate the biodiversity rating for this layout, consider each
# tile left-to-right in the top row, then left-to-right in the second
# row, and so on.  Each of these tiles is worth biodiversity points
# equal to increasing powers of two: 1, 2, 4, 8, 16, 32, and so on.
# Add up the biodiversity points for tiles with bugs; in this example,
# the 16th tile (32768 points) and 22nd tile (2097152 points) have
# bugs, a total biodiversity rating of 2129920.
#
# What is the biodiversity rating for the first layout that appears
# twice?
#
# --------------------
#
# We index grid tiles by row and column in this part.

require "set"

grid = open("24.in").each_with_index.flat_map {|l,r|
  l.chomp.chars.each_with_index.map {|v,c| [[r,c], v] }
}.to_h

def next_state(grid, pos, adjacents)
  # Returns the next state of grid[pos] based on `adjacents`, a list
  # of the tile positions adjacent to `pos`.
  n = adjacents.count {|p| grid[p] == "#" }
  if grid[pos] == "#"
    n == 1 ? "#" : "."
  else
    n == 1 || n == 2 ? "#" : "."
  end
end

def evolve(grid)
  grid.each.map {|pos,v|
    r, c = pos
    v = next_state(grid, pos,
      [[0,-1], [0,1], [-1,0], [1,0]].map {|dr,dc| [r+dr,c+dc] } )
    [pos, v]
  }.to_h
end

seen = Set.new([grid])
while true
  grid = evolve(grid)
  break if seen.member?(grid)
  seen.add(grid)
end

def rating(grid)
  (0..4).flat_map {|r|
    (0..4).map {|c| grid[[r,c]] == "#" ? 1 : 0 }
  }.reverse.join.to_i(2)
end

puts rating(grid)

# --- Part Two ---
#
# After careful analysis, one thing is certain: you have no idea where
# all these bugs are coming from.
#
# Then, you remember: Eris is an old Plutonian settlement!  Clearly,
# the bugs are coming from recursively-folded space.
#
# This 5x5 grid is only one level in an infinite number of recursion
# levels.  The tile in the middle of the grid is actually another 5x5
# grid, the grid in your scan is contained as the middle tile of a
# larger 5x5 grid, and so on.  Two levels of grids look like this:
#
#      |     |         |     |
#      |     |         |     |
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#      |     |         |     |
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     | | | | | |     |
#      |     |-+-+-+-+-|     |
#      |     | | | | | |     |
#      |     |-+-+-+-+-|     |
#      |     | | |?| | |     |
#      |     |-+-+-+-+-|     |
#      |     | | | | | |     |
#      |     |-+-+-+-+-|     |
#      |     | | | | | |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#      |     |         |     |
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#      |     |         |     |
#      |     |         |     |
#
# (To save space, some of the tiles are not drawn to scale.)
# Remember, this is only a small part of the infinitely recursive
# grid; there is a 5x5 grid that contains this diagram, and a 5x5 grid
# that contains that one, and so on.  Also, the ? in the diagram
# contains another 5x5 grid, which itself contains another 5x5 grid,
# and so on.
#
# The scan you took (your puzzle input) shows where the bugs are on a
# single level of this structure.  The middle tile of your scan is
# empty to accommodate the recursive grids within it.  Initially, no
# other levels contain bugs.
#
# Tiles still count as adjacent if they are directly up, down, left,
# or right of a given tile.  Some tiles have adjacent tiles at a
# recursion level above or below their own level.  For example:
#
#      |     |         |     |
#   1  |  2  |    3    |  4  |  5
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#   6  |  7  |    8    |  9  |  10
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |A|B|C|D|E|     |
#      |     |-+-+-+-+-|     |
#      |     |F|G|H|I|J|     |
#      |     |-+-+-+-+-|     |
#  11  | 12  |K|L|?|N|O|  14 |  15
#      |     |-+-+-+-+-|     |
#      |     |P|Q|R|S|T|     |
#      |     |-+-+-+-+-|     |
#      |     |U|V|W|X|Y|     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#  16  | 17  |    18   |  19 |  20
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#  21  | 22  |    23   |  24 |  25
#      |     |         |     |
#
# - Tile 19 has four adjacent tiles: 14, 18, 20, and 24.
# - Tile G has four adjacent tiles: B, F, H, and L.
# - Tile D has four adjacent tiles: 8, C, E, and I.
# - Tile E has four adjacent tiles: 8, D, 14, and J.
# - Tile 14 has eight adjacent tiles: 9, E, J, O, T, Y, 15, and 19.
# - Tile N has eight adjacent tiles: I, O, S, and five tiles within
#   the sub-grid marked ?.
#
# The rules about bugs living and dying are the same as before.
#
# For example, consider the same initial state as above:
#
# ....#
# #..#.
# #.?##
# ..#..
# #....
#
# The center tile is drawn as ? to indicate the next recursive grid.
# Call this level 0; the grid within this one is level 1, and the grid
# that contains this one is level -1.  Then, after ten minutes, the
# grid at each level would look like this:
#
# Depth -5:
# ..#..
# .#.#.
# ..?.#
# .#.#.
# ..#..
#
# Depth -4:
# ...#.
# ...##
# ..?..
# ...##
# ...#.
#
# Depth -3:
# #.#..
# .#...
# ..?..
# .#...
# #.#..
#
# Depth -2:
# .#.##
# ....#
# ..?.#
# ...##
# .###.
#
# Depth -1:
# #..##
# ...##
# ..?..
# ...#.
# .####
#
# Depth 0:
# .#...
# .#.##
# .#?..
# .....
# .....
#
# Depth 1:
# .##..
# #..##
# ..?.#
# ##.##
# #####
#
# Depth 2:
# ###..
# ##.#.
# #.?..
# .#.##
# #.#..
#
# Depth 3:
# ..###
# .....
# #.?..
# #....
# #...#
#
# Depth 4:
# .###.
# #..#.
# #.?..
# ##.#.
# .....
#
# Depth 5:
# ####.
# #..#.
# #.?#.
# ####.
# .....
#
# In this example, after 10 minutes, a total of 99 bugs are present.
#
# Starting with your scan, how many bugs are present after 200
# minutes?
#
# --------------------
#
# In this part we index the now infinite grid by index (as in the
# diagram above, but zero-based) and level.
#
# Note that it takes two rounds for bugs to spread one level in each
# direction.  This is because, for increasing levels (analogously for
# decreasing levels), it takes one round to reach the outer tiles
# (A/B/E/J/Y/X/U/P/etc, or, from the higher level's perspective,
# 1/2/5/10/25/24/21/16/etc), then a second round to reach the inner
# tiles (7/8/9/14/19/18/17/12).

Adjacents = [ # [tile index, relative level]
  [[7,-1], [11,-1], [1,0], [5,0]],
  [[7,-1], [0,0], [2,0], [6,0]],
  [[7,-1], [1,0], [3,0], [7,0]],
  [[7,-1], [2,0], [4,0], [8,0]],
  [[7,-1], [13,-1], [3,0], [9,0]],

  [[11,-1], [0,0], [6,0], [10,0]],
  [[1,0], [5,0], [7,0], [11,0]],
  [[2,0], [6,0], [8,0], [0,1], [1,1], [2,1], [3,1], [4,1]],
  [[3,0], [7,0], [9,0], [13,0]],
  [[13,-1], [4,0], [8,0], [14,0]],

  [[11,-1], [5,0], [11,0], [15,0]],
  [[6,0], [10,0], [16,0], [0,1], [5,1], [10,1], [15,1], [20,1]],
  [], # recursive center
  [[8,0], [14,0], [18,0], [4,1], [9,1], [14,1], [19,1], [24,1]],
  [[13,-1], [9,0], [13,0], [19,0]],

  [[11,-1], [10,0], [16,0], [20,0]],
  [[11,0], [15,0], [17,0], [21,0]],
  [[16,0], [18,0], [22,0], [20,1], [21,1], [22,1], [23,1], [24,1]],
  [[13,0], [17,0], [19,0], [23,0]],
  [[13,-1], [14,0], [18,0], [24,0]],

  [[11,-1], [17,-1], [15,0], [21,0]],
  [[17,-1], [16,0], [20,0], [22,0]],
  [[17,-1], [17,0], [21,0], [23,0]],
  [[17,-1], [18,0], [22,0], [24,0]],
  [[13,-1], [17,-1], [19,0], [23,0]]
]

grid = {}
open("24.in").each_with_index do |l,r|
  l.chomp.chars.each_with_index do |v,c|
    grid[[r*5+c,0]] = v if [r,c] != [2,2]
  end
end

def spread(max_level, grid)
  (-(max_level/2+1)..(max_level/2+1)).flat_map {|l|
    (0..24).reject {|i| i == 12 }.map {|i|
      v = next_state(grid, [i,l], Adjacents[i].map {|j,dl| [j,l+dl] })
      [[i,l], v]
    }
  }.to_h
end

200.times do |ml|
  grid = spread(ml, grid)
end
puts grid.values.count("#")
