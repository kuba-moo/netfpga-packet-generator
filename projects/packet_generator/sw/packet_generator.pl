#!/usr/bin/perl -w

#############################################################
# packet_generator
#
# $Id: packet_generator.pl 6036 2010-04-01 00:30:59Z grg $
#
# Load packets from Pcap files into the Packet Generator and
# start the packet Generator
#
# Revisions:
#
##############################################################

use strict;
use warnings;
use POSIX;

use NF::Base;
use NF::PacketGen;
use NF::PacketLib;
use threads;                # pull in threading routines
use threads::shared;        # and variable sharing routines
use NF::RegressLib;
use NF::RegAccess;
use NF::DeviceID;
use Net::Pcap;
use Getopt::Long;
use IO::Handle;
use List::Util qw[max];
use Time::HiRes qw[usleep];
use Math::BigInt;

use reg_defines_packet_generator;


# -------------------------------------
# Constants
# -------------------------------------


# Total memory size in NetFPGA (words)
use constant MEM_SIZE	=> 0x80000;

# Number of ports
use constant NUM_PORTS	=> 4;

# Queue sizes (words)
#   Xmit queue is used for transmission during setup
use constant XMIT_QUEUE_SIZE => 4096;
#   Min RX queue size is the minimum size for the RX queue.
#    - we have 2 * NUM_PORTS queues (tx + rx)
#    - arbitrarily chosen 1/2 * fair sharing b/w all queues
use constant MIN_RX_QUEUE_SIZE => MEM_SIZE / (2 * NUM_PORTS) / 2;
#   Minimum TX queue size
use constant MIN_TX_QUEUE_SIZE => 4;
#   Maximum TX queue size -- allow as much as possible
use constant MAX_TX_QUEUE_SIZE => MEM_SIZE - NUM_PORTS *
		(MIN_RX_QUEUE_SIZE + XMIT_QUEUE_SIZE + MIN_TX_QUEUE_SIZE);

# Clock frequency (Hz)
use constant CLK_FREQ => 125*(10 ** 6);

# Time between bytes
use constant USEC_PER_BYTE => 0.008;
use constant NSEC_PER_BYTE => USEC_PER_BYTE * 1000;

# Various overheads
use constant FCS_LEN => 4;
use constant PREAMBLE_LEN => 8;
use constant INTER_PKT_GAP => 12;
use constant OVERHEAD_LEN => PREAMBLE_LEN + INTER_PKT_GAP;

# Minimum packet size
use constant MIN_PKT_SIZE => 60;


# Globals
my $MAX_ITER = 2 ** (OQ_PKT_GEN_ITER_WIDTH() - 1);

my $queue_addr_offset = OQ_QUEUE_GROUP_INST_OFFSET();

my $total_words = 0;

my @queue_words = (0, 0, 0, 0);
my @queue_bytes = (0, 0, 0, 0);
my @queue_pkts = (0, 0, 0, 0);
my @queue_base_addr = (0, 0, 0, 0);
my @sec_current = (0, 0, 0, 0);
my @usec_current = (0, 0, 0, 0);
my $capture_enable = 0;
my @num_pkts = (0, 0, 0, 0);
my @threads;
my $send_enable = 0;

my @queue_data = ( [], [], [], [] );

my @caplen_warned = (0, 0, 0, 0);

my $help = '';

my $saw_sigusr1 = 0;
my $wait = 0;

my @pcap_filename = ('', '', '', '');
my @capture_filename = ('', '', '', '');
my @final_capture_filename;
my @capture_interfaces;
my @rate = (-1, -1, -1, -1);
my @clks_between_tokens = (-1, -1, -1, -1);
my @number_tokens = (-1, -1, -1, -1);
my @last_len = (0, 0, 0, 0);
my @last_nsec = (0, 0, 0, 0);
my @last_sec = (0, 0, 0, 0);
my @final_pkt_delay = (0, 0, 0, 0);
my @iterations = (1, 1, 1, 1);
my @delay = (-1, -1, -1, -1);
my @usec_per_byte = (USEC_PER_BYTE) x NUM_PORTS;
my $err;
my $xmit_done = 0;
my $resolve_ns = 0;
my $pad = 0;
my $nodrop = 0;

unless ( GetOptions ( 'q0=s' => \$pcap_filename[0],
                      'q1=s' => \$pcap_filename[1],
                      'q2=s' => \$pcap_filename[2],
                      'q3=s' => \$pcap_filename[3],
                      'r0=s' => \$rate[0],
                      'r1=s' => \$rate[1],
                      'r2=s' => \$rate[2],
                      'r3=s' => \$rate[3],
                      'i0=s' => \$iterations[0],
                      'i1=s' => \$iterations[1],
                      'i2=s' => \$iterations[2],
                      'i3=s' => \$iterations[3],
                      'c0=s' => \$capture_filename[0],
                      'c1=s' => \$capture_filename[1],
                      'c2=s' => \$capture_filename[2],
                      'c3=s' => \$capture_filename[3],
                      'd0=i' => \$delay[0],
                      'd1=i' => \$delay[1],
                      'd2=i' => \$delay[2],
                      'd3=i' => \$delay[3],
		      'ns'   => \$resolve_ns,
		      'pad'  => \$pad,
                      'wait' => \$wait,
                      'nodrop' => \$nodrop,
                      'help' => \$help,
        )
  and ($help eq '')
       ) { usage(); exit 1 }

