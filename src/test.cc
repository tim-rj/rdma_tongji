#include <iostream>
#include <utility>
#include <sstream>
#include <string>
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <iostream>

int main(int argc, char ** argv){
	std::ostream myost(std::cout.rdbuf());
	char buf[1024];
	sprintf(buf,"0x12  0x13 3\n");
	char *pEND;
	int val1 = strtol(buf,&pEND,16);
	int val2 = strtol(buf,&pEND,16);
	int val3 = strtol(buf,&pEND,16);
	printf("%d %d %d \n",val1,val2,val3);
}//int
