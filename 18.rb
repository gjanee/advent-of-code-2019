# --- Day 18: Many-Worlds Interpretation ---
#
# As you approach Neptune, a planetary security system detects you and
# activates a giant tractor beam on Triton!  You have no choice but to
# land.
#
# A scan of the local area reveals only one interesting feature: a
# massive underground vault.  You generate a map of the tunnels (your
# puzzle input).  The tunnels are too narrow to move diagonally.
#
# Only one entrance (marked @) is present among the open passages
# (marked .) and stone walls (#), but you also detect an assortment of
# keys (shown as lowercase letters) and doors (shown as uppercase
# letters).  Keys of a given letter open the door of the same letter:
# a opens A, b opens B, and so on.  You aren't sure which key you need
# to disable the tractor beam, so you'll need to collect all of them.
#
# For example, suppose you have the following map:
#
# #########
# #b.A.@.a#
# #########
#
# Starting from the entrance (@), you can only access a large door (A)
# and a key (a).  Moving toward the door doesn't help you, but you can
# move 2 steps to collect the key, unlocking A in the process:
#
# #########
# #b.....@#
# #########
#
# Then, you can move 6 steps to collect the only other key, b:
#
# #########
# #@......#
# #########
#
# So, collecting every key took a total of 8 steps.
#
# Here is a larger example:
#
# ########################
# #f.D.E.e.C.b.A.@.a.B.c.#
# ######################.#
# #d.....................#
# ########################
#
# The only reasonable move is to take key a and unlock door A:
#
# ########################
# #f.D.E.e.C.b.....@.B.c.#
# ######################.#
# #d.....................#
# ########################
#
# Then, do the same with key b:
#
# ########################
# #f.D.E.e.C.@.........c.#
# ######################.#
# #d.....................#
# ########################
#
# ...and the same with key c:
#
# ########################
# #f.D.E.e.............@.#
# ######################.#
# #d.....................#
# ########################
#
# Now, you have a choice between keys d and e.  While key e is closer,
# collecting it now would be slower in the long run than collecting
# key d first, so that's the best choice:
#
# ########################
# #f...E.e...............#
# ######################.#
# #@.....................#
# ########################
#
# Finally, collect key e to unlock door E, then collect key f, taking
# a grand total of 86 steps.
#
# Here are a few more examples:
#
# - ########################
#   #...............b.C.D.f#
#   #.######################
#   #.....@.a.B.c.d.A.e.F.g#
#   ########################
#
#   Shortest path is 132 steps: b, a, c, d, f, e, g
#
# - #################
#   #i.G..c...e..H.p#
#   ########.########
#   #j.A..b...f..D.o#
#   ########@########
#   #k.E..a...g..B.n#
#   ########.########
#   #l.F..d...h..C.m#
#   #################
#
#   Shortest paths are 136 steps;
#   one is: a, f, b, j, g, n, h, d, l, o, e, p, c, i, k, m
#
# - ########################
#   #@..............ac.GI.b#
#   ###d#e#f################
#   ###A#B#C################
#   ###g#h#i################
#   ########################
#
#   Shortest paths are 81 steps; one is: a, c, f, i, d, g, b, e, h
#
# How many steps is the shortest path that collects all of the keys?
#
# --------------------
#
# Difficult puzzle!  By far the hardest yet.  Approaching it as a
# straightforward shortest path problem seems doomed as the solution
# path must revisit keys and retrace steps.  Our strategy is to
# reconceptualize the problem from navigating from key to key, to
# collecting new keys one at a time.  With this view, if we are at a
# key, and holding some set of previously-collected keys (including
# the current key), we explore all unheld keys which can next be added
# to our set, subject to the keys we hold and any intervening doors.
# Keys that are in the way but already held are disregarded.
#
# To support this view, we construct a complete graph of keys.  Each
# graph edge records the distance of the shortest path between a pair
# of keys and the intervening doors along that shortest path.  We're
# aided here by the fact that all shortest paths between two keys
# share the same intervening doors (we verify this).  For example, the
# following situation does not occur, in which there are two,
# different shortest paths between a and c:
#
# #######
# #..a..#
# #.###B#
# #..c..#
# #######
#
# The starting point is a node in the graph, but it has only outgoing
# edges.
#
# We exhaustively try all permutations of key orders.  The
# combinatorial explosion is mitigated two ways.  One, the intervening
# doors cut down the possibilities, at least initially when few keys
# are held.  Two, caching is very effective because path states can
# collapse.  This phenomenon can be seen in this example given in the
# puzzle:
#
# ########################
# #...............b.C.D.f#
# #.######################
# #.....@.a.B.c.d.A.e.F.g#
# ########################
#
# We have a choice in the beginning between collecting keys a-b-c or
# keys b-a-c.  Either way, we arrive at a state where we are at key c
# and hold keys {a,b,c}.
#
# Keys and sets of keys are represented using bitmasks.  Starting
# points are represented by negative integers.

