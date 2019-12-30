# --- Day 16: Flawed Frequency Transmission ---
#
# You're 3/4ths of the way through the gas giants.  Not only do
# roundtrip signals to Earth take five hours, but the signal quality
# is quite bad as well.  You can clean up the signal with the Flawed
# Frequency Transmission algorithm, or FFT.
#
# As input, FFT takes a list of numbers.  In the signal you received
# (your puzzle input), each number is a single digit: data like 15243
# represents the sequence 1, 5, 2, 4, 3.
#
# FFT operates in repeated phases.  In each phase, a new list is
# constructed with the same length as the input list.  This new list
# is also used as the input for the next phase.
#
# Each element in the new list is built by multiplying every value in
# the input list by a value in a repeating pattern and then adding up
# the results.  So, if the input list were 9, 8, 7, 6, 5 and the
# pattern for a given element were 1, 2, 3, the result would be
# 9*1 + 8*2 + 7*3 + 6*1 + 5*2 (with each input element on the left and
# each value in the repeating pattern on the right of each
# multiplication).  Then, only the ones digit is kept: 38 becomes 8,
# -17 becomes 7, and so on.
#
# While each element in the output array uses all of the same input
# array elements, the actual repeating pattern to use depends on which
# output element is being calculated.  The base pattern is
# 0, 1, 0, -1.  Then, repeat each value in the pattern a number of
# times equal to the position in the output list being considered.
# Repeat once for the first element, twice for the second element,
# three times for the third element, and so on.  So, if the third
# element of the output list is being calculated, repeating the values
# would produce: 0, 0, 0, 1, 1, 1, 0, 0, 0, -1, -1, -1.
#
# When applying the pattern, skip the very first value exactly once.
# (In other words, offset the whole pattern left by one.)  So, for the
# second element of the output list, the actual pattern used would be:
# 0, 1, 1, 0, 0, -1, -1, 0, 0, 1, 1, 0, 0, -1, -1, ....
#
# After using this process to calculate each element of the output
# list, the phase is complete, and the output list of this phase is
# used as the new input list for the next phase, if any.
#
# Given the input signal 12345678, below are four phases of FFT.
# Within each phase, each output digit is calculated on a single line
# with the result at the far right; each multiplication operation
# shows the input digit on the left and the pattern value on the
# right:
#
# Input signal: 12345678
#
# 1*1  + 2*0  + 3*-1 + 4*0  + 5*1  + 6*0  + 7*-1 + 8*0  = 4
# 1*0  + 2*1  + 3*1  + 4*0  + 5*0  + 6*-1 + 7*-1 + 8*0  = 8
# 1*0  + 2*0  + 3*1  + 4*1  + 5*1  + 6*0  + 7*0  + 8*0  = 2
# 1*0  + 2*0  + 3*0  + 4*1  + 5*1  + 6*1  + 7*1  + 8*0  = 2
# 1*0  + 2*0  + 3*0  + 4*0  + 5*1  + 6*1  + 7*1  + 8*1  = 6
# 1*0  + 2*0  + 3*0  + 4*0  + 5*0  + 6*1  + 7*1  + 8*1  = 1
# 1*0  + 2*0  + 3*0  + 4*0  + 5*0  + 6*0  + 7*1  + 8*1  = 5
# 1*0  + 2*0  + 3*0  + 4*0  + 5*0  + 6*0  + 7*0  + 8*1  = 8
#
# After 1 phase: 48226158
#
# 4*1  + 8*0  + 2*-1 + 2*0  + 6*1  + 1*0  + 5*-1 + 8*0  = 3
# 4*0  + 8*1  + 2*1  + 2*0  + 6*0  + 1*-1 + 5*-1 + 8*0  = 4
# 4*0  + 8*0  + 2*1  + 2*1  + 6*1  + 1*0  + 5*0  + 8*0  = 0
# 4*0  + 8*0  + 2*0  + 2*1  + 6*1  + 1*1  + 5*1  + 8*0  = 4
# 4*0  + 8*0  + 2*0  + 2*0  + 6*1  + 1*1  + 5*1  + 8*1  = 0
# 4*0  + 8*0  + 2*0  + 2*0  + 6*0  + 1*1  + 5*1  + 8*1  = 4
# 4*0  + 8*0  + 2*0  + 2*0  + 6*0  + 1*0  + 5*1  + 8*1  = 3
# 4*0  + 8*0  + 2*0  + 2*0  + 6*0  + 1*0  + 5*0  + 8*1  = 8
#
# After 2 phases: 34040438
#
# 3*1  + 4*0  + 0*-1 + 4*0  + 0*1  + 4*0  + 3*-1 + 8*0  = 0
# 3*0  + 4*1  + 0*1  + 4*0  + 0*0  + 4*-1 + 3*-1 + 8*0  = 3
# 3*0  + 4*0  + 0*1  + 4*1  + 0*1  + 4*0  + 3*0  + 8*0  = 4
# 3*0  + 4*0  + 0*0  + 4*1  + 0*1  + 4*1  + 3*1  + 8*0  = 1
# 3*0  + 4*0  + 0*0  + 4*0  + 0*1  + 4*1  + 3*1  + 8*1  = 5
# 3*0  + 4*0  + 0*0  + 4*0  + 0*0  + 4*1  + 3*1  + 8*1  = 5
# 3*0  + 4*0  + 0*0  + 4*0  + 0*0  + 4*0  + 3*1  + 8*1  = 1
# 3*0  + 4*0  + 0*0  + 4*0  + 0*0  + 4*0  + 3*0  + 8*1  = 8
#
# After 3 phases: 03415518
#
# 0*1  + 3*0  + 4*-1 + 1*0  + 5*1  + 5*0  + 1*-1 + 8*0  = 0
# 0*0  + 3*1  + 4*1  + 1*0  + 5*0  + 5*-1 + 1*-1 + 8*0  = 1
# 0*0  + 3*0  + 4*1  + 1*1  + 5*1  + 5*0  + 1*0  + 8*0  = 0
# 0*0  + 3*0  + 4*0  + 1*1  + 5*1  + 5*1  + 1*1  + 8*0  = 2
# 0*0  + 3*0  + 4*0  + 1*0  + 5*1  + 5*1  + 1*1  + 8*1  = 9
# 0*0  + 3*0  + 4*0  + 1*0  + 5*0  + 5*1  + 1*1  + 8*1  = 4
# 0*0  + 3*0  + 4*0  + 1*0  + 5*0  + 5*0  + 1*1  + 8*1  = 9
# 0*0  + 3*0  + 4*0  + 1*0  + 5*0  + 5*0  + 1*0  + 8*1  = 8
#
# After 4 phases: 01029498
#
# Here are the first eight digits of the final output list after 100
# phases for some larger inputs:
#
# - 80871224585914546619083218645595 becomes 24176176.
# - 19617804207202209144916044189917 becomes 73745418.
# - 69317163492948606335995924319873 becomes 52432133.
#
# After 100 phases of FFT, what are the first eight digits in the
# final output list?
#
# --------------------
#
# It is tempting to try to use an actual Fourier transform here, but
# the absolute value and modulus operations are problematic.