# Catch interupts (SIGINT)
$SIG{INT} = \&INT_Handler;

# Catch wait signal (SIGUSR1)
$SIG{USR1} = \&USR1_Handler;

# Begin by checking that the correct bitfile is downloaded
check_bitfile();

# determine if transmit is enabled
if (($pcap_filename[0] ne '' || $pcap_filename[1] ne '' ||
      $pcap_filename[2] ne '' || $pcap_filename[3] ne '')) {
	$send_enable = 1;
}

# determine if capture is enabled
if (($capture_filename[0] ne '' || $capture_filename[1] ne '' ||
      $capture_filename[2] ne '' || $capture_filename[3] ne '')) {
	$capture_enable = 1;
}

# Need to specify at least one pcap file to load into SRAM or
# one port to capture on
if (!$send_enable && !$capture_enable) {
	usage(); exit 1;
}

# Verify that the number of iterations is correct
for (my $i = 0; $i < NUM_PORTS; $i++) {
	if ($pcap_filename[$i] ne '' &&
	    ($iterations[$i] < 1 || $iterations[$i] > $MAX_ITER)) {
		    print "Error: Iteration count ($iterations[$i]) specified for queue $i is invalid. Must be between 1 and $MAX_ITER.\n\n";
		    exit 1;
	    }
}

if ($capture_enable) {
	@capture_interfaces = determine_capture_interfaces(\@capture_filename);

	if ($#capture_interfaces >= 0) {
		print "Starting packet capture on: " . join(' ', @capture_interfaces) . "\n";

		my @interfaces = ("nf2c0", "nf2c1", "nf2c2", "nf2c3");
		nftest_init(\@ARGV,\@interfaces,);
		nftest_pkt_cap_start(\@capture_interfaces);
	}
}

# Disable the output queues by writing 0x0 to the enable register
packet_generator_enable (0x0);

# Load the pcap files into the host's memory
for (my $i = 0; $i < NUM_PORTS; $i++) {
	# Set the rate limiter
	($clks_between_tokens[$i], $number_tokens[$i]) = rate_limiter_set($i * 2, $rate[$i]);
	if ($rate[$i] > 0) {
		$usec_per_byte[$i] *= (10**6) / $rate[$i];
	}

	if ($pcap_filename[$i] ne '') {
		load_pcap($pcap_filename[$i], $i, $delay[$i]);
	}
}

# Reorganize the queues
queue_reorganize();

# Load the packets into sram
for (my $i = 0; $i < NUM_PORTS; $i++) {
	if ($pcap_filename[$i] ne '') {
		load_queues($i);
	}
}

# Set the rate limiter for CPU queues
for (my $i = 0; $i < 4; $i++) {
	rate_limiter_set($i * 2 + 1, 200000);
}

# Set the number of iterations for the queues with pcap files
for (my $i = 0; $i < NUM_PORTS; $i++) {
	if ($pcap_filename[$i] ne '') {
		set_number_iterations ($iterations[$i], 1, $i);
	}
	# Enable the rate limiter
	if ($rate[$i] > 0) {
		rate_limiter_enable($i * 2);
	}
	else {
		rate_limiter_disable($i * 2);
	}
}

# Enable the rate limiter on the CPU queues
for (my $i = 0; $i < 4; $i++) {
	rate_limiter_enable($i * 2 + 1);
}

# Optionally wait for SIGUSR1 to start packet generator.
# This helps synchronize multi-NetFPGA packet generation.
if ($wait) {
	print "waiting for SIGUSR1\n";
	while(1) {
	    last if ($saw_sigusr1);
	    usleep(1000);
	}
}

# Enable the packet generator hardware to send the packets
my $drop = 0;
if (!$nodrop) {
	for (my $i = 0; $i < NUM_PORTS; $i++) {
		if ($capture_filename[$i] eq '') {
			$drop |= (1 << $i);
		}
	}
	$drop <<= 8;
}
packet_generator_enable ($drop | 0xF);

# Wait until the correct number of packets is sent
my $start = time();
if ($send_enable) {
	print "Sending packets...\n";
	wait_for_last_packet($start);
}
$xmit_done = 1;


# Keep the capture running
if ($capture_enable) {
	wait_for_ctrl_c($start);
}

# Finish up
finish_gen();

exit(0);

###############################################################
# Name: usage
#
# Prints the usage information
#
###############################################################
sub usage {
  (my $cmd = $0) =~ s/.*\///;
  print <<"HERE1";
NAME
   $cmd - Replay and/or capture packets using the PacketGenerator.
          Packets can be loaded from files for replay and received packets can be capture upon reception.

SYNOPSIS
   $cmd
        -q<queue number> <pcap file>
	[-r<queue number> <rate>] (Kbps)
	[-i<queue number> <number of iterations>]
	[-d<queue number> <delay between packets>] (ns)
	[-c<queue number> <capture file>]
	[--pad]
	[--nodrop]
	[--wait]
	[--ns]

   $cmd --help  - show detailed help

HERE1

  return unless ($help);
  print <<"HERE";

DESCRIPTION

   This script loads pcap files into the associated queue in the
the packet generator and sets up the capture of incoming data.
Iteration counts and rate limiters can be specified for each output port.
The packet generator is started once all setup is complete.

OPTIONS
   -q<queue number> <pcap file>
     Specify the pcap file to load in and send from a queue

   -r<queue number> <rate>
     Specify the rate for each queue in Kbps

   -i<queue number> <number of iterations>
     Specify the number of iterations per queue

   -d<queue number> <delay between packets>
     Specify the delay between packets in ns.
     If not specified then the delay recorded in the pcap file
     is used. A value of 0 will disable the delay.

   -c<queue number> <capture file>
     Specify the capture file.

   --pad
     Shorten all packets to 64 bytes maximum and allow the NetFPGA to pad the
     packets when sending them.

   --nodrop
     Don't drop packets on input ports for which we're not capturing

   --wait
     Wait for USR1 signal; helps with synchronizing multiple generators.

   --ns
     Report times with nanosecond precision (default in microsecond).
     Stanard PCAP format only supports microsecond resolution -- nanosecond
     resolution is provided by multiplying all packet times by 1000.
     Thus, 1000s in the PCAP file corresponds to 1s realtime.

EXAMPLE

   % $cmd -q0 udp.pcap -r1 3

HERE
}

