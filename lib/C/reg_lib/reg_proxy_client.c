/***************************************************************
* Author: Jad Naous
* Filename: reg_proxy_client.c
* Description:
* Implements a library to talk to the reg_proxy_server
****************************************************************/

#include "reg_proxy.h"
#include "../common/reg_defines.h"
#include <string.h>

#define MD5_LEN		4

/* Local variables */
unsigned cpci_version = -1;
unsigned cpci_revision = -1;
unsigned nf2_device_id = -1;
unsigned nf2_revision = -1;
unsigned nf2_cpci_version = -1;
unsigned nf2_cpci_revision = -1;
char nf2_device_str[DEVICE_STR_LEN] = "";

static int connectRegServer();
static int sendRequest(int socket_to_server, struct reg_request *reg_request);
static void disconnectRegServer(int socket_to_server);

static int connectRegServer(){
    struct sockaddr_in servaddr;
    int socket_to_server;

    /* get socket to server */
    if ( (socket_to_server = socket(PF_INET, SOCK_STREAM, 0)) < 0){
        perror("socket");
        DPRINTF("");
        return -1;
    }

    DPRINTF("Socket number: %d\n", socket_to_server);

    /* fill in the address struct */
    memset(&servaddr, 0, sizeof(SA));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(SERVER_PORT);
    inet_aton(SERVER_IP_ADDR, &servaddr.sin_addr);

    DPRINTF("Connecting to %s:%u\n", SERVER_IP_ADDR, SERVER_PORT);

    if ( connect(socket_to_server, (SA *) &servaddr, sizeof(servaddr)) != 0) {
        perror("connect");
        DPRINTF("connect returned error\n");
        close(socket_to_server);
        return -1;
    }

    return socket_to_server;
}

static int sendRequest(int socket_to_server, struct reg_request *reg_request) {

    DPRINTF("Sending the following request:\n");
    dprint_req(reg_request);

    if(writen(socket_to_server,
       (const char *) reg_request,
    	sizeof (struct reg_request)) < sizeof(struct reg_request)) {
        perror("write");
        DPRINTF("Error on write\n");
    	return -1;
    }

    if(readn(socket_to_server, (char *) reg_request, sizeof(struct reg_request)) < sizeof(struct reg_request)) {
    	perror("read");
    	DPRINTF("Error on read\n");
    	return -1;
    }

    DPRINTF("Received the following response:\n");
    dprint_req(reg_request);

    return 0;
}

static void disconnectRegServer(int socket_to_server) {
    close(socket_to_server);
}

/*
 * readReg - read a register
 */
int readReg(struct nf2device *nf2, unsigned reg, unsigned *val)
{
	struct reg_request req;
	req.address = reg;
	req.data = 0xBADDD065;
	req.device_num = nf2->fd;
	req.error = 0;
	req.type = READ_REQ;

	if(sendRequest(nf2->net_iface, &req) < 0) {
		return -1;
	}

	*val = req.data;
	return req.error;
}

/*
 * writeReg - write a register
 */
int writeReg(struct nf2device *nf2, unsigned reg, unsigned val)
{
	struct reg_request req;
	req.address = reg;
	req.data = val;
	req.device_num = nf2->fd;
	req.error = 0;
	req.type = WRITE_REQ;

	if(sendRequest(nf2->net_iface, &req) < 0) {
		return -1;
	}
	return req.error;
}

/*
 * Check the iface name to make sure we can find the interface
 */
int check_iface(struct nf2device *nf2)
{
	struct reg_request req;
	int socket_to_server;

	/* test name length */
	if(strnlen(nf2->device_name, 10) > 7) {
		fprintf(stderr, "Interface name is too long: %s\n", nf2->device_name);
		return -1;
	}

	/* get the int part of the name */
	req.device_num = strtol(nf2->device_name + 4, NULL, 10);
	if(errno == EINVAL) {
		fprintf(stderr, "Error: device number is invalid.\n");
		return -1;
	}

	req.address = 0;
	req.data = 0;
	req.error = 0;
	req.type = CHECK_REQ;

	socket_to_server = connectRegServer();
	if(sendRequest(socket_to_server, &req) < 0) {
		DPRINTF("sendRequest caused an error.\n");
		disconnectRegServer(socket_to_server);
		return -1;
	}

	if(req.error < 0 || req.data != 1) {
		DPRINTF("Check failed.\n");
		disconnectRegServer(socket_to_server);
		return -1;
	}
	else {
		DPRINTF("Check succeeded.\n");
		nf2->fd = req.device_num;
		disconnectRegServer(socket_to_server);
		return 0;
	}
}

