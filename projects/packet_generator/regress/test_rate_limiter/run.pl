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
my $pcap1 = "../../sw/udp_lite_full_coverage_0.pcap";
my $cap1 = "temp_cap1.pcap";
my $total_errors = 0;
my $temp_val = 0;
my @orig_pcap_data;
my @pcap_data;
my $rate = 1000; #Kbps

nftest_fpga_reset('nf2c0');

my $pid = fork();
if ($pid == 0) {
	system("/usr/sbin/tcpdump -i eth1 -s 2000 -w $cap0 &");
	exit (0);
}
else {

`sleep 2`;

`../../sw/packet_generator.pl -q0 $pcap0 -q1 $pcap1 -d0 0 -r0 $rate 1>/dev/null`;

print "finished transmitting the data\n";

`killall -s SIGINT tcpdump`;

my $count = 0;
while ( !(`-f $cap0`) ) {
	`sleep 1`;
	$count++;
	if ($count == 10)
	{
		last;
	}
}

@pcap_data = pcap_calc_rates($cap0);

my $cap_rate = $pcap_data[2] / $pcap_data[0] * 8 / 1000;

print "Rate limited to: $rate Kbps\n";
print "Captured file reports $cap_rate Kbps\n";

if ( abs($cap_rate - $rate) < 10) {
	$total_errors = 0;
}
else {
	$total_errors++;
}

my $unmatched_hoh = nftest_finish();
$total_errors += nftest_print_errors($unmatched_hoh);

`rm $cap0`;

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
# Name: pcap_calc_rates
#
# Returns the total time from first packet to the last packet, and the
#   total number of bytes in the pcap file
#
# Arguments: cmp  pcap used to calculate the time and number of bytes
#
###############################################################

sub pcap_calc_rates {

	my $cmp_name = $_[0];

 	my $err;
	my %hdr;
	my $packet;
	my $sec;
	my $usec;
	my $beginning_sec;
	my $beginning_usec;
	my $bytes;

	my $cmp = Net::Pcap::open_offline($cmp_name, \$err)
		or die "Can't read '$cmp_name': $err\n";

	$packet = Net::Pcap::next($cmp, \%hdr);

	$beginning_sec = $hdr{"tv_sec"};
	$beginning_usec = $hdr{"tv_usec"} + ($beginning_sec * 1000000);

	my $index = 1;

	while ( %hdr ) {
		#print "$sec $usec\n";

    $sec = $hdr{"tv_sec"};
    $usec = $hdr{"tv_usec"} + ($sec * 1000000);
    $bytes += $hdr{"len"};

		$index++;
		undef %hdr;
		$packet = Net::Pcap::next($cmp, \%hdr);

	}

	$sec -= $beginning_sec;
	my $temp_usec = $usec - $beginning_usec;
	$sec = $temp_usec / 1000000;

	#print "$sec $temp_usec $bytes\n";

	return ($sec, $usec, $bytes);
}