###############################################################
# Name: INT_Handler
#
# captures SigINT when capture is enabled.  Saves the capture
# files prior to exit
#
# Arguments:
#
###############################################################

sub INT_Handler {
	my $signame = shift;

	print "\n\n";

	if (!$xmit_done) {
		print "Warning: Program interrupted during operation. Not all packets have\n";
		print "been sent. Some packets may continue to be sent after exiting.\n";
		print "\n";
	}

	finish_gen();
}

###############################################################
# Name: USR1_Handler
#
# captures SigUSR1, used for precisely starting packet generation.
#
# Arguments:
#
###############################################################

sub USR1_Handler {
    $saw_sigusr1 = 1;
}

###############################################################
# Name: finish_gen
#
# Perform the necessary actions when finishing the packet generation
#
# Arguments:
#
###############################################################

sub finish_gen {
	# Disable the packet generator
	#  1. disable the output queues
	#  2. reset the delay module
	#    -- do this multiple times to flush any remaining packets
	#       The syncfifo is 1024 entries deep -- we should need far
	#       fewer than this to ensure the FIFO is flushed
	#  3. disable the packet generator
	for (my $i = 0; $i < NUM_PORTS; $i++) {
		disable_queue($i + 8);
	}
	sleep(1);
	for (my $i = 0; $i < 1024; $i++) {
		reset_delay();
	}
	sleep(1);
	packet_generator_enable(0x0);
	reset_delay();

	if ($capture_enable) {
		save_pcap();
	}

	display_xmit_metrics();
	display_capture_metrics();

	if ($capture_enable) {
		print "Ignore warnings about scalars leaked...\n";
	}
	exit (0);
}


###############################################################
# Name: save_pcap
#
# Saves the pcap files prior to exiting
#
# Arguments:
#
###############################################################

sub save_pcap {
	my %hdr;
	my $pcap_t;
	my $err;

	my $usec;
	my $sec;

	if ($capture_enable == 1) {

		my %packets = nftest_pkt_cap_finish();
		for (my $i = 0; $i < scalar(@capture_interfaces); $i++) {
			print "Writing $final_capture_filename[$i] (" . scalar(@{$packets{$capture_interfaces[$i]}}) . " packets)\n";
			$pcap_t = Net::Pcap::open_live($capture_interfaces[$i], 2000, 0, 0, \$err)
		    or die "Can't open dev '$capture_interfaces[$i]': $err\n";

			# Open Pcap output file
	 		my $dumper = Net::Pcap::dump_open($pcap_t, $final_capture_filename[$i]);
			my @array = @{ $packets{$capture_interfaces[$i]} };

			for ( my $i = 0; $i < scalar(@array); $i++) {
				my $pkt = $array[$i];
				my $hdr = substr($pkt, 0, 24);
				$pkt = substr($pkt, 24);

				# Extract the custom header we place on the packet
				my @hdrvals = unpack("C6C6nnNN", $hdr);
				my $high = bint($hdrvals[14]);
				my $low = bint($hdrvals[15]);
				my $val = $high->blsft(32) + $low;

				my ($sec, $usec);
				if ($resolve_ns) {
					$sec = $val / (10**6);
					$usec = $val % (10 ** 6);
				}
				else {
					$sec = $val / (10**9);
					$usec = ($val % (10 ** 9)) / (10 ** 3);
				}
				$hdr{"len"} = length($pkt);
				$hdr{"caplen"} = length($pkt);
				$hdr{"tv_usec"} = $usec;
				$hdr{"tv_sec"} = $sec;
				Net::Pcap::dump($dumper, \%hdr, $pkt);
			}
			Net::Pcap::dump_close($dumper);
		}
	}
}

###############################################################
# Name: queue_reorganize
#
# Reorganizes the queues
#
# Arguments: None
#
###############################################################