/*
 * Open the descriptor associated with the device name
 */
int openDescriptor(struct nf2device *nf2)
{
	struct reg_request req;
	int socket_to_server;

	req.address = 0;
	req.data = 0;
	req.device_num = nf2->fd;
	req.error = 0;
	req.type = OPEN_REQ;

	socket_to_server = connectRegServer();
	if(sendRequest(socket_to_server, &req) < 0) {
		DPRINTF("sendRequest failed.\n");
		disconnectRegServer(socket_to_server);
		return -1;
	}
	if(!req.error) {
		nf2->fd = req.device_num;
		nf2->net_iface = socket_to_server;
	}
	return req.error;
}

/*
 * Close the descriptor associated with the device name
 */
int closeDescriptor(struct nf2device *nf2)
{
	struct reg_request req;
	req.address = 0;
	req.data = 0;
	req.device_num = nf2->fd;
	req.error = 0;
	req.type = CLOSE_REQ;

	if(sendRequest(nf2->net_iface, &req) < 0) {
		DPRINTF("sendRequest failed.\n");
		return -1;
	}
	disconnectRegServer(nf2->net_iface);
	return req.error;
}


/*
 *  Read the version info from the board
 */
void read_info(struct nf2device *nf2)
{
  int i;

  // Read the version and revision
  readReg(nf2, NF2_DEVICE_ID, &nf2_device_id);
  readReg(nf2, NF2_REVISION, &nf2_revision);

  // Read the version string
  for (i = 0; i < (DEVICE_STR_LEN / 4) - 2; i++)
  {
    readReg(nf2, NF2_DEVICE_STR + i * 4, (unsigned *)(nf2_device_str + i * 4));

    // Perform byte swapping if necessary
    *(unsigned *)(nf2_device_str + i * 4) = ntohl(*(unsigned *)(nf2_device_str + i * 4));
  }
  nf2_device_str[DEVICE_STR_LEN - 1] = '\0';
}


/*
 *  Read the version info from the Virtex and CPCI
 */
void nf2_read_info(struct nf2device *nf2)
{
	int i;
	int md5_good = 1;
	unsigned md5[MD5_LEN];
	unsigned cpci_id;
	unsigned nf2_cpci_id;

	// Read the CPCI version/revision
	readReg(nf2, CPCI_ID_REG, &cpci_id);
	cpci_version = cpci_id & 0xffffff;
	cpci_revision = cpci_id >> 24;

	// Verify the MD5 checksum of the device ID block
	for  (i = 0; i < MD5_LEN; i++) {
		readReg(nf2, DEVICE_MD5_1_REG + i * 4, &md5[i]);
	}
	md5_good &= md5[0] == DEVICE_MD5_1_VAL;
	md5_good &= md5[1] == DEVICE_MD5_2_VAL;
	md5_good &= md5[2] == DEVICE_MD5_3_VAL;
	md5_good &= md5[3] == DEVICE_MD5_4_VAL;

	// Process only if the MD5 sum is good
	if (md5_good) {
		// Read the version and revision
		readReg(nf2, DEVICE_ID_REG, &nf2_device_id);
		readReg(nf2, DEVICE_REVISION_REG, &nf2_revision);
		readReg(nf2, DEVICE_CPCI_ID_REG, &nf2_cpci_id);
		nf2_cpci_version = nf2_cpci_id & 0xffffff;
		nf2_cpci_revision = nf2_cpci_id >> 24;

		// Read the version string
		for (i = 0; i < (DEVICE_STR_LEN / 4) - 2; i++)
		{
			readReg(nf2, DEVICE_STR_REG + i * 4, (unsigned *)(nf2_device_str + i * 4));

			// Perform byte swapping if necessary
			*(unsigned *)(nf2_device_str + i * 4) = ntohl(*(unsigned *)(nf2_device_str + i * 4));
		}
		nf2_device_str[DEVICE_STR_LEN - 1] = '\0';
	}
}

/*
 * Print out a test string
 */
void printHello (struct nf2device *nf2, int *val)
{
  printf ("Hello world. Name=%s val=%d\n", nf2->device_name, *val);
  *val = 10;
}
