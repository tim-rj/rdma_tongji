/*
  rdma_tongji
  2018/3/7
  lihui@ruijie.com.cn
*/

#if 1
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

void listFiles(const char *dir);
bool isFolderExist(const char *folder);
bool isFileExist(const char *file);
void listDirFile(char *dirfile);

int main(int argc,char *argv[]){
	char *dir = "//sys//class//infiniband//mlx5_bond_0//ports//1//counters//unicast_rcv_packets";
	FILE *fp = fopen(dir,"r");
	fseek(fp,0L,SEEK_END);
	int len = ftell(fp);
	rewind(fp);
	long a = -1;
	char *buffer = (char *)malloc(len);
	fread(buffer,len,1,fp);
	printf("%s %lu\n",buffer,strlen(buffer));
	//int aa = a;
	fclose(fp);
}//void


#endif
