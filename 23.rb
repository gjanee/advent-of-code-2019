# --- Day 23: Category Six ---
#
# The droids have finished repairing as much of the ship as they can.
# Their report indicates that this was a Category 6 disaster - not
# because it was that bad, but because it destroyed the stockpile of
# Category 6 network cables as well as most of the ship's network
# infrastructure.
#
# You'll need to rebuild the network from scratch.
#
# The computers on the network are standard Intcode computers that
# communicate by sending packets to each other.  There are 50 of them
# in total, each running a copy of the same Network Interface
# Controller (NIC) software (your puzzle input).  The computers have
# network addresses 0 through 49; when each computer boots up, it will
# request its network address via a single input instruction.  Be sure
# to give each computer a unique network address.
#
# Once a computer has received its network address, it will begin
# doing work and communicating over the network by sending and
# receiving packets.  All packets contain two values named X and Y.
# Packets sent to a computer are queued by the recipient and read in
# the order they are received.
#
# To send a packet to another computer, the NIC will use three output
# instructions that provide the destination address of the packet
# followed by its X and Y values.  For example, three output
# instructions that provide the values 10, 20, 30 would send a packet
# with X=20 and Y=30 to the computer with address 10.
#
# To receive a packet from another computer, the NIC will use an input
# instruction.  If the incoming packet queue is empty, provide -1.
# Otherwise, provide the X value of the next packet; the computer will
# then use a second input instruction to receive the Y value for the
# same packet.  Once both values of the packet are read in this way,
# the packet is removed from the queue.
#
# Note that these input and output instructions never block.
# Specifically, output instructions do not wait for the sent packet to
# be received - the computer might send multiple packets before
# receiving any.  Similarly, input instructions do not wait for a
# packet to arrive - if no packet is waiting, input instructions
# should receive -1.
#
# Boot up all 50 computers and attach them to your network.  What is
# the Y value of the first packet sent to address 255?
#
# --------------------
#
# We tried to use Ruby threads to implement the computers, but gave
# up.  The difficulty is that the computers are all compute-bound,
# even those waiting for input (they poll continuously).  And
# managing---in fact, just starting up---50 running threads in Ruby
# requires careful use of mutexes, condition variables, waits, etc.
# In the end, to solve the puzzle the logic below must be replicated
# one way or another, and threads add only convolution and horrible
# inefficiency.  (In hindsight, the computers need poll for input only
# once, but the puzzle description clearly implies that they should do
# so always.)

Program = open("23.in").read.scan(/-?\d+/).map(&:to_i)

class Computer

  def initialize(id)
    @input = [id]
    @output = []
    @program = Program.clone
    @ip = 0
    @rb = 0 # relative base
  end

  def idle?
    @input.length == 0
  end

  def run(&block)
    # Runs the computer until it needs more input; may be called again
    # to continue execution.  When a packet for address 255 is
    # encountered, yields the packet to the associated block.
    run_intcode {|io,v|
      if io == :input
        return if idle?
        @input.shift
      else
        @output << v
        if @output.length == 3
          if @output[0] == 255
            yield(@output[1], @output[2])
          else
            $computers[@output[0]].receive(@output[1], @output[2])
          end
          @output.clear
        end
      end
    }
  end

  def receive(x, y)
    @input << x << y
  end

  def kick
    @input << -1
  end

  private

  def run_intcode(&block)
    p = @program # alias
    loc = lambda {|i|
      case (p[@ip]/10**(i+1))%10
      when 0
        p[@ip+i]
      when 1
        @ip+i
      when 2
        p[@ip+i]+@rb
      end
    }
    param = lambda {|i| p[loc[i]] || 0 }
    while true
      case p[@ip]%100
      when 1
        p[loc[3]] = param[1] + param[2]
        @ip += 4
      when 2
        p[loc[3]] = param[1] * param[2]
        @ip += 4
      when 3
        p[loc[1]] = yield(:input, nil)
        @ip += 2
      when 4
        yield(:output, param[1])
        @ip += 2
      when 5
        @ip = (param[1] != 0 ? param[2] : @ip+3)
      when 6
        @ip = (param[1] == 0 ? param[2] : @ip+3)
      when 7
        p[loc[3]] = (param[1] < param[2] ? 1 : 0)
        @ip += 4
      when 8
        p[loc[3]] = (param[1] == param[2] ? 1 : 0)
        @ip += 4
      when 9
        @rb += param[1]
        @ip += 2
      when 99
        break
      end
    end
  end

end

$computers = (0...50).map {|id| Computer.new(id) }
answer = nil
while true
  l = $computers.select {|c| !c.idle? }
  if l.length > 0
    l.each do |c|
      c.run {|x,y|
        answer = y
        break
      }
      break if !answer.nil?
    end
    break if !answer.nil?
  else
    $computers.each {|c| c.kick }
  end
end
puts answer

# --- Part Two ---
#
# Packets sent to address 255 are handled by a device called a NAT
# (Not Always Transmitting).  The NAT is responsible for managing
# power consumption of the network by blocking certain packets and
# watching for idle periods in the computers.
#
# If a packet would be sent to address 255, the NAT receives it
# instead.  The NAT remembers only the last packet it receives; that
# is, the data in each packet it receives overwrites the NAT's packet
# memory with the new packet's X and Y values.
#
# The NAT also monitors all computers on the network.  If all
# computers have empty incoming packet queues and are continuously
# trying to receive packets without sending packets, the network is
# considered idle.
#
# Once the network is idle, the NAT sends only the last packet it
# received to address 0; this will cause the computers on the network
# to resume activity.  In this way, the NAT can throttle power
# consumption of the network when the ship needs power in other areas.
#
# Monitor packets released to the computer at address 0 by the NAT.
# What is the first Y value delivered by the NAT to the computer at
# address 0 twice in a row?

$computers = (0...50).map {|id| Computer.new(id) }
nat_packet = nil
prev_nat_y = nil
while true
  l = $computers.select {|c| !c.idle? }
  if l.length > 0
    l.each do |c|
      c.run {|x,y| nat_packet = [x, y] }
    end
  else
    if nat_packet.nil?
      $computers.each {|c| c.kick }
    else
      break if nat_packet[1] == prev_nat_y
      prev_nat_y = nat_packet[1]
      $computers[0].receive(nat_packet[0], nat_packet[1])
    end
  end
end
puts prev_nat_y