sub queue_reorganize {

	my $queue_addr_offset = OQ_QUEUE_1_ADDR_LO_REG() - OQ_QUEUE_0_ADDR_LO_REG();

	my $curr_addr = 0;

	# Calculate the size of the receive queues
	#  - all unallocated memory given to rx queues
	#  - all receive queues are sized equally
	#    (first queue given any remaining memory)
	my $queue_free = MEM_SIZE - NUM_PORTS * XMIT_QUEUE_SIZE;
	for (my $i = 0; $i < NUM_PORTS; $i++) {
		$queue_free -= get_queue_size($i);
	}
	my @rx_queue_size = (POSIX::floor($queue_free / NUM_PORTS)) x NUM_PORTS;
	$rx_queue_size[0] += $queue_free - NUM_PORTS * $rx_queue_size[0];

	# Disable output queues
	# Note: 3 queues per port -- rx, tx and tx-during-setup
	for (my $i = 0; $i < 3 * NUM_PORTS; $i++) {

		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_CTRL_REG() + ($i) * $queue_addr_offset),
			0x00);
	}

	# Resize the queues
	for (my $i = 0; $i < NUM_PORTS; $i++) {
		# Set queue sizes for tx-during-setup queues
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_LO_REG() + ($i * 2) * $queue_addr_offset),
			$curr_addr);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_HI_REG() + ($i * 2) * $queue_addr_offset),
			$curr_addr + XMIT_QUEUE_SIZE - 1);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_CTRL_REG() + ($i * 2) * $queue_addr_offset),
			0x02);
		$curr_addr += XMIT_QUEUE_SIZE;

		# Set queue sizes for RX queues
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_LO_REG() + ($i * 2 + 1) * $queue_addr_offset),
			$curr_addr);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_HI_REG() + ($i * 2 + 1) * $queue_addr_offset),
			$curr_addr + $rx_queue_size[$i] - 1);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_CTRL_REG() + ($i * 2 + 1) * $queue_addr_offset),
			0x02);
		$curr_addr += $rx_queue_size[$i];
	}

	for (my $i = 0; $i < NUM_PORTS; $i++) {
		my $queue_size = get_queue_size($i);

		# Set queue sizes for TX queues
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_LO_REG() + ($i + 2 * NUM_PORTS) * $queue_addr_offset),
			$curr_addr);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_ADDR_HI_REG() + ($i + 2 * NUM_PORTS) * $queue_addr_offset),
			$curr_addr + $queue_size - 1);
		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_CTRL_REG() + ($i + 2 * NUM_PORTS) * $queue_addr_offset),
			0x02);

		$queue_base_addr[$i] = $curr_addr;
		$curr_addr += $queue_size;
	}

	# Enable Output Queues that are not associated with Packet Generation
	for (my $i = 0; $i < 2 * NUM_PORTS; $i++) {

		nf_regwrite ('nf2c0',
			(OQ_QUEUE_0_CTRL_REG() + ($i) * $queue_addr_offset),
			0x01);
	}

	return 0;
}


###############################################################
# Name: reset_delay
#
# Reset the delay modules
#
###############################################################
sub reset_delay {
	nf_regwrite ('nf2c0', DELAY_RESET_REG(), 1);
}

###############################################################
# Name: disable_queue
#
# Disable one of the queues
#
# Arguments: queue             queue number (0-11)
#
###############################################################
sub disable_queue {
	my $queue = shift;

	nf_regwrite ('nf2c0',
		OQ_QUEUE_0_CTRL_REG() + $queue * $queue_addr_offset,
		0x0);
}

###############################################################
# Name: set_number_iterations
#
# Sets the number of iterations for a Packet Generator Queue
#
# Arguments: number_iterations number of iterations for queue
#            iterations        enable the number of iterations
#            queue             queue number (0-3)
#
# Control register
#       bit 0 -- enable queue
#       bit 1 -- initialize queue (set to 1)
#
###############################################################

sub set_number_iterations {

	my $number_iterations = $_[0];
	my $iterations_enable = $_[1];
	my $queue = $_[2];

	nf_regwrite ('nf2c0',
                   OQ_QUEUE_0_CTRL_REG() + ($queue + 2 * NUM_PORTS) * $queue_addr_offset,
		   0x1);
	nf_regwrite ('nf2c0',
                   OQ_QUEUE_0_MAX_ITER_REG() + ($queue + 2 * NUM_PORTS) * $queue_addr_offset,
		   $number_iterations);

	return 0;
}

###############################################################
# Name: rate_limiter_enable
#
# Enables the rate limiter for a queue
#
# Arguments: queue    queue to enable the rate limiter on
#
###############################################################

sub rate_limiter_enable {

	my $queue = $_[0];

	my $rate_limit_offset = RATE_LIMIT_1_CTRL_REG() - RATE_LIMIT_0_CTRL_REG();

	nf_regwrite ('nf2c0',
                RATE_LIMIT_0_CTRL_REG() + ($queue * $rate_limit_offset),
 							  0x1);

	return 0;
}

###############################################################
# Name: rate_limiter_disable
#
# Disables the rate limiter for a queue
#
# Arguments: queue    queue to disable the rate limiter on
#
###############################################################

sub rate_limiter_disable {

	my $queue = $_[0];

	my $rate_limit_offset = RATE_LIMIT_1_CTRL_REG() - RATE_LIMIT_0_CTRL_REG();

	nf_regwrite ('nf2c0',
                RATE_LIMIT_0_CTRL_REG() + ($queue * $rate_limit_offset),
 							  0x0);

	return 0;
}

###############################################################
# Name: rate_limiter_set
#
# Set the rate limiter value of an output queue
#
# Arguments: queue  queue to enable the rate limiter on
#            rate   the rate to set for the output queue
#
###############################################################

