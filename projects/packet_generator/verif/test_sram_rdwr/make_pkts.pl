#!/usr/local/bin/perl -w
# make_pkts.pl
#

use NF::PacketGen;
use NF::PacketLib;
use SimLib;

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

printf "BASE_ADDR: %08x\n", SRAM_BASE_ADDR();

# Write some values into SRAM
for (my $i = 0; $i < 8; $i++) {
	nf_PCI_write32($delay, $batch, SRAM_BASE_ADDR() + $i * 4,
		       0x11111111 * ($i + 1));
}

# Read the values back again
for (my $i = 0; $i < 8; $i++) {
	my $val = 0x11111111 * ($i + 1);
	if ($i % 4 == 0) {
		$val = 0;
	}
	elsif ($i %4 == 1) {
		$val &= 0x000000ff;
	}

	nf_PCI_read32($delay, $batch, SRAM_BASE_ADDR() + $i * 4, $val);
}


# *********** Finishing Up - need this in all scripts ! ****************************
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');
