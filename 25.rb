# --- Day 25: Cryostasis ---
#
# As you approach Santa's ship, your sensors report two important
# details:
#
# First, that you might be too late: the internal temperature is -40
# degrees.
#
# Second, that one faint life signature is somewhere on the ship.
#
# The airlock door is locked with a code; your best option is to send
# in a small droid to investigate the situation.  You attach your ship
# to Santa's, break a small hole in the hull, and let the droid run in
# before you seal it up again.  Before your ship starts freezing, you
# detach your ship and set it to automatically stay within range of
# Santa's ship.
#
# This droid can follow basic instructions and report on its
# surroundings; you can communicate with it through an Intcode program
# (your puzzle input) running on an ASCII-capable computer.
#
# As the droid moves through its environment, it will describe what it
# encounters.  When it says Command?, you can give it a single
# instruction terminated with a newline (ASCII code 10).  Possible
# instructions are:
#
# - Movement via north, south, east, or west.
# - To take an item the droid sees in the environment, use the command
#   take <name of item>.  For example, if the droid reports seeing a
#   red ball, you can pick it up with take red ball.
# - To drop an item the droid is carrying, use the command drop
#   <name of item>.  For example, if the droid is carrying a green
#   ball, you can drop it with drop green ball.
# - To get a list of all of the items the droid is currently carrying,
#   use the command inv (for "inventory").
#
# Extra spaces or other characters aren't allowed - instructions must
# be provided precisely.
#
# Santa's ship is a Reindeer-class starship; these ships use
# pressure-sensitive floors to determine the identity of droids and
# crew members.  The standard configuration for these starships is for
# all droids to weigh exactly the same amount to make them easier to
# detect.  If you need to get past such a sensor, you might be able to
# reach the correct weight by carrying items from the environment.
#
# Look around the ship and see if you can find the password for the
# main airlock.
#
# --------------------
#
# Our strategy was to play the game manually, by running this program
# with the "interactive" command line option, in order to explore the
# space, discover the available items, find the pressure-sensitive
# floor... and appreciate the humor.  The set of items required to
# pass through was determined fairly quickly by process of
# elimination.  Note that dropped items can be re-taken without having
# to move rooms.

Program = open("25.in").read.scan(/-?\d+/).map(&:to_i)

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

if ARGV[0] == "interactive"

  input = []
  run {|io,v|
    if io == :input
      input = STDIN.gets.chars.map(&:ord) if input.length == 0
      input.shift
    else
      print v.chr
    end
  }

else

  solution = <<~END
  north
  north
  take space heater
  east
  take semiconductor
  west
  south
  south
  east
  take ornament
  south
  take festive hat
  north
  west
  west
  north
  north
  west
  END

  input = solution.chars.map(&:ord)
  output = ""
  run {|io,v|
    if io == :input
      output = ""
      input.shift
    else
      output << v.chr
    end
  }
  puts /get in by typing (\d+) on the keypad/.match(output)[1]

end
