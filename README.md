My [Advent of Code 2019](https://adventofcode.com/2019) solutions in
Ruby.

Advent of Code puzzles are usually standalone, but this year half of
them built on an "Intcode" virtual machine.  The Intcode language (if
you will) is defined, and the VM is incrementally constructed over
puzzles 2, 5, and 9.  Our final implementation, in which the VM, a
function, yields to an associated block for I/O, was developed in
puzzle 11 and reused thereafter.
