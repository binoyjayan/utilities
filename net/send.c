#include <stdio.h>		/* for printf() and fprintf() */
#include <sys/socket.h>		/* for socket() and bind() */
#include <arpa/inet.h>		/* for sockaddr_in */
#include <stdlib.h>		/* for atoi() and exit() */
#include <string.h>		/* for memset() */
#include <unistd.h>		/* for close() */
#include "die.h"

#define RECV_BUF_LEN 128

void DieWithError(char *errorMessage);	/* External error handling function */

int main(int argc, char *argv[])
{
	int ret, i, sock;		/* Socket */
	struct sockaddr_in broadcastAddr;	/* Broadcast address */
	struct sockaddr_in serverAddr;
	char *broadcastIP;	/* IP broadcast address */
	unsigned short broadcastPort;	/* Server port */
	char *sendString;	/* String to broadcast */
	int broadcastPermission;	/* Socket opt to set permission to broadcast */
	unsigned int sendStringLen;	/* Length of string to broadcast */
	unsigned int recvbufflen, addrlen;
	char recvbuff[RECV_BUF_LEN];

	if (argc < 4) {		/* Test for correct number of parameters */
		fprintf(stderr,
			"Usage:  %s <IP Address> <Port> <Send String>\n",
			argv[0]);
		exit(1);
	}

	broadcastIP = argv[1];	/* First arg:  broadcast IP address */
	broadcastPort = atoi(argv[2]);	/* Second arg:  broadcast port */
	sendString = argv[3];	/* Third arg:  string to broadcast */

	/* Create socket for sending/receiving datagrams */
	if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
		DieWithError("socket() failed");

	/* Set socket to allow broadcast */
	broadcastPermission = 1;
	if (setsockopt
	    (sock, SOL_SOCKET, SO_BROADCAST, (void *)&broadcastPermission,
	     sizeof(broadcastPermission)) < 0)
		DieWithError("setsockopt() failed");

	/* Construct local address structure */
	memset(&broadcastAddr, 0, sizeof(broadcastAddr));	/* Zero out structure */
	broadcastAddr.sin_family = AF_INET;	/* Internet address family */
	broadcastAddr.sin_addr.s_addr = inet_addr(broadcastIP);	/* Broadcast IP address */
	broadcastAddr.sin_port = htons(broadcastPort);	/* Broadcast port */

	sendStringLen = strlen(sendString);
	recvbufflen   = sizeof(recvbuff);
	for (i = 0; i < 10; i++) {
		printf("Sending broadcast message...\n");
		ret = sendto(sock, sendString, sendStringLen, 0, (struct sockaddr *)
		     &broadcastAddr, sizeof(broadcastAddr));
		if(ret != sendStringLen) {
			DieWithError("sendto() sent a different number of bytes than expected");
		}
		printf("Waiting for reply...\n");
		ret = recvfrom(sock, recvbuff, recvbufflen, 0,(struct sockaddr *)&serverAddr, &addrlen);
		if(ret >= 0) {
			recvbuff[ret] = '\0';
			printf("Received %d bytes: %s\n", ret, recvbuff);
			break;
		}
		sleep(3);	/* Avoids flooding the network */
	}
}

/*
Reference

http://www.cs.ubbcluj.ro/~dadi/compnet/labs/lab3/udp-broadcast.html
http://cs.baylor.edu/~donahoo/practical/CSockets/code/BroadcastSender.c
http://cs.baylor.edu/~donahoo/practical/CSockets/code/BroadcastReceiver.c

*/
