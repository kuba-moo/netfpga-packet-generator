#!/usr/local/bin/perl -w
# make_pkts.pl
#

use NF::PacketGen;
use NF::PacketLib;
use SimLib;
use POSIX;

use reg_defines_packet_generator;

$delay = '@4us';
$batch = 0;
nf_set_environment( { PORT_MODE => 'PHYSICAL', MAX_PORTS => 4 } );

# use strict AFTER the $delay, $batch and %reg are declared
use strict;
use vars qw($delay $batch %reg);

my $ROUTER_PORT_1_MAC = '00:ca:fe:00:00:01';
my $ROUTER_PORT_2_MAC = '00:ca:fe:00:00:02';
my $ROUTER_PORT_3_MAC = '00:ca:fe:00:00:03';
my $ROUTER_PORT_4_MAC = '00:ca:fe:00:00:04';

my $ROUTER_PORT_1_IP = '192.168.1.1';
my $ROUTER_PORT_2_IP = '192.168.2.1';
my $ROUTER_PORT_3_IP = '192.168.3.1';
my $ROUTER_PORT_4_IP = '192.168.4.1';

my $next_hop_1_DA = '00:fe:ed:01:d0:65';
my $next_hop_2_DA = '00:fe:ed:02:d0:65';

# Prepare the DMA and enable interrupts
prepare_DMA('@3.9us');
enable_interrupts(0);

#
###############################
#
# Send in four packet before enabling the packet generator

my $delay = '@4us';
my $length = 64;
my $DA;
my $SA;
my $dst_ip = '171.64.2.7';
my $src_ip;
my $TTL = 64;
my $pkt;

$DA = $ROUTER_PORT_1_MAC;
$SA = '01:55:55:55:55:55';
$src_ip = '171.64.1.1';
$pkt = make_IP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(1, $length, $delay, $batch,  $pkt);
nf_expected_dma_data(1, $length, $pkt);

$DA = $ROUTER_PORT_2_MAC;
$SA = '02:55:55:55:55:55';
$src_ip = '171.64.2.1';
$pkt = make_IP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(2, $length, $delay, $batch,  $pkt);
nf_expected_dma_data(2, $length, $pkt);

$DA = $ROUTER_PORT_3_MAC;
$SA = '03:55:55:55:55:55';
$src_ip = '171.64.3.1';
$pkt = make_IP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(3, $length, $delay, $batch,  $pkt);
nf_expected_dma_data(3, $length, $pkt);

$DA = $ROUTER_PORT_4_MAC;
$SA = '04:55:55:55:55:55';
$src_ip = '171.64.4.1';
$pkt = make_IP_pkt($length, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(4, $length, $delay, $batch,  $pkt);
nf_expected_dma_data(4, $length, $pkt);

#
###############################
#
# Enable the packet generator and send in a packet
$delay = '@22us';
nf_PCI_write32($delay, $batch, &PKT_GEN_CTRL_ENABLE_REG(), 0x0000000f);

$delay = '@25us';
$dst_ip = '171.64.2.8';

my @hdr = split(' ',
	  (sprintf("%02x %02x %02x %02x %02x %02x",
		PKT_CAP_DA_HI() >> 8,
	   	PKT_CAP_DA_HI() & 0xff,
	   	(PKT_CAP_DA_LO() >> 24) & 0xff,
	   	(PKT_CAP_DA_LO() >> 16) & 0xff,
	   	(PKT_CAP_DA_LO() >> 8) & 0xff,
	   	(PKT_CAP_DA_LO() >> 0) & 0xff) . " " .
           sprintf("%02x %02x %02x %02x %02x %02x",
		PKT_CAP_SA_HI() >> 8,
	   	PKT_CAP_SA_HI() & 0xff,
	   	(PKT_CAP_SA_LO() >> 24) & 0xff,
	   	(PKT_CAP_SA_LO() >> 16) & 0xff,
	   	(PKT_CAP_SA_LO() >> 8) & 0xff,
	   	(PKT_CAP_SA_LO() >> 0) & 0xff) . " " .
           sprintf("%02x %02x",
		PKT_CAP_ETHERTYPE() >> 8,
		PKT_CAP_ETHERTYPE() & 0xff) . " 00 00"));

my $length1 = 64;
$DA = $ROUTER_PORT_1_MAC;
$SA = '01:55:55:55:55:55';
$src_ip = '171.64.1.1';
$pkt = make_IP_pkt($length1, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(1, $length1, $delay, $batch,  $pkt);
nf_expected_dma_data(1, $length1 + 24, @hdr, ("XX") x 8, $pkt);

my $length2 = 66;
$DA = $ROUTER_PORT_1_MAC;
$SA = '02:55:55:55:55:55';
$src_ip = '171.64.2.1';
$pkt = make_IP_pkt($length2, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(2, $length2, $delay, $batch,  $pkt);
nf_expected_dma_data(2, $length2 + 24, @hdr, ("XX") x 8, $pkt);

my $length3 = 68;
$DA = $ROUTER_PORT_1_MAC;
$SA = '03:55:55:55:55:55';
$src_ip = '171.64.3.1';
$pkt = make_IP_pkt($length3, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(3, $length3, $delay, $batch,  $pkt);
nf_expected_dma_data(3, $length3 + 24, @hdr, ("XX") x 8, $pkt);

my $length4 = 69;
$DA = $ROUTER_PORT_1_MAC;
$SA = '04:55:55:55:55:55';
$src_ip = '171.64.4.1';
$pkt = make_IP_pkt($length4, $DA, $SA, $TTL, $dst_ip, $src_ip);
nf_packet_in(4, $length4, $delay, $batch,  $pkt);
nf_expected_dma_data(4, $length4 + 24, @hdr, ("XX") x 8, $pkt);


#
###############################
#
# Read the counter registers to ensure that my packets have been counted
# Also check to make sure that the upper bits of the timer regs are 0
$delay = '@45us';
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_0_PKT_COUNT_REG(), 0x00000001);
$delay = 0;
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_0_BYTE_COUNT_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_0_BYTE_COUNT_LO_REG(), $length1 + 4);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_0_TIME_FIRST_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_0_TIME_LAST_HI_REG(), 0x00000000);

nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_1_PKT_COUNT_REG(), 0x00000001);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_1_BYTE_COUNT_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_1_BYTE_COUNT_LO_REG(), $length2 + 4);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_1_TIME_FIRST_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_1_TIME_LAST_HI_REG(), 0x00000000);

nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_2_PKT_COUNT_REG(), 0x00000001);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_2_BYTE_COUNT_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_2_BYTE_COUNT_LO_REG(), $length3 + 4);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_2_TIME_FIRST_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_2_TIME_LAST_HI_REG(), 0x00000000);

nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_3_PKT_COUNT_REG(), 0x00000001);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_3_BYTE_COUNT_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_3_BYTE_COUNT_LO_REG(), $length4 + 4);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_3_TIME_FIRST_HI_REG(), 0x00000000);
nf_PCI_read32($delay, $batch, &PKT_GEN_CTRL_3_TIME_LAST_HI_REG(), 0x00000000);


# *********** Finishing Up - need this in all scripts ! ****************************
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');