sub rate_limiter_set {

	my $queue = $_[0];
	my $rate = $_[1];

	my $clks_between_tokens = 1000000;
	my $number_tokens = 1;

	my $epsilon = 0.001;
	my $MAX_TOKENS = 84;
	my $BITS_PER_TOKEN = 8;

	# Check if we really need to limit this port
	return (1, 1000000) if ($rate < 1);

	$clks_between_tokens = 1;
	$rate = ($rate * 1000) / $BITS_PER_TOKEN;
	$number_tokens = ($rate * $clks_between_tokens) / CLK_FREQ;

	# Attempt to get the number of tokens as close as possible to a
	# whole number without being too large
	my $token_inc = $number_tokens;
	my $min_delta = 1;
	my $min_delta_clk = 1;
	while (($number_tokens < 1 ||
	        $number_tokens - floor($number_tokens) > $epsilon) &&
	       $number_tokens < $MAX_TOKENS) {

		$number_tokens += $token_inc;
		$clks_between_tokens += 1;

		# Verify that number_tokens exceeds 1
		if ($number_tokens > 1) {
			# See if the delta is lower than the best we've seen so far
			my $delta = $number_tokens - floor($number_tokens);
			if ($delta < $min_delta) {
				$min_delta = $delta;
				$min_delta_clk = $clks_between_tokens;
			}
		}
	}

	# Adjust the number of tokens/clks between tokens to get the closest to a whole number of
	# tokens per increment
	if ($number_tokens - floor($number_tokens) > $epsilon) {
		$clks_between_tokens = $min_delta_clk;
		$number_tokens = floor($token_inc * $clks_between_tokens);
	}

	# Calculate what the actual rate will be
	$rate = $number_tokens * CLK_FREQ / $clks_between_tokens;
	$rate = ($rate * $BITS_PER_TOKEN) / 1000;

	print "Limiting " . queue_name($queue) . " to " . rate_str($rate) . " (";
	print "tokens = $number_tokens, ";
	print "clks = $clks_between_tokens)\n";

	my $rate_limit_offset = RATE_LIMIT_1_CTRL_REG() - RATE_LIMIT_0_CTRL_REG();

	nf_regwrite ('nf2c0',
                RATE_LIMIT_0_TOKEN_INTERVAL_REG() + ($queue * $rate_limit_offset),
                $clks_between_tokens);
	nf_regwrite ('nf2c0',
                RATE_LIMIT_0_TOKEN_INC_REG() + ($queue * $rate_limit_offset),
                $number_tokens);

	return $clks_between_tokens, $number_tokens;
}

###############################################################
# Name: load_pcap
#
# Loads the Pcap file a packet at a time and stores the packet
# into SRAM in the appropriate Packet Generator Queue.  It will
# only load the full packets upto the queue size.  If there are
# more packets in the Pcap file than can fit in the queue, they
# are ignored. If there is no delay specified the delay between
# packets in the Pcap file is used.
#
# Arguments: pcap_filename      Filename of the Pcap to load
#            queue              Queue to load the Pcap into
#            delay              Specified delay between packets
#
###############################################################

sub load_pcap {

	my $pcap_filename = $_[0];
	my $queue = $_[1];
	my $delay = $_[2];

	my $err;
	my %hdr;
	my $packet;
	my $load_pkt = 0;

	my $pcap_t = Net::Pcap::open_offline($pcap_filename, \$err)
		or die "Can't read '$pcap_filename': $err\n";

	# While there are still packets in the Pcap file
	#   and there is space in the queue read them in

	$packet = Net::Pcap::next($pcap_t, \%hdr);

	$sec_current[$queue] = $hdr{"tv_sec"};
	$usec_current[$queue] = $hdr{"tv_usec"};

	while ( %hdr && !($load_pkt == 1) ) {

		#print "Packet Number:$num_pkts\n";
		if ($hdr{'len'} != $hdr{'caplen'} && !$caplen_warned[$queue]) {
			print "Warning: The capture length was less than the packet length for one";
			print " or more packets in '$pcap_filename'. Packets will be padded with zeros.\n";
			$caplen_warned[$queue] = 1;
		}

		$load_pkt = load_packet (\%hdr, $packet, $queue, $delay);

		undef %hdr;
		$packet = Net::Pcap::next($pcap_t, \%hdr);
		if ($load_pkt == 0) {
			$num_pkts[$queue]++;
		}
	}

	print "Loaded $num_pkts[$queue] packet(s) into " . queue_name($queue + 8) . "\n";

	# Close the pcap file
	Net::Pcap::close($pcap_t);

	return 0;
}

###############################################################
# Name: determine_capture_interfaces
#
# Takes the capture filenames array and determines which
# interfaces to capture on. Returns an array
#
# Arguments: capture_filenames  Array of capture filenames from
#                               from the command line
#
###############################################################

sub determine_capture_interfaces {
	my @capture_filenames = @{$_[0]};
	my @interfaces;

	for (my $i = 0; $i < scalar(@capture_filenames); $i++) {
		if ($capture_filenames[$i] ne '' && $capture_filenames[$i] ne '-') {
			push(@interfaces, "nf2c$i");
			push(@final_capture_filename, $capture_filenames[$i]);
		}
	}

	return @interfaces;
}

###############################################################
# Name: load_packet
#
# Load a packet into (host) memory in a form suitable for
# uploading to the NetFPGA
#
# Arguments: hdr                pcap header for the packet
#            packet             the packet form the Pcap file
#            queue              SRAM queue to insert the packet
#                               (0-3)
#            delay              delay (if specified)
#		                -1 uses Pcap delay
#
###############################################################

