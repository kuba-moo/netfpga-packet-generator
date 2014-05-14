#!/usr/bin/perl -W

`/usr/local/sbin/cpci_reprogram.pl`;

`sleep 2`;

system("/usr/local/bin/nf_download  /usr/local/netfpga/bitfiles/packet_generator.bit") == 0 or die "Download of packet generator bitfile failed\n";
