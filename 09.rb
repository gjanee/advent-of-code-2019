# --- Day 9: Sensor Boost ---
#
# You've just said goodbye to the rebooted rover and left Mars when
# you receive a faint distress signal coming from the asteroid belt.
# It must be the Ceres monitoring station!
#
# In order to lock on to the signal, you'll need to boost your
# sensors.  The Elves send up the latest BOOST program - Basic
# Operation Of System Test.
#
# While BOOST (your puzzle input) is capable of boosting your sensors,
# for tenuous safety reasons, it refuses to do so until the computer
# it runs on passes some checks to demonstrate it is a complete
# Intcode computer.
#
# Your existing Intcode computer is missing one key feature: it needs
# support for parameters in relative mode.
#
# Parameters in mode 2, relative mode, behave very similarly to
# parameters in position mode: the parameter is interpreted as a
# position.  Like position mode, parameters in relative mode can be
# read from or written to.
#
# The important difference is that relative mode parameters don't
# count from address 0.  Instead, they count from a value called the
# relative base.  The relative base starts at 0.
#
# The address a relative mode parameter refers to is itself plus the
# current relative base.  When the relative base is 0, relative mode
# parameters and position mode parameters with the same value refer to
# the same address.
#
# For example, given a relative base of 50, a relative mode parameter
# of -7 refers to memory address 50 + -7 = 43.
#
# The relative base is modified with the relative base offset
# instruction:
#
# - Opcode 9 adjusts the relative base by the value of its only
#   parameter.  The relative base increases (or decreases, if the
#   value is negative) by the value of the parameter.
#
# For example, if the relative base is 2000, then after the
# instruction 109,19, the relative base would be 2019.  If the next
# instruction were 204,-34, then the value at address 1985 would be
# output.
#
# Your Intcode computer will also need a few other capabilities:
#
# - The computer's available memory should be much larger than the
#   initial program.  Memory beyond the initial program starts with
#   the value 0 and can be read or written like any other memory.  (It
#   is invalid to try to access memory at a negative address, though.)
# - The computer should have support for large numbers.  Some
#   instructions near the beginning of the BOOST program will verify
#   this capability.
#
# Here are some example programs that use these features:
#
# - 109,1,204,-1,1001,100,1,100,1008,100,16,101,1006,101,0,99 takes no
#   input and produces a copy of itself as output.
# - 1102,34915192,34915192,7,4,7,99,0 should output a 16-digit number.
# - 104,1125899906842624,99 should output the large number in the
#   middle.
#
# The BOOST program will ask for a single input; run it in test mode
# by providing it the value 1.  It will perform a series of checks on
# each opcode, output any opcodes (and the associated parameter modes)
# that seem to be functioning incorrectly, and finally output a BOOST
# keycode.
#
# Once your Intcode computer is fully functional, the BOOST program
# should report no malfunctioning opcodes when run in test mode; it
# should only output a single value, the BOOST keycode.  What BOOST
# keycode does it produce?
#
# --------------------
#
# The program is quite clever in that it really does test opcodes and
# output opcodes that fail.  The first version of this solution
# incorrectly processed an input instruction that uses relative mode,
# and sure enough, the program output 203, the offending opcode.  A
# deconstruction of the program and the faulty operation illustrates
# how it did that:
#
#                              |   @63 @1000    rb |
# -----------------------------+-------------------+---------------------------
# @63 = 34463338 * 34463338    | 11...     0     0 | check multiply
# @63 = @63 < 34463338 ? 1 : 0 |     0     0     0 | "
# goto ... if @63 != 0         |     0     0     0 | "
# @1000 = 0 + 3                |     0     3     0 | check relative mode
# rb += 988                    |     0     3   988 | "
# rb += @(rb+12)               |     0     3   991 | "
# rb += @1000                  |     0     3   994 | "
# rb += @(rb+6)                |     0     3   997 | "
# rb += @(rb+3)                |     0     3  1000 | "
# @(rb+0) << input             |     0     3  1000 | WRONG! should be @1000 = 1
# @63 = @1000 == 1 ? 1 : 0     |     0     3  1000 | continue part 1 if correct
# goto ... if @63 != 0         |     0     3  1000 | "
# @63 = @1000 == 2 ? 1 : 0     |     0     3  1000 | or go to part 2
# goto ... if @63 != 0         |     0     3  1000 | "
# @63 = @1000 == 0 ? 1 : 0     |     0     3  1000 | check @1000 set at all?
# goto ... if @63 != 0         |     0     3  1000 | "
# @25 >> output                |     0     3  1000 | error, output 203
# 0 >> output                  |     0     3  1000 | output 0
# halt

Program = open("09.in").read.scan(/-?\d+/).map(&:to_i)

def run(input)
  input = input.reverse
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
  output = []
  while true
    case p[ip]%100
    when 1
      p[loc[3]] = param[1] + param[2]
      ip += 4
    when 2
      p[loc[3]] = param[1] * param[2]
      ip += 4
    when 3
      p[loc[1]] = input.pop
      ip += 2
    when 4
      output << param[1]
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
  output
end

puts run([1])

# --- Part Two ---
#
# You now have a complete Intcode computer.
#
# Finally, you can lock on to the Ceres distress signal!  You just
# need to boost your sensors using the BOOST program.
#
# The program runs in sensor boost mode by providing the input
# instruction the value 2.  Once run, it will boost the sensors
# automatically, but it might take a few seconds to complete the
# operation on slower hardware.  In sensor boost mode, the program
# will output a single value: the coordinates of the distress signal.
#
# Run the BOOST program in sensor boost mode.  What are the
# coordinates of the distress signal?

puts run([2])