sub load_packet {

	my %hdr = %{$_[0]};
	my $packet = $_[1];
	my $queue = $_[2];
	my $delay = $_[3];
	my $src_port = 0;
	my $dst_port = 0x100;
	my $sec = $hdr{"tv_sec"};
	my $usec = $hdr{"tv_usec"};
	my $len = $hdr{"len"};
	my $caplen = $hdr{"caplen"};
	my $word_len = POSIX::ceil($len / 8);
	my $packet_words;

	$dst_port = ($dst_port << $queue);

	# If the delay is not specified assign based on the Pcap file
	if ($delay == -1) {
		$delay = $sec - $sec_current[$queue];
		$delay = $delay * 1000000; # convert to usec
		$delay = (($usec + $delay) - $usec_current[$queue]);
		$delay = $delay * 1000; # convert to nsec
	}

	# Work out if this packet should be padded
	my $non_pad_len = $len;
	my $non_pad_word_len = $word_len;
	my $write_pad = 0;
	if ($pad && $non_pad_len > 64) {
		$write_pad = 1;
		$non_pad_len = 64;
		$non_pad_word_len = 8;
	}

	# Check if there is room in the queue for the entire packet
	# 	If there is no room return 1
	$packet_words = $non_pad_word_len + 1 + ($delay > 0) + ($write_pad);
	if ( ($packet_words + $total_words) > MAX_TX_QUEUE_SIZE) {
		print "Warning: unable to load all packets from pcap file. SRAM queues are full.\n";
		print "Total output queue size: " . MAX_TX_QUEUE_SIZE . " words\n";
		print "Current queue occupancy: $total_words words\n";
		print "Packet size: $packet_words words\n";
		return (1);
	}
	else {
		$total_words += $packet_words;
		$queue_words[$queue] += $packet_words;
		$queue_bytes[$queue] += $len;
		$queue_pkts[$queue]++;
	}

	# Update the current time
	$sec_current[$queue] = $sec;
	$usec_current[$queue] = $usec;

	$usec_current[$queue] += ($len + 4) * $usec_per_byte[$queue];

	while ($usec_current[$queue] > 10**6) {
		$usec_current[$queue] -= 10**6;
		$sec_current[$queue]++;
	}

	# Load module hdr into SRAM
	push (@{$queue_data[$queue]},
		IO_QUEUE_STAGE_NUM(),
		$non_pad_word_len | ($dst_port << 16),
		($non_pad_len | ($src_port << 16)));

	# Load pad hdr into SRAM
	if ($write_pad) {
		push (@{$queue_data[$queue]},
			PAD_CTRL_VAL(),
			$word_len | ($dst_port << 16),
			($len | ($src_port << 16)));
	}

	# Load delay into SRAM if it exists
	if ($delay > 0) {
		push (@{$queue_data[$queue]},
			DELAY_CTRL_VAL(),
			floor($delay / 2**32),
			$delay % 2**32);
	}

	# Store the packet into SRAM
	my @pkt = unpack_packet_and_pad($packet, $len, $caplen);

	for (my $i = 0; $i < scalar(@pkt); $i += 2){
		my $ctrl = 0x0;
		if ($i / 2 == $non_pad_word_len - 1) {
			$ctrl = 0x100 >> ($non_pad_len % 8);
			$ctrl = $ctrl & 0xff | ($ctrl == 0x100);
		}
		my $word1 = $pkt[$i + 0];
		my $word2 = $pkt[$i + 1];

		push (@{$queue_data[$queue]}, $ctrl, $word1, $word2);
	}


	# Calculate the delay between the preceding packet and this packet
	# It should be the maximum of the delay specified in the header
	# and the delay introduced by the rate limiter
	my $delay_hdr = $delay;
	my $delay_rate = 0;
	if ($rate[$queue] >= 1) {
		$delay_rate = ceil($last_len[$queue] / $number_tokens[$queue]);
		$delay_rate *= $clks_between_tokens[$queue] * NSEC_PER_BYTE;
	}
	my $delay_max = $delay_hdr > $delay_rate ? $delay_hdr : $delay_rate;
	$delay_max -= ($last_len[$queue] + FCS_LEN) * NSEC_PER_BYTE;
	$delay_max = 0 if ($delay_max < 0);
	$delay_max += (($len > MIN_PKT_SIZE ? $len : MIN_PKT_SIZE) +
		FCS_LEN + OVERHEAD_LEN) * NSEC_PER_BYTE;

	# Update packet transmit time
	$last_nsec[$queue] += $delay_max;
	$last_len[$queue] = $len;

	while ($last_nsec[$queue] > 10**9) {
		$last_nsec[$queue] -= 10**9;
		$last_sec[$queue]++;
	}

	# Assume this is the last packet and update the amount of extra time
	# to wait for this packet to pass through the delay module. (We'll
	# eventually guess right that this is the last packet.)
	$final_pkt_delay[$queue] = 0;
	if ($rate[$queue] >= 1) {
		$final_pkt_delay[$queue] = ceil(($len + FCS_LEN) / $number_tokens[$queue]);
		$final_pkt_delay[$queue] *= $clks_between_tokens[$queue];
		$final_pkt_delay[$queue] -= $len + FCS_LEN;
		$final_pkt_delay[$queue] *= NSEC_PER_BYTE;
	}

	return 0;
}