Input = open("16.in").read.chomp

def output_digit(signal, j)
  pattern = [0, 1, 0, -1]
  signal.each_with_index.map {|d,i|
    d*pattern[((i+1)/(j+1))%4]
  }.reduce(:+).abs % 10
end

def compute_phase(signal)
  (0...signal.length).map {|i| output_digit(signal, i) }
end

s = Input.chars.map(&:to_i)
100.times do
  s = compute_phase(s)
end
puts s[0, 8].join

# --- Part Two ---
#
# Now that your FFT is working, you can decode the real signal.
#
# The real signal is your puzzle input repeated 10000 times.  Treat
# this new signal as a single input list.  Patterns are still
# calculated as before, and 100 phases of FFT are still applied.
#
# The first seven digits of your initial input signal also represent
# the message offset.  The message offset is the location of the
# eight-digit message in the final output list.  Specifically, the
# message offset indicates the number of digits to skip before reading
# the eight-digit message.  For example, if the first seven digits of
# your initial input signal were 1234567, the eight-digit message
# would be the eight digits after skipping 1,234,567 digits of the
# final output list.  Or, if the message offset were 7 and your final
# output list were 98765432109876543210, the eight-digit message would
# be 21098765.  (Of course, your real message offset will be a
# seven-digit number, not a one-digit number like 7.)
#
# Here is the eight-digit message in the final output list after 100
# phases.  The message offset given in each input has been
# highlighted.  (Note that the inputs given below are repeated 10000
# times to find the actual starting input lists.)
#
#   vvvvvvv
# - 03036732577212944063491565474664 becomes 84462026.
# - 02935109699940807407585447034323 becomes 78725270.
# - 03081770884921959731165446850517 becomes 53553731.
#
# After repeating your input signal 10000 times and running 100 phases
# of FFT, what is the eight-digit message embedded in the final output
# list?
#
# --------------------
#
# We can't reuse the naive approach from part 1 because the numbers
# are far too large.  The solution given here is not entirely
# satisfactory because it relies on characteristics of the input.
#
# The first 12 elements of the first 12 patterns are listed below
# (lines added for clarity).  Notice that the matrix is upper
# triangular, i.e., that output element i is dependent on input
# elements i and higher only.  Notice also that for output elements
# halfway and beyond, the alternating pattern disappears and is
# reduced to simple summation which can be efficienty computed using a
# cumulative sum.
#
#  1  0 -1  0  1  0|-1  0  1  0 -1  0
#  0  1  1  0  0 -1|-1  0  0  1  1  0
#  0  0  1  1  1  0| 0  0 -1 -1 -1  0
#  0  0  0  1  1  1| 1  0  0  0  0 -1
#  0  0  0  0  1  1| 1  1  1  0  0  0
#  0  0  0  0  0  1| 1  1  1  1  1  0
# -----------------+-----------------
#  0  0  0  0  0  0| 1  1  1  1  1  1
#  0  0  0  0  0  0| 0  1  1  1  1  1
#  0  0  0  0  0  0| 0  0  1  1  1  1
#  0  0  0  0  0  0| 0  0  0  1  1  1
#  0  0  0  0  0  0| 0  0  0  0  1  1
#  0  0  0  0  0  0| 0  0  0  0  0  1
#
# The offset in our input is approximately 5.9 million into a signal
# of length 6.5 million, hence we can get away with storing only
# .6 million digits and computing cumulative sums.

def compute_phase_latter_half_only(signal)
  sum = 0
  cs = signal.map {|d| sum += d } # cumulative sum
  (0...cs.length).map {|i| (cs[-1] - (i > 0 ? cs[i-1] : 0)).abs % 10 }
end

offset = Input[0, 7].to_i
raise if offset < Input.length*10000/2
s = Input*(10000-offset/Input.length)
s = s[offset%Input.length..-1].chars.map(&:to_i)
100.times {
  s = compute_phase_latter_half_only(s)
}
puts s[0, 8].join
