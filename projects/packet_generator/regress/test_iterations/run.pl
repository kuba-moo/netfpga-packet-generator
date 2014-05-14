#!/usr/bin/perl

use strict;
use NF::RegressLib;
use NF::PacketLib;

use reg_defines_packet_generator;

my @interfaces = ("nf2c0", "nf2c1");
nftest_init(\@ARGV,\@interfaces,);

my $pcap0 = "../../sw/http.pcap";
my $pcap0_num_pkts = 43;
my $pcap0_num_iterations = 10;
my $pcap1 = "../../sw/udp_lite_full_coverage_0.pcap";
my $pcap1_num_pkts = 1;
my $pcap1_num_iterations = 100;
my $total_errors = 0;
my $temp_val = 0;

nftest_fpga_reset('nf2c0');

my $output = `../../sw/packet_generator.pl -q0 $pcap0 -q1 $pcap1 -i0 $pcap0_num_iterations -i1 $pcap1_num_iterations -d0 0 -d1 0`;

#print $output;

my $temp = $pcap0_num_pkts * $pcap0_num_iterations;

$temp_val = nftest_regread_expect('nf2c0', MAC_GRP_0_TX_QUEUE_NUM_PKTS_SENT_REG(), $temp);

if ($temp_val != $temp)
{
	print "ERROR: expected $temp to be sent. Only $temp_val were sent.\n";
	$total_errors++;
}

my $temp = $pcap1_num_pkts * $pcap1_num_iterations;
$temp_val = nftest_regread_expect('nf2c0', MAC_GRP_1_TX_QUEUE_NUM_PKTS_SENT_REG(), $temp);

if ($temp_val != $temp)
{
	print "ERROR: expected $temp to be sent. Only $temp_val were sent.\n";
	$total_errors++;
}

sleep 2;
my $unmatched_hoh = nftest_finish();
$total_errors += nftest_print_errors($unmatched_hoh);

if ($total_errors==0) {
  print "SUCCESS!\n";
	exit 0;
}
else {
  print "FAIL: $total_errors errors\n";
	exit 1;
}

