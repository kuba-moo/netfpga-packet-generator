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

# Construct a packet and place in SRAM queue 8
my $lenNonPad = 60;
my $lenPad = 100;
my @pktIn = (1 .. $lenNonPad);
my @pktOut = @pktIn;
push @pktOut, ((0) x ($lenPad - $lenNonPad));

my $wordLenNonPad = POSIX::ceil($lenNonPad / 8);
my $wordLenPad = POSIX::ceil($lenPad / 8);
my $srcPort = 0;
my $dstPort = 0x100;

my $qOffset = 8 * $defaultQSize * 16;
my $addr = SRAM_BASE_ADDR() + $qOffset;

# Write the header to SRAM
nf_PCI_write32($delay, $batch, $addr + 0x4, 0x000000ff);
nf_PCI_write32($delay, $batch, $addr + 0x8, $wordLenNonPad | ($dstPort << 16));
nf_PCI_write32($delay, $batch, $addr + 0xc, $lenNonPad | ($srcPort << 16));
$addr += 0x10;

# Write the header to SRAM
# Pad
nf_PCI_write32($delay, $batch, $addr + 0x4, PAD_CTRL_VAL());
nf_PCI_write32($delay, $batch, $addr + 0x8, $wordLenPad | ($dstPort << 16));
nf_PCI_write32($delay, $batch, $addr + 0xc, $lenPad | ($srcPort << 16));
$addr += 0x10;

# Write the actual data
my @paddedPkt = @pktIn;
push @paddedPkt, ((0) x (8 - $lenNonPad % 8)) if ($lenNonPad % 8 != 0);
for (my $i = 0; $i < scalar(@paddedPkt); $i += 8) {
	my $ctrl = 0x0;
	if ($i / 8 == $wordLenNonPad - 1) {
		$ctrl = 0x100 >> ($lenNonPad % 8);
		$ctrl = $ctrl & 0xff | ($ctrl == 0x100);
	}
	my $word1 = ($paddedPkt[$i + 0] << 24) | ($paddedPkt[$i + 1] << 16) |
	            ($paddedPkt[$i + 2] <<  8) | ($paddedPkt[$i + 3] <<  0);
	my $word2 = ($paddedPkt[$i + 4] << 24) | ($paddedPkt[$i + 5] << 16) |
	            ($paddedPkt[$i + 6] <<  8) | ($paddedPkt[$i + 7] <<  0);

	nf_PCI_write32($delay, $batch, $addr + 0x4, $ctrl);
	nf_PCI_write32($delay, $batch, $addr + 0x8, $word1);
	nf_PCI_write32($delay, $batch, $addr + 0xc, $word2);

	$addr += 0x10;
}

nf_PCI_write32($delay, $batch,
	OQ_QUEUE_0_ADDR_HI_REG() + 8 * $qAddrOffset,
	scalar(@paddedPkt) / 8 + 1 + 8 * $defaultQSize);

# Expect the packet
nf_expected_packet(1, $lenPad, join(' ', map {sprintf("%02x", $_)} @pktOut));


# Construct a packet and place in SRAM queue 9
$lenNonPad = 40;
$lenPad = 256;
@pktIn = (1 .. $lenNonPad);
@pktOut = @pktIn;
push @pktOut, ((0) x ($lenPad - $lenNonPad));

$wordLenNonPad = POSIX::ceil($lenNonPad / 8);
$wordLenPad = POSIX::ceil($lenPad / 8);
$srcPort = 0;
$dstPort = 0x200;

$qOffset = 9 * $defaultQSize * 16;
$addr = SRAM_BASE_ADDR() + $qOffset;

# Write the header to SRAM
nf_PCI_write32($delay, $batch, $addr + 0x4, 0x000000ff);
nf_PCI_write32($delay, $batch, $addr + 0x8, $wordLenNonPad | ($dstPort << 16));
nf_PCI_write32($delay, $batch, $addr + 0xc, $lenNonPad | ($srcPort << 16));
$addr += 0x10;

# Write the header to SRAM
# Pad
nf_PCI_write32($delay, $batch, $addr + 0x4, PAD_CTRL_VAL());
nf_PCI_write32($delay, $batch, $addr + 0x8, $wordLenPad | ($dstPort << 16));
nf_PCI_write32($delay, $batch, $addr + 0xc, $lenPad | ($srcPort << 16));
$addr += 0x10;

# Write the actual data
my @paddedPkt = @pktIn;
push @paddedPkt, ((0) x (8 - $lenNonPad % 8)) if ($lenNonPad % 8 != 0);
for (my $i = 0; $i < scalar(@paddedPkt); $i += 8) {
	my $ctrl = 0x0;
	if ($i / 8 == $wordLenNonPad - 1) {
		$ctrl = 0x100 >> ($lenNonPad % 8);
		$ctrl = $ctrl & 0xff | ($ctrl == 0x100);
	}
	my $word1 = ($paddedPkt[$i + 0] << 24) | ($paddedPkt[$i + 1] << 16) |
	            ($paddedPkt[$i + 2] <<  8) | ($paddedPkt[$i + 3] <<  0);
	my $word2 = ($paddedPkt[$i + 4] << 24) | ($paddedPkt[$i + 5] << 16) |
	            ($paddedPkt[$i + 6] <<  8) | ($paddedPkt[$i + 7] <<  0);

	nf_PCI_write32($delay, $batch, $addr + 0x4, $ctrl);
	nf_PCI_write32($delay, $batch, $addr + 0x8, $word1);
	nf_PCI_write32($delay, $batch, $addr + 0xc, $word2);

	$addr += 0x10;
}

nf_PCI_write32($delay, $batch,
	OQ_QUEUE_0_ADDR_HI_REG() + 9 * $qAddrOffset,
	scalar(@paddedPkt) / 8 + 1 + 8 * $defaultQSize);

# Expect the packet
nf_expected_packet(2, $lenPad, join(' ', map {sprintf("%02x", $_)} @pktOut));



# Attempt to send the packet
nf_PCI_write32($delay, $batch, OQ_QUEUE_0_CTRL_REG() + 8 * $qAddrOffset, 0x03);
nf_PCI_write32($delay, $batch, OQ_QUEUE_0_MAX_ITER_REG() + 8 * $qAddrOffset, 1);
nf_PCI_write32($delay, $batch, OQ_QUEUE_0_CTRL_REG() + 9 * $qAddrOffset, 0x03);
nf_PCI_write32($delay, $batch, OQ_QUEUE_0_MAX_ITER_REG() + 9 * $qAddrOffset, 1);
nf_PCI_write32($delay, $batch, &PKT_GEN_CTRL_ENABLE_REG(), 0x0000000f);


# *********** Finishing Up - need this in all scripts ! ****************************
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');
