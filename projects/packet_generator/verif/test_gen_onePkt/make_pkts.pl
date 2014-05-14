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

# Prepare the DMA and enable interrupts
prepare_DMA('@3.9us');
enable_interrupts(0);

my $defaultQSize = floor(0x80000 / 12);
my $qAddrOffset = OQ_QUEUE_GROUP_INST_OFFSET();

# Construct a packet and place in SRAM
my $len = 60;
my @pkt = (1 .. 60);

my $wordLen = POSIX::ceil($len / 8);
my $srcPort = 0;
my $dstPort = 0x100;

# Write the header to SRAM
my $qOffset = 8 * $defaultQSize * 16;
nf_PCI_write32($delay, $batch, SRAM_BASE_ADDR() + $qOffset + 0x4, 0x000000ff);
nf_PCI_write32($delay, $batch, SRAM_BASE_ADDR() + $qOffset + 0x8, $wordLen | ($dstPort << 16));
nf_PCI_write32($delay, $batch, SRAM_BASE_ADDR() + $qOffset + 0xc, $len | ($srcPort << 16));

# Write the actual data
my @paddedPkt = @pkt;
push @paddedPkt, ((0) x (8 - $len % 8)) if ($len % 8 != 0);
for (my $i = 0; $i < scalar(@paddedPkt); $i += 8) {
	my $ctrl = 0x0;
	if ($i / 8 == $wordLen - 1) {
		$ctrl = 0x100 >> ($len % 8);
		$ctrl = $ctrl & 0xff | ($ctrl == 0x100);
	}
	my $word1 = ($paddedPkt[$i + 0] << 24) | ($paddedPkt[$i + 1] << 16) |
	            ($paddedPkt[$i + 2] <<  8) | ($paddedPkt[$i + 3] <<  0);
	my $word2 = ($paddedPkt[$i + 4] << 24) | ($paddedPkt[$i + 5] << 16) |
	            ($paddedPkt[$i + 6] <<  8) | ($paddedPkt[$i + 7] <<  0);

	my $addr = ($i / 8) * 0x10 + 0x10 + SRAM_BASE_ADDR()+ $qOffset;
	nf_PCI_write32($delay, $batch, $addr + 0x4, $ctrl);
	nf_PCI_write32($delay, $batch, $addr + 0x8, $word1);
	nf_PCI_write32($delay, $batch, $addr + 0xc, $word2);
}


# Attempt to send the packet
nf_PCI_write32($delay, $batch,
	OQ_QUEUE_0_ADDR_HI_REG() + 8 * $qAddrOffset,
	scalar(@paddedPkt) / 8 + 8 * $defaultQSize);
nf_PCI_write32($delay, $batch,
	OQ_QUEUE_0_CTRL_REG() + 8 * $qAddrOffset,
	0x03);
nf_PCI_write32($delay, $batch, OQ_QUEUE_0_MAX_ITER_REG() + 8 * $qAddrOffset, 1);
nf_PCI_write32($delay, $batch, PKT_GEN_CTRL_ENABLE_REG(), 0x0000000f);


# Expect the packet
nf_expected_packet(1, $len, join(' ', map {sprintf("%02x", $_)} @pkt));


# *********** Finishing Up - need this in all scripts ! ****************************
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');
