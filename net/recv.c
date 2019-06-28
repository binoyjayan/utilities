#include <stdio.h>		/* for printf() and fprintf() */
#include <sys/socket.h>		/* for socket(), connect(), sendto(), and recvfrom() */
#include <arpa/inet.h>		/* for sockaddr_in and inet_addr() */
#include <stdlib.h>		/* for atoi() and exit() */
#include <string.h>		/* for memset() */
#include <unistd.h>		/* for close() */
#include "die.h"

#define MAXRECVSTRING 255	/* Longest string to receive */
#define MY_IP_ADDR "192.168.0.1"

void DieWithError(char *errorMessage);	/* External error handling function */

int main(int argc, char *argv[])
{
	int ret, sock;		/* Socket */
	struct sockaddr_in broadcastAddr;	/* Broadcast Address */
	struct sockaddr_in clientAddr;
	unsigned short broadcastPort;	/* Port */
	char recvString[MAXRECVSTRING + 1];	/* Buffer for received string */
	char sendString[MAXRECVSTRING + 1];	/* Buffer for received string */
	int recvStringLen;	/* Length of received string */
	int sendStringLen;
	int addrlen;

	if (argc != 2) {	/* Test for correct number of arguments */
		fprintf(stderr, "Usage: %s <Broadcast Port>\n", argv[0]);
		exit(1);
	}

	broadcastPort = atoi(argv[1]);	/* First arg: broadcast port */

	/* Create a best-effort datagram socket using UDP */
	if ((sock = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0)
		DieWithError("socket() failed");

	/* Construct bind structure */
	memset(&broadcastAddr, 0, sizeof(broadcastAddr));	/* Zero out structure */
	broadcastAddr.sin_family = AF_INET;	/* Internet address family */
	broadcastAddr.sin_addr.s_addr = htonl(INADDR_ANY);	/* Any incoming interface */
	broadcastAddr.sin_port = htons(broadcastPort);	/* Broadcast port */

	/* Bind to the broadcast port */
	if (bind(sock, (struct sockaddr *)&broadcastAddr, sizeof(broadcastAddr))
	    < 0)
		DieWithError("bind() failed");

	while(1) {
		/* Receive a single datagram from the server */
		recvStringLen = recvfrom(sock, recvString, MAXRECVSTRING, 0, (struct sockaddr *)
			&clientAddr, &addrlen);
		if (recvStringLen < 0)
			DieWithError("recvfrom() failed");

		recvString[recvStringLen] = '\0';
		printf("Received: %s\n", recvString);
		sendStringLen = sprintf(sendString, "hello, my IP is %s", MY_IP_ADDR);
		ret = sendto(sock, sendString, sendStringLen, 0, (struct sockaddr *)
			&clientAddr, sizeof(clientAddr));
		if (ret < 0)
			DieWithError("sendto() failed");
	}
	close(sock);
	exit(0);
}

/*
Reference

http://www.cs.ubbcluj.ro/~dadi/compnet/labs/lab3/udp-broadcast.html
http://cs.baylor.edu/~donahoo/practical/CSockets/code/BroadcastSender.c
http://cs.baylor.edu/~donahoo/practical/CSockets/code/BroadcastReceiver.c

*/
