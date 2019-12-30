# --- Day 13: Care Package ---
#
# As you ponder the solitude of space and the ever-increasing
# three-hour roundtrip for messages between you and Earth, you notice
# that the Space Mail Indicator Light is blinking.  To help keep you
# sane, the Elves have sent you a care package.
#
# It's a new game for the ship's arcade cabinet!  Unfortunately, the
# arcade is all the way on the other end of the ship.  Surely, it
# won't be hard to build your own - the care package even comes with
# schematics.
#
# The arcade cabinet runs Intcode software like the game the Elves
# sent (your puzzle input).  It has a primitive screen capable of
# drawing square tiles on a grid.  The software draws tiles to the
# screen with output instructions: every three output instructions
# specify the x position (distance from the left), y position
# (distance from the top), and tile id.  The tile id is interpreted as
# follows:
#
# - 0 is an empty tile.  No game object appears in this tile.
# - 1 is a wall tile.  Walls are indestructible barriers.
# - 2 is a block tile.  Blocks can be broken by the ball.
# - 3 is a horizontal paddle tile.  The paddle is indestructible.
# - 4 is a ball tile.  The ball moves diagonally and bounces off
#   objects.
#
# For example, a sequence of output values like 1,2,3,6,5,4 would draw
# a horizontal paddle tile (1 tile from the left and 2 tiles from the
# top) and a ball tile (6 tiles from the left and 5 tiles from the
# top).
#
# Start the game.  How many block tiles are on the screen when the
# game exits?

Program = open("13.in").read.scan(/-?\d+/).map(&:to_i)

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

grid = {}
i = 0
x = y = nil
run {|io,v|
  if io == :output
    case i
    when 0
      x = v
    when 1
      y = v
    when 2
      grid[[x,y]] = v
    end
    i = (i+1)%3
  end
}
puts grid.values.count(2)

# --- Part Two ---
#
# The game didn't run because you didn't put in any quarters.
# Unfortunately, you did not bring any quarters.  Memory address 0
# represents the number of quarters that have been inserted; set it to
# 2 to play for free.
#
# The arcade cabinet has a joystick that can move left and right.  The
# software reads the position of the joystick with input instructions:
#
# - If the joystick is in the neutral position, provide 0.
# - If the joystick is tilted to the left, provide -1.
# - If the joystick is tilted to the right, provide 1.
#
# The arcade cabinet also has a segment display capable of showing a
# single number that represents the player's current score.  When
# three output instructions specify X=-1, Y=0, the third output
# instruction is not a tile; the value instead specifies the new score
# to show in the segment display.  For example, a sequence of output
# values like -1,0,12345 would show 12345 as the player's current
# score.
#
# Beat the game by breaking all the blocks.  What is your score after
# the last block is broken?
#
# --------------------
#
# It took some experimentation and visualization to understand the
# nature of this game.  The game initially looks like this, in which
# "#" are walls, "=" is the paddle, "O" is the ball, and "." are
# blocks:
#
# #####################################
# #                                   #
# #     .. .. ..........  .  .. . ... #
# # ... .. ............ . ...... .    #
# #    .... .  ..  ... ... .. . . . . #
# # .... ...... ....... ..  ...   ... #
# #  ........ . ..  ... .. ... .    . #
# # .. .  .. .. .. ........   ... ..  #
# # ...  .... ..  .... . ........ .   #
# #   .... ... .. .. ... ..   .. ..   #
# #  . .   .. .   .  .. ... ... . ..  #
# # .....  . .. ...   ...  .. ... ..  #
# #  ....  .  .... ...   .   .. . ... #
# # ..   ...  .    .... . ..  .  .... #
# #                                   #
# #               O                   #
# #                                   #
# #                                   #
# #                 =                 #
# #                                   #
#
# The ball travels continuously and diagonally, bouncing off walls,
# the paddle, and blocks; blocks are destroyed on contact.  The game
# ends when all blocks have been destroyed, or if the ball drops out
# of the bottom of the grid.  The paddle can be moved left or right
# (only) in response to joystick commands.  Thus, this game is
# essentially Pong.
#
# In each cycle, the game reads a joystick command, moves the paddle
# left or right (or not at all), and then moves the ball.  To ensure
# that the game remains in play, we need only track the paddle
# horizontally as the ball moves horizontally.  Helpfully, at the
# start the ball and paddle are already aligned for a collision.
#
# Run this program with a "visualize" command line argument to see the
# progression of the game graphically (requires the curses gem).  A
# second, optional argument can be a floating point number to insert
# a sleep delay between frames.

visualize = (ARGV[0] == "visualize")
delay = ARGV[1].to_f
if visualize
  require "curses"
  Curses.init_screen
end

draw = Proc.new {
  Curses.clear
  Curses.setpos(0, 0)
  xmin, xmax = grid.keys.map {|x,y| x }.minmax
  ymin, ymax = grid.keys.map {|x,y| y }.minmax
  (ymin..ymax).each do |y|
    Curses.addstr((xmin..xmax).map {|x| " #.=O"[grid[[x,y]]||0] }.join + "\n")
  end
  Curses.refresh
}

Program[0] = 2

grid = {}
i = 0
x = y = paddle_x = ball_x = score = nil
begin
  run {|io,v|
    if io == :input
      ball_x <=> paddle_x
    else
      case i
      when 0
        x = v
      when 1
        y = v
      when 2
        if x == -1 && y == 0
          score = v
        else
          grid[[x,y]] = v
          paddle_x = x if v == 3
          ball_x = x if v == 4
          if visualize
            draw.call
            sleep(delay)
          end
        end
      end
      i = (i+1)%3
    end
  }
ensure
  Curses.close_screen if visualize
end
puts score