require "set"

Map = open("18.in").readlines.map {|l| l.chomp }

def load_map
  # Returns [grid, starts] where:
  # grid = { [x,y] => symbol }
  # starts = [[x,y], ...]
  # (The possibility of more than one starting point will be needed in
  # part 2.)
  starts = []
  grid = Map.each_with_index.flat_map {|l,y|
    l.chars.each_with_index.map {|c,x|
      if c == "@"
        starts << [x,y]
        c = "."
      end
      [[x,y], c]
    }
  }.to_h
  [grid, starts]
end

def key?(symbol)
  !!(symbol =~ /[a-z]/)
end

def door?(symbol)
  !!(symbol =~ /[A-Z]/)
end

def to_mask(symbol) # key or door
  1 << (symbol.downcase.ord-"a".ord)
end

def compute_distances(grid, pos)
  # Starting from `pos`, returns { key => {steps:, doors:} } where:
  # key = key in bitmask form
  # steps = distance to key
  # doors = bitmask of intervening doors
  d = {}
  seen = Set.new([pos])
  boundary = { pos => 0 } # position => doors encountered
  n = 0
  loop do
    n += 1
    next_boundary = {}
    boundary.each do |bpos,doors|
      [[0,1], [0,-1], [1,0], [-1,0]].each do |dx,dy|
        npos = [bpos[0]+dx,bpos[1]+dy]
        # The map is surrounded by walls, and we are always starting
        # from an interior point, so the following access is safe.
        s = grid[npos]
        if s != "#" && !seen.member?(npos)
          d[to_mask(s)] = { steps: n, doors: doors } if key?(s)
          m = doors
          m |= to_mask(s) if door?(s)
          # Verify that all shortest paths encounter the same doors.
          raise if next_boundary.fetch(npos, m) != m
          next_boundary[npos] = m
        end
      end
    end
    break if next_boundary.length == 0
    seen.merge(next_boundary.keys)
    boundary = next_boundary
  end
  d
end

def create_key_graph(grid, starts)
  # Returns [graph, all_keys] where:
  # graph = { key => { key => {steps:, doors:} } }
  # key = key in bitmask form, or negative value for starting point
  # (starting points are never destinations)
  # steps = distance to other key
  # doors = bitmask of intervening doors
  # all_keys = union bitmask
  graph = {}
  all_keys = 0
  starts.each_with_index.each do |pos,i|
    graph[-i-1] = compute_distances(grid, pos)
  end
  grid.select {|pos,s| key?(s) }.each do |pos,s|
    k = to_mask(s)
    graph[k] = compute_distances(grid, pos)
    all_keys |= k
  end
  [graph, all_keys]
end

$graph, $all_keys = create_key_graph(*load_map)

$cache = {}
def walk1(key, keys_held)
  return 0 if keys_held == $all_keys
  return $cache[[key, keys_held]] if $cache.member?([key, keys_held])
  l = []
  $graph[key]
    .reject {|k,v| keys_held|k == keys_held }
    .select {|k,v| v[:doors]&keys_held == v[:doors] }
    .each do |k,v|
      n = walk1(k, keys_held|k)
      l << n+v[:steps] if !n.nil?
    end
  r = l.min
  $cache[[key, keys_held]] = r
  r
end

puts walk1(-1, 0)

