#!/usr/bin/perl

use strict;
use NF::RegressLib;
use NF::PacketLib;

use Net::Pcap;

use reg_defines_packet_generator;

my @interfaces = ("nf2c0", "nf2c1");
nftest_init(\@ARGV,\@interfaces,);

my $pcap0 = "../../sw/http.pcap";
my $cap0 = "temp_cap0.pcap";
my $pcap0_num_pkts = 43;
my $pcap1 = "../../sw/udp_lite_full_coverage_0.pcap";
my $cap1 = "temp_cap1.pcap";
my $pcap1_num_pkts = 1;
my $total_errors = 0;
my $temp_val = 0;

# These variables represent whether each interface is connected.
# This simplifies testing on machines with a single available
#  ethernet port.
my $nf2c0 = 1;
my $nf2c1 = 1;

nftest_fpga_reset('nf2c0');

my $pid = fork();
if ($pid == 0) {
	my $args;
	$args .= " -q0 $pcap0 -c0 $cap0" if ($nf2c0);
	$args .= " -q1 $pcap1 -c1 $cap1" if ($nf2c1);
	system("../../sw/packet_generator.pl $args 1>/dev/null &");
	exit (0);
}
else {

`sleep 5`;

`tcpreplay -i eth1 $pcap0` if ($nf2c0);
`tcpreplay -i eth2 $pcap1` if ($nf2c1);

`killall -s SIGINT packet_generator.pl`;

my $count = 0;

sub capture_done {
	return (`-f $cap0` && `-f $cap1`) if ($nf2c0 && $nf2c1);
	return (`-f $cap0`) if ($nf2c0);
	return (`-f $cap1`) if ($nf2c1);
}

while ( !capture_done ) {
	`sleep 1`;
	$count++;
	if ($count == 10)
	{
		last;
	}
}

$total_errors = pcap_compare($cap0, $pcap0) if ($nf2c0);
$total_errors += pcap_compare($cap1, $pcap1) if ($nf2c1);

print "Checking registers\n";

if ($nf2c0) {
	$temp_val = nftest_regread_expect('nf2c0', MAC_GRP_0_RX_QUEUE_NUM_PKTS_DEQUEUED_REG(), $pcap0_num_pkts);

	if ($temp_val != $pcap0_num_pkts)
	{
		print "ERROR: expected $pcap0_num_pkts to be sent. Only $temp_val were sent.\n";
		$total_errors++;
	}
}

if ($nf2c1) {
	$temp_val = nftest_regread_expect('nf2c0', MAC_GRP_1_RX_QUEUE_NUM_PKTS_DEQUEUED_REG(), $pcap1_num_pkts);

	if ($temp_val != $pcap1_num_pkts)
	{
		print "ERROR: expected $pcap1_num_pkts to be sent. Only $temp_val were sent.\n";
		$total_errors++;
	}
}

sleep 2;
my $unmatched_hoh = nftest_finish();
$total_errors += nftest_print_errors($unmatched_hoh);

#`rm $cap0 $cap1`;

if ($total_errors==0) {
  print "SUCCESS!\n";
	exit 0;
}
else {
  print "FAIL: $total_errors errors\n";
	exit 1;
}

return 1;

}

###############################################################

###############################################################
# Name: pcap_compare
#
# compare two pcap files and return 0 if same 1 else.
#
# Arguments: cmp0  first pcap file name to compare
#            cmp1  second pcap file name to compare
#
###############################################################

sub pcap_compare {

	my $cmp0_name = $_[0];
	my $cmp1_name = $_[1];

 	my $err;
	my %hdr0;
	my %hdr1;
	my $packet0;
	my $packet1;

	my $cmp0 = Net::Pcap::open_offline($cmp0_name, \$err)
		or die "Can't read '$cmp0_name': $err\n";

	my $cmp1 = Net::Pcap::open_offline($cmp1_name, \$err)
		or die "Can't read '$cmp1_name': $err\n";

	$packet0 = Net::Pcap::next($cmp0, \%hdr0);
	$packet1 = Net::Pcap::next($cmp1, \%hdr1);
  print "Comparing captured pcap file to original\n";

	my $index = 1;

	while ( defined(%hdr0) || defined(%hdr1) ) {
		#print $index . " ";
		# Verify that both files have a packet
		if ( !defined(%hdr0) || !defined(%hdr1) ) {
			print "Capture error the files are not the same: index $index\n";
			return 1;
		}

		if (length($packet0) < 60) {
			$packet0 .= "\0" x (60 - length($packet0));
		}

		if (length($packet1) < 60) {
			$packet1 .= "\0" x (60 - length($packet1));
		}

		# Verify that the packets are identical
		if ( $packet0 ne $packet1 ) {
			print "Capture error the files are not the same: index $index\n";
			return 1;
		}

		$index++;
		undef %hdr0;
		undef %hdr1;
		$packet0 = Net::Pcap::next($cmp0, \%hdr0);
		$packet1 = Net::Pcap::next($cmp1, \%hdr1);

	}

	return 0;
}
