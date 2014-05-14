#
# $Id: Makefile 6042 2010-04-01 05:59:23Z grg $
#

CFLAGS = -g -I ../../../lib/C/common
CC = gcc
LDFLAGS = -lncurses

all : regdump

regdump : regdump.o $(NF_ROOT)/lib/C/common/nf2util.o $(NF_ROOT)/lib/C/common/reg_defines.h

clean :
	rm -f regdump *.o

install:

.PHONY: all clean install