# --- Part Two ---
#
# You arrive at the vault only to discover that there is not one
# vault, but four - each with its own entrance.
#
# On your map, find the area in the middle that looks like this:
#
# ...
# .@.
# ...
#
# Update your map to instead use the correct data:
#
# @#@
# ###
# @#@
#
# This change will split your map into four separate sections, each
# with its own entrance:
#
# #######       #######
# #a.#Cd#       #a.#Cd#
# ##...##       ##@#@##
# ##.@.##  -->  #######
# ##...##       ##@#@##
# #cB#Ab#       #cB#Ab#
# #######       #######
#
# Because some of the keys are for doors in other vaults, it would
# take much too long to collect all of the keys by yourself.  Instead,
# you deploy four remote-controlled robots. Each starts at one of the
# entrances (@).
#
# Your goal is still to collect all of the keys in the fewest steps,
# but now, each robot has its own position and can move
# independently.  You can only remotely control a single robot at a
# time.  Collecting a key instantly unlocks any corresponding doors,
# regardless of the vault in which the key or door is found.
#
# For example, in the map above, the top-left robot first collects key
# a, unlocking door A in the bottom-right vault:
#
# #######
# #@.#Cd#
# ##.#@##
# #######
# ##@#@##
# #cB#.b#
# #######
#
# Then, the bottom-right robot collects key b, unlocking door B in the
# bottom-left vault:
#
# #######
# #@.#Cd#
# ##.#@##
# #######
# ##@#.##
# #c.#.@#
# #######
#
# Then, the bottom-left robot collects key c:
#
# #######
# #@.#.d#
# ##.#@##
# #######
# ##.#.##
# #@.#.@#
# #######
#
# Finally, the top-right robot collects key d:
#
# #######
# #@.#.@#
# ##.#.##
# #######
# ##.#.##
# #@.#.@#
# #######
#
# In this example, it only took 8 steps to collect all of the keys.
#
# Sometimes, multiple robots might have keys available, or a robot
# might have to wait for multiple keys to be collected:
#
# ###############
# #d.ABC.#.....a#
# ######@#@######
# ###############
# ######@#@######
# #b.....#.....c#
# ###############
#
# First, the top-right, bottom-left, and bottom-right robots take
# turns collecting keys a, b, and c, a total of 6 + 6 + 6 = 18 steps.
# Then, the top-left robot can access key d, spending another 6 steps;
# collecting all of the keys here takes a minimum of 24 steps.
#
# Here's a more complex example:
#
# #############
# #DcBa.#.GhKl#
# #.###@#@#I###
# #e#d#####j#k#
# ###C#@#@###J#
# #fEbA.#.FgHi#
# #############
#
# - Top-left robot collects key a.
# - Bottom-left robot collects key b.
# - Top-left robot collects key c.
# - Bottom-left robot collects key d.
# - Top-left robot collects key e.
# - Bottom-left robot collects key f.
# - Bottom-right robot collects key g.
# - Top-right robot collects key h.
# - Bottom-right robot collects key i.
# - Top-right robot collects key j.
# - Bottom-right robot collects key k.
# - Top-right robot collects key l.
#
# In the above example, the fewest steps to collect all of the keys is
# 32.
#
# Here's an example with more choices:
#
# #############
# #g#f.D#..h#l#
# #F###e#E###.#
# #dCba@#@BcIJ#
# #############
# #nK.L@#@G...#
# #M###N#H###.#
# #o#m..#i#jk.#
# #############
#
# One solution with the fewest steps is:
#
# - Top-left robot collects key e.
# - Top-right robot collects key h.
# - Bottom-right robot collects key i.
# - Top-left robot collects key a.
# - Top-left robot collects key b.
# - Top-right robot collects key c.
# - Top-left robot collects key d.
# - Top-left robot collects key f.
# - Top-left robot collects key g.
# - Bottom-right robot collects key k.
# - Bottom-right robot collects key j.
# - Top-right robot collects key l.
# - Bottom-left robot collects key n.
# - Bottom-left robot collects key m.
# - Bottom-left robot collects key o.
#
# This example requires at least 72 steps to collect all keys.
#
# After updating your map and using the remote-controlled robots, what
# is the fewest steps necessary to collect all of the keys?
#
# --------------------
#
# Remarkably little needs to change for this part.  Instead of the
# state being a (single) current key, it is a list of 4 current keys
# (along with a set of held keys, of course).

x, y = Map[0].length/2, Map.length/2
Map[y-1][x-1..x+1] = "@#@"
Map[y+0][x-1..x+1] = "###"
Map[y+1][x-1..x+1] = "@#@"

$graph, $all_keys = create_key_graph(*load_map)

$cache = {}
def walk4(keys, keys_held)
  return 0 if keys_held == $all_keys
  return $cache[[keys, keys_held]] if $cache.member?([keys, keys_held])
  l = []
  keys.each_with_index do |key,i|
    $graph[key]
      .reject {|k,v| keys_held|k == keys_held }
      .select {|k,v| v[:doors]&keys_held == v[:doors] }
      .each do |k,v|
        keys_next = keys.clone
        keys_next[i] = k
        n = walk4(keys_next, keys_held|k)
        l << n+v[:steps] if !n.nil?
      end
  end
  r = l.min
  $cache[[keys, keys_held]] = r
  r
end

puts walk4((-4..-1).to_a, 0)
