/* ****************************************************************************
 * $Id: regdump.c 5851 2009-11-13 00:17:17Z grg $
 *
 * Module: regdump.c
 * Project: NetFPGA 2.1 reference
 * Description: Test program to dump the switch registers
 *
 * Change history:
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>

#include <net/if.h>

#include <time.h>

#include "../lib/C/reg_defines_packet_generator.h"
#include "nf2util.h"

#define PATHLEN		80

#define DEFAULT_IFACE	"nf2c0"

/* Global vars */
static struct nf2device nf2;
static int verbose = 0;
static int force_cnet = 0;

/* Function declarations */
void print (void);
void printMAC (unsigned, unsigned);
void printIP (unsigned);

int main(int argc, char *argv[])
{
	unsigned val;

	nf2.device_name = DEFAULT_IFACE;

	if (check_iface(&nf2))
	{
		exit(1);
	}
	if (openDescriptor(&nf2))
	{
		exit(1);
	}

	print();

	closeDescriptor(&nf2);

	return 0;
}

void print(void) {
	unsigned val, val2;
	int i;

	int qAddrOffset;
	int rateLimBase;
	int rateLimOffset;

	qAddrOffset = OQ_QUEUE_GROUP_INST_OFFSET;
	rateLimOffset = RATE_LIMIT_OFFSET;
	rateLimBase = RATE_LIMIT_0_BASE_ADDR;

	//	readReg(&nf2, UNET_ID, &val);
	//	printf("Board ID: Version %i, Device %i\n", GET_VERSION(val), GET_DEVICE(val));
	readReg(&nf2, MAC_GRP_0_CONTROL_REG, &val);
	printf("MAC 0 Control: 0x%08x ", val);
	if(val&(1<<MAC_GRP_TX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("TX disabled, ");
	}
	else {
	  printf("TX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("RX disabled, ");
	}
	else {
	  printf("RX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RESET_MAC_BIT_NUM)) {
	  printf("reset on\n");
	}
	else {
	  printf("reset off\n");
	}
	printf("mac config 0x%02x\n", val>>MAC_GRP_MAC_DISABLE_TX_BIT_NUM);

	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_PKTS_STORED_REG, &val);
	printf("Num pkts enqueued to rx queue 0:      %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG, &val);
	printf("Num pkts dropped (rx queue 0 full): %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG, &val);
	printf("Num pkts dropped (bad fcs q 0):     %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of rx queue 0: %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of rx queue 0: %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_PKTS_DEQUEUED_REG, &val);
	printf("Num pkts dequeued from rx queue 0: %u\n", val);
	readReg(&nf2, MAC_GRP_0_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in rx queue 0: %u\n\n", val);

	readReg(&nf2, MAC_GRP_0_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in tx queue 0:             %u\n", val);
	readReg(&nf2, MAC_GRP_0_TX_QUEUE_NUM_PKTS_SENT_REG, &val);
	printf("Num pkts dequeued from tx queue 0:           %u\n", val);
	readReg(&nf2, MAC_GRP_0_TX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of tx queue 0: %u\n", val);
	readReg(&nf2, MAC_GRP_0_TX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of tx queue 0: %u\n", val);
	readReg(&nf2, MAC_GRP_0_TX_QUEUE_NUM_PKTS_ENQUEUED_REG, &val);
	printf("Num pkts enqueued to tx queue 0: %u\n\n", val);

	readReg(&nf2, MAC_GRP_1_CONTROL_REG, &val);
	printf("MAC 1 Control: 0x%08x ", val);
	if(val&(1<<MAC_GRP_TX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("TX disabled, ");
	}
	else {
	  printf("TX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("RX disabled, ");
	}
	else {
	  printf("RX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RESET_MAC_BIT_NUM)) {
	  printf("reset on\n");
	}
	else {
	  printf("reset off\n");
	}
	printf("mac config 0x%02x\n", val>>MAC_GRP_MAC_DISABLE_TX_BIT_NUM);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_PKTS_STORED_REG, &val);
	printf("Num pkts enqueued to rx queue 1:      %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG, &val);
	printf("Num pkts dropped (rx queue 1 full): %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG, &val);
	printf("Num pkts dropped (bad fcs q 1):     %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of rx queue 1: %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of rx queue 1: %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_PKTS_DEQUEUED_REG, &val);
	printf("Num pkts dequeued from rx queue 1: %u\n", val);
	readReg(&nf2, MAC_GRP_1_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in rx queue 1: %u\n\n", val);

	readReg(&nf2, MAC_GRP_1_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in tx queue 1:             %u\n", val);
	readReg(&nf2, MAC_GRP_1_TX_QUEUE_NUM_PKTS_SENT_REG, &val);
	printf("Num pkts dequeued from tx queue 1:           %u\n", val);
	readReg(&nf2, MAC_GRP_1_TX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of tx queue 1: %u\n", val);
	readReg(&nf2, MAC_GRP_1_TX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of tx queue 1: %u\n", val);
        readReg(&nf2, MAC_GRP_1_TX_QUEUE_NUM_PKTS_ENQUEUED_REG, &val);
        printf("Num pkts enqueued to tx queue 1: %u\n\n", val);

	readReg(&nf2, MAC_GRP_2_CONTROL_REG, &val);
	printf("MAC 2 Control: 0x%08x ", val);
	if(val&(1<<MAC_GRP_TX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("TX disabled, ");
	}
	else {
	  printf("TX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("RX disabled, ");
	}
	else {
	  printf("RX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RESET_MAC_BIT_NUM)) {
	  printf("reset on\n");
	}
	else {
	  printf("reset off\n");
	}
	printf("mac config 0x%02x\n", val>>MAC_GRP_MAC_DISABLE_TX_BIT_NUM);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_PKTS_STORED_REG, &val);
	printf("Num pkts enqueued to rx queue 2:      %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG, &val);
	printf("Num pkts dropped (rx queue 2 full): %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG, &val);
	printf("Num pkts dropped (bad fcs q 2):     %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of rx queue 2: %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of rx queue 2: %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_PKTS_DEQUEUED_REG, &val);
	printf("Num pkts dequeued from rx queue 2: %u\n", val);
	readReg(&nf2, MAC_GRP_2_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in rx queue 2: %u\n\n", val);

	readReg(&nf2, MAC_GRP_2_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in tx queue 2:             %u\n", val);
	readReg(&nf2, MAC_GRP_2_TX_QUEUE_NUM_PKTS_SENT_REG, &val);
	printf("Num pkts dequeued from tx queue 2:           %u\n", val);
	readReg(&nf2, MAC_GRP_2_TX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of tx queue 2: %u\n", val);
	readReg(&nf2, MAC_GRP_2_TX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of tx queue 2: %u\n", val);
        readReg(&nf2, MAC_GRP_2_TX_QUEUE_NUM_PKTS_ENQUEUED_REG, &val);
        printf("Num pkts enqueued to tx queue 2: %u\n\n", val);

	readReg(&nf2, MAC_GRP_3_CONTROL_REG, &val);
	printf("MAC 3 Control: 0x%08x ", val);
	if(val&(1<<MAC_GRP_TX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("TX disabled, ");
	}
	else {
	  printf("TX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RX_QUEUE_DISABLE_BIT_NUM)) {
	  printf("RX disabled, ");
	}
	else {
	  printf("RX enabled,  ");
	}
	if(val&(1<<MAC_GRP_RESET_MAC_BIT_NUM)) {
	  printf("reset on\n");
	}
	else {
	  printf("reset off\n");
	}
        printf("mac config 0x%02x\n", val>>MAC_GRP_MAC_DISABLE_TX_BIT_NUM);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_PKTS_STORED_REG, &val);
	printf("Num pkts enqueued to rx queue 3:      %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_PKTS_DROPPED_FULL_REG, &val);
	printf("Num pkts dropped (rx queue 3 full): %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_PKTS_DROPPED_BAD_REG, &val);
	printf("Num pkts dropped (bad fcs q 3):     %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of rx queue 3: %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of rx queue 3: %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_PKTS_DEQUEUED_REG, &val);
	printf("Num pkts dequeued from rx queue 3: %u\n", val);
	readReg(&nf2, MAC_GRP_3_RX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in rx queue 3: %u\n\n", val);

	readReg(&nf2, MAC_GRP_3_TX_QUEUE_NUM_PKTS_IN_QUEUE_REG, &val);
	printf("Num pkts in tx queue 3:             %u\n", val);
	readReg(&nf2, MAC_GRP_3_TX_QUEUE_NUM_PKTS_SENT_REG, &val);
	printf("Num pkts dequeued from tx queue 3:           %u\n", val);
	readReg(&nf2, MAC_GRP_3_TX_QUEUE_NUM_WORDS_PUSHED_REG, &val);
	printf("Num words pushed out of tx queue 3: %u\n", val);
	readReg(&nf2, MAC_GRP_3_TX_QUEUE_NUM_BYTES_PUSHED_REG, &val);
	printf("Num bytes pushed out of tx queue 3: %u\n", val);
        readReg(&nf2, MAC_GRP_3_TX_QUEUE_NUM_PKTS_ENQUEUED_REG, &val);
        printf("Num pkts enqueued to tx queue 3: %u\n\n", val);

        // FIXME: If CPU queue counters are ever reimplemented
        /*
	readReg(&nf2, CPU_REG_Q_0_WR_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_0_WR_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_0_WR_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_0_WR_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_0_WR_NUM_WORDS_LEFT_REG, &val);
	printf("CPU_REG_Q_0_WR_NUM_WORDS_LEFT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_WR_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_0_WR_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_RD_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_0_RD_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_0_RD_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_0_RD_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_0_RD_NUM_WORDS_AVAIL_REG, &val);
	printf("CPU_REG_Q_0_RD_NUM_WORDS_AVAIL_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_RD_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_0_RD_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_RX_NUM_PKTS_RCVD_REG, &val);
	printf("CPU_REG_Q_0_RX_NUM_PKTS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_TX_NUM_PKTS_SENT_REG, &val);
	printf("CPU_REG_Q_0_TX_NUM_PKTS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_RX_NUM_WORDS_RCVD_REG, &val);
	printf("CPU_REG_Q_0_RX_NUM_WORDS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_TX_NUM_WORDS_SENT_REG, &val);
	printf("CPU_REG_Q_0_TX_NUM_WORDS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_RX_NUM_BYTES_RCVD_REG, &val);
	printf("CPU_REG_Q_0_RX_NUM_BYTES_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_0_TX_NUM_BYTES_SENT_REG, &val);
	printf("CPU_REG_Q_0_TX_NUM_BYTES_SENT_REG: %u\n\n", val);

	readReg(&nf2, CPU_REG_Q_1_WR_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_1_WR_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_1_WR_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_1_WR_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_1_WR_NUM_WORDS_LEFT_REG, &val);
	printf("CPU_REG_Q_1_WR_NUM_WORDS_LEFT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_WR_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_1_WR_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_RD_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_1_RD_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_1_RD_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_1_RD_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_1_RD_NUM_WORDS_AVAIL_REG, &val);
	printf("CPU_REG_Q_1_RD_NUM_WORDS_AVAIL_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_RD_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_1_RD_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_RX_NUM_PKTS_RCVD_REG, &val);
	printf("CPU_REG_Q_1_RX_NUM_PKTS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_TX_NUM_PKTS_SENT_REG, &val);
	printf("CPU_REG_Q_1_TX_NUM_PKTS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_RX_NUM_WORDS_RCVD_REG, &val);
	printf("CPU_REG_Q_1_RX_NUM_WORDS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_TX_NUM_WORDS_SENT_REG, &val);
	printf("CPU_REG_Q_1_TX_NUM_WORDS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_RX_NUM_BYTES_RCVD_REG, &val);
	printf("CPU_REG_Q_1_RX_NUM_BYTES_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_1_TX_NUM_BYTES_SENT_REG, &val);
	printf("CPU_REG_Q_1_TX_NUM_BYTES_SENT_REG: %u\n\n", val);

	readReg(&nf2, CPU_REG_Q_2_WR_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_2_WR_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_2_WR_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_2_WR_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_2_WR_NUM_WORDS_LEFT_REG, &val);
	printf("CPU_REG_Q_2_WR_NUM_WORDS_LEFT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_WR_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_2_WR_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_RD_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_2_RD_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_2_RD_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_2_RD_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_2_RD_NUM_WORDS_AVAIL_REG, &val);
	printf("CPU_REG_Q_2_RD_NUM_WORDS_AVAIL_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_RD_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_2_RD_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_RX_NUM_PKTS_RCVD_REG, &val);
	printf("CPU_REG_Q_2_RX_NUM_PKTS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_TX_NUM_PKTS_SENT_REG, &val);
	printf("CPU_REG_Q_2_TX_NUM_PKTS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_RX_NUM_WORDS_RCVD_REG, &val);
	printf("CPU_REG_Q_2_RX_NUM_WORDS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_TX_NUM_WORDS_SENT_REG, &val);
	printf("CPU_REG_Q_2_TX_NUM_WORDS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_RX_NUM_BYTES_RCVD_REG, &val);
	printf("CPU_REG_Q_2_RX_NUM_BYTES_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_2_TX_NUM_BYTES_SENT_REG, &val);
	printf("CPU_REG_Q_2_TX_NUM_BYTES_SENT_REG: %u\n\n", val);

	readReg(&nf2, CPU_REG_Q_3_WR_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_3_WR_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_3_WR_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_3_WR_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_3_WR_NUM_WORDS_LEFT_REG, &val);
	printf("CPU_REG_Q_3_WR_NUM_WORDS_LEFT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_WR_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_3_WR_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_RD_DATA_WORD_REG, &val);
	printf("CPU_REG_Q_3_RD_DATA_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_3_RD_CTRL_WORD_REG, &val);
	printf("CPU_REG_Q_3_RD_CTRL_WORD_REG: 0x%08x\n", val);
	readReg(&nf2, CPU_REG_Q_3_RD_NUM_WORDS_AVAIL_REG, &val);
	printf("CPU_REG_Q_3_RD_NUM_WORDS_AVAIL_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_RD_NUM_PKTS_IN_Q_REG, &val);
	printf("CPU_REG_Q_3_RD_NUM_PKTS_IN_Q_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_RX_NUM_PKTS_RCVD_REG, &val);
	printf("CPU_REG_Q_3_RX_NUM_PKTS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_TX_NUM_PKTS_SENT_REG, &val);
	printf("CPU_REG_Q_3_TX_NUM_PKTS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_RX_NUM_WORDS_RCVD_REG, &val);
	printf("CPU_REG_Q_3_RX_NUM_WORDS_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_TX_NUM_WORDS_SENT_REG, &val);
	printf("CPU_REG_Q_3_TX_NUM_WORDS_SENT_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_RX_NUM_BYTES_RCVD_REG, &val);
	printf("CPU_REG_Q_3_RX_NUM_BYTES_RCVD_REG: %u\n", val);
	readReg(&nf2, CPU_REG_Q_3_TX_NUM_BYTES_SENT_REG, &val);
	printf("CPU_REG_Q_3_TX_NUM_BYTES_SENT_REG: %u\n\n", val);
        */

	readReg(&nf2, IN_ARB_NUM_PKTS_SENT_REG, &val);
	printf("IN_ARB_NUM_PKTS_SENT_REG                  %u\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_WORD_0_LO_REG, &val);
	printf("IN_ARB_LAST_PKT_WORD_0_LO_REG             0x%08x\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_WORD_0_HI_REG, &val);
	printf("IN_ARB_LAST_PKT_WORD_0_HI_REG             0x%08x\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_CTRL_0_REG, &val);
	printf("IN_ARB_LAST_PKT_CTRL_0_REG                0x%02x\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_WORD_1_LO_REG, &val);
	printf("IN_ARB_LAST_PKT_WORD_1_LO_REG             0x%08x\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_WORD_1_HI_REG, &val);
	printf("IN_ARB_LAST_PKT_WORD_1_HI_REG             0x%08x\n", val);
	readReg(&nf2, IN_ARB_LAST_PKT_CTRL_1_REG, &val);
	printf("IN_ARB_LAST_PKT_CTRL_1_REG                0x%02x\n", val);
	readReg(&nf2, IN_ARB_STATE_REG, &val);
	printf("IN_ARB_STATE_REG                          %u\n\n", val);

	for (i = 0; i < 12; i++) {
		readReg(&nf2, OQ_QUEUE_0_NUM_WORDS_LEFT_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_WORDS_LEFT_REG_%d                   %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKT_BYTES_STORED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKT_BYTES_STORED_REG_%d             %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_OVERHEAD_BYTES_STORED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_OVERHEAD_BYTES_STORED_REG_%d        %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKTS_STORED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKTS_STORED_REG_%d                  %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKTS_DROPPED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKTS_DROPPED_REG_%d                 %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKT_BYTES_REMOVED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKT_BYTES_REMOVED_REG_%d            %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_OVERHEAD_BYTES_REMOVED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_OVERHEAD_BYTES_REMOVED_REG_%d       %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKTS_REMOVED_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKTS_REMOVED_REG_%d                 %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_ADDR_LO_REG + i * qAddrOffset, &val);
		printf("OQ_ADDRESS_LO_REG_%d                       0x%08x\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_ADDR_HI_REG + i * qAddrOffset, &val);
		printf("OQ_ADDRESS_HI_REG_%d                       0x%08x\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_WR_ADDR_REG + i * qAddrOffset, &val);
		printf("OQ_WR_ADDRESS_REG_%d                       0x%08x\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_RD_ADDR_REG + i * qAddrOffset, &val);
		printf("OQ_RD_ADDRESS_REG_%d                       0x%08x\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_NUM_PKTS_IN_Q_REG + i * qAddrOffset, &val);
		printf("OQ_NUM_PKTS_IN_Q_REG_%d                    %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_MAX_PKTS_IN_Q_REG + i * qAddrOffset, &val);
		printf("OQ_MAX_PKTS_IN_Q_REG_%d                    %u\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_CTRL_REG + i * qAddrOffset, &val);
		printf("OQ_CONTROL_REG_%d                          0x%08x\n", i, val);
		readReg(&nf2, OQ_QUEUE_0_FULL_THRESH_REG + i * qAddrOffset, &val);
		printf("OQ_FULL_THRESH_REG_%d                      %u\n\n", i, val);
		// The following register is not yet hooked up
		//readReg(&nf2, PKT_GEN_OQ_QUEUE_0_CURR_ITER_REG + i * qAddrOffset, &val);
		//printf("PKT_GEN_OQ_CURR_ITER_REG_%d                %u\n\n", i, val);
	}

	readReg(&nf2, PKT_GEN_CTRL_ENABLE_REG, &val);
	printf("PKT_GEN_CTRL_ENABLE_REG                   0x%08x\n\n", val);

	for (i = 0; i < 8; i++) {
		readReg(&nf2, RATE_LIMIT_0_CTRL_REG + i * rateLimOffset, &val);
		printf("RATE_LIMIT_ENABLE_REG_%d                   0x%08x\n", i, val);
		readReg(&nf2, RATE_LIMIT_0_TOKEN_INTERVAL_REG + i * rateLimOffset, &val);
		printf("RATE_LIMIT_TOKEN_INTERVAL_REG_%d           0x%08x\n", i, val);
		readReg(&nf2, RATE_LIMIT_0_TOKEN_INTERVAL_REG + i * rateLimOffset, &val);
		printf("RATE_LIMIT_TOKEN_INC_REG_%d                0x%08x\n\n", i, val);
	}

}

//
// printMAC: print a MAC address as a : separated value. eg:
//    00:11:22:33:44:55
//
void printMAC(unsigned hi, unsigned lo)
{
	printf("%02x:%02x:%02x:%02x:%02x:%02x",
			((hi>>8)&0xff), ((hi>>0)&0xff),
			((lo>>24)&0xff), ((lo>>16)&0xff), ((lo>>8)&0xff), ((lo>>0)&0xff)
		);
}


//
// printIP: print an IP address in dotted notation. eg: 192.168.0.1
//
void printIP(unsigned ip)
{
	printf("%u.%u.%u.%u",
			((ip>>24)&0xff), ((ip>>16)&0xff), ((ip>>8)&0xff), ((ip>>0)&0xff)
		);
}