###############################################################
# Name: packet_generator_enable
#
# Enable the Packet Generator Hardware
#
# Arguments: enable_queues      0xf enables all queues
#
# Enable register definition:
#	    Bits    Description
#     31:4    Ignored
#     3       Enable packet gen on nf2c3 (1=enable, 0=disable)
#     2       Enable packet gen on nf2c2 (1=enable, 0=disable)
#     1       Enable packet gen on nf2c1 (1=enable, 0=disable)
#     0       Enable packet gen on nf2c0 (1=enable, 0=disable)
#
###############################################################

sub packet_generator_enable {

	my $enable_queues = $_[0];

	# Start the queues that are passed into the function

	nf_regwrite ('nf2c0', PKT_GEN_CTRL_ENABLE_REG(),  $enable_queues);

	return 0;
}


###############################################################
# Name: queue_name
#
# Convert a queue number to a name
#
# Arguments: queue      Queue number
#
###############################################################

sub queue_name {
	my $queue = shift;

	if ($queue < 0 || $queue >= 12) {
		return "Invalid queue";
	}
	elsif ($queue < 8) {
		if ($queue % 2 == 0) {
			return "MAC Queue " . ($queue / 2);
		}
		else {
			return "CPU Queue " . (($queue - 1) / 2);
		}

	}
	else {
		return "MAC Queue " . ($queue - 8);
	}
}


###############################################################
# Name: rate_str
#
# Convert a rate to a string. Attempts to choose the most
# sensible set of units (Gbps, Mbps, Kbps)
#
# Arguments: rate      Data rate
#
###############################################################

sub rate_str {
	my $rate = shift;

	if ($rate < 1000) {
		return "$rate Kbps";
	}
	elsif ($rate < 1000000) {
		return (sprintf("%1.3f Mbps", $rate / 1000));
	}
	else {
		return (sprintf("%1.3f Gbps", $rate / 1000000));
	}
}


###############################################################
# Name: wait_for_last_packet
#
# Wait until the last packet is scheduled to be sent
#
###############################################################

sub wait_for_last_packet {
	my $start = shift;
	my $last_pkt = 0;
	my $delta = 0;

	# Work out when the last packet is to be sent
	for (my $i = 0; $i < scalar(@pcap_filename); $i++) {
		if ($pcap_filename[$i] ne '') {
			my $queue_last = ($last_sec[$i] * 1.0) + ($last_nsec[$i] * 10**-9);
			$queue_last *= ($iterations[$i] * 1.0);
			$queue_last += ($final_pkt_delay[$i] * 10**-9) * ($iterations[$i] - 1.0);
			if ($queue_last > $last_pkt) {
				$last_pkt = $queue_last;
			}
		}
	}


	# Disable output buffering on stdout to enable status updates
	autoflush STDOUT 1;

	# Wait the requesite number of seconds
	printf "Last packet scheduled for transmission at %1.3f seconds\n", $last_pkt;
	while ($delta <= $last_pkt) {
		print "\r$delta seconds elapsed...";
		sleep 1;
		$delta = time() - $start;
	}
	autoflush STDOUT 0;
	print "\n\n";
}


###############################################################
# Name: wait_for_ctrl_c
#
# Wait until the user presses Ctrl-C
#
###############################################################

sub wait_for_ctrl_c {
	my $start = shift;
	my $delta = 0;

	# Disable output buffering on stdout to enable status updates
	autoflush STDOUT 1;

	# Wait the requesite number of seconds
	if ($send_enable) {
		print "All packets should have been sent.\n";
	}
	else {
		print "Capturing packets (no packets to send).\n";
	}
	print "Press Ctrl-C to stop capture...\n\n";
	while (1) {
		$delta = time() - $start;
		print "\r$delta seconds elapsed...";
		sleep 1;
	}
	autoflush STDOUT 0;
	print "\n\n";
}


###############################################################
# Name: display_capture_metrics
#
# Display the metrics capture by the card
#
###############################################################

sub display_capture_metrics {
	my $offset = PKT_GEN_CTRL_1_PKT_COUNT_REG() - PKT_GEN_CTRL_0_PKT_COUNT_REG();

	print "Receive statistics:\n";
	print "===================\n\n";

	for (my $i = 0; $i < scalar(@capture_filename); $i++) {
		my $pkt_cnt = nf_regread('nf2c0', PKT_GEN_CTRL_0_PKT_COUNT_REG() + $i * $offset);
		my $byte_cnt_hi = nf_regread('nf2c0', PKT_GEN_CTRL_0_BYTE_COUNT_HI_REG() + $i * $offset);
		my $byte_cnt_lo = nf_regread('nf2c0', PKT_GEN_CTRL_0_BYTE_COUNT_LO_REG() + $i * $offset);
		my $time_first_hi = nf_regread('nf2c0', PKT_GEN_CTRL_0_TIME_FIRST_HI_REG() + $i * $offset);
		my $time_first_lo = nf_regread('nf2c0', PKT_GEN_CTRL_0_TIME_FIRST_LO_REG() + $i * $offset);
		my $time_last_hi = nf_regread('nf2c0', PKT_GEN_CTRL_0_TIME_LAST_HI_REG() + $i * $offset);
		my $time_last_lo = nf_regread('nf2c0', PKT_GEN_CTRL_0_TIME_LAST_LO_REG() + $i * $offset);

		my $byte_cnt = ($byte_cnt_hi) * 2 ** 32 + ($byte_cnt_lo);
		my $delta_hi = $time_last_hi - $time_first_hi;
		my $delta_lo = $time_last_lo - $time_first_lo;

		if ($time_first_lo > $time_last_lo) {
			$delta_hi--;
			$delta_lo += 2**32;
		}

		my $sec = `echo "($delta_lo+($delta_hi*2^32))/10^9" | bc`;
		my $nsec = `echo "(($delta_lo+($delta_hi*2^32))%10^9)" | bc`;

		my $time = $sec + ($nsec / 10**9);
		my $rate_data_only = 0;
		my $rate_all = 0;
		if ($time != 0) {
			$rate_data_only = $byte_cnt / $time / 1000 * 8;
			$rate_all = ($byte_cnt + 20 * $pkt_cnt) / $time / 1000 * 8;
		}


		printf "%s:\n", queue_name($i + 8);
		printf "\tPackets: %u\n", $pkt_cnt;
		if ($pkt_cnt > 0) {
			printf "\tBytes: %1.0f\n", $byte_cnt;
			printf "\tTime: %1d.%09d s\n", $sec, $nsec;
			printf "\tRate: %s (packet data only)\n", rate_str($rate_data_only);
			printf "\tRate: %s (including preamble/inter-packet gap)\n", rate_str($rate_all);
		}
	}
	print "\n\n";
}


###############################################################
# Name: display_xmit_metrics
#
# Display the metrics of sent packets maintained by the card
#
###############################################################

sub display_xmit_metrics {
	print "Transmit statistics:\n";
	print "====================\n\n";

	for (my $i = 0; $i < scalar(@pcap_filename); $i++) {
		if ($pcap_filename[$i] ne '') {
			my $pkt_cnt = nf_regread('nf2c0', OQ_QUEUE_0_NUM_PKTS_REMOVED_REG() + ($i + 8) * $queue_addr_offset);
			my $iter_cnt = nf_regread('nf2c0', OQ_QUEUE_0_CURR_ITER_REG() + ($i + 8) * $queue_addr_offset);


			printf "%s:\n", queue_name($i + 8);
			printf "\tPackets: %u\n", $pkt_cnt;
			printf "\tCompleted iterations: %1.0f\n", $iter_cnt;
		}
	}
	print "\n\n";
}


###############################################################
# Name: get_queue_size
#
# Get the size of a queue
#
# Arguements: queue		Queue number
#
###############################################################

sub get_queue_size {

	my $queue = $_[0];
	my $queue_size = max($queue_words[$queue], MIN_TX_QUEUE_SIZE);

	return $queue_size;
}


###############################################################
# Name: load_queues
#
# Loads the packets into NetFPGA RAM from the hosts memory
#
# Arguments: queue              Queue to load the Pcap into
#
###############################################################

sub load_queues {

	my $queue = $_[0];

	my $sram_addr = SRAM_BASE_ADDR() + $queue_base_addr[$queue] * 16;

	for (my $i = 0; $i < scalar(@{$queue_data[$queue]}); $i += 3) {

		nf_regwrite ('nf2c0',
                     $sram_addr + 0x4,
		     ${$queue_data[$queue]}[$i]);
		nf_regwrite ('nf2c0',
                     $sram_addr + 0x8,
		     ${$queue_data[$queue]}[$i + 1]);
		nf_regwrite ('nf2c0',
                     $sram_addr + 0xc,
		     ${$queue_data[$queue]}[$i + 2]);

		$sram_addr += 16;

	}

	return 0;
}

###############################################################
# Name: unpack_packet_and_pad
#
# Unpacks a packet, pads the packet with zeros up to the
# packet length (in case caplen < len) and then pads to a
# whole number of words)
#
# Arguments: packet     String representation of packet
#            len        Total packet length
#            caplen     Captured packet length
#
# Return: array of 32-bit words
#
###############################################################
sub unpack_packet_and_pad {

	my $packet = $_[0];
	my $len = $_[1];
	my $caplen = $_[2];

	# Unpack the packet as a series of 8-bit unsigned ints and pad
	my @pkt = unpack("C*", $packet);
	push @pkt, ((0) x ($len - $caplen)) if ($len != $caplen);
	push @pkt, ((0) x (8 - $len % 8)) if ($len % 8 != 0);

	if ($pad && (scalar(@pkt) > 64)) {
		@pkt = @pkt[0 .. 63];
	}

	# Convert 8-bit unsigneds into 32-bit unsigneds by merging 4
	@pkt = unpack("N*", pack("C*", @pkt));

	return @pkt;
}

###############################################################
# Name: check_bitfile
#
# Verifies that the correct bitfile is downloaded to the Virtex
#
###############################################################
sub check_bitfile {

	if (!checkVirtexBitfile('nf2c0', DEVICE_PROJ_DIR(),
			DEVICE_MAJOR(), DEVICE_MINOR(), undef,
			DEVICE_MAJOR(), DEVICE_MINOR(), undef)) {
		print STDERR getVirtexBitfileErr() . "\n";
		exit 1;
	}
}

###############################################################
# Name: bint
#
# Construct a Math::BigInt
#
###############################################################
sub bint {
	Math::BigInt->new(shift);
}
