/*
  rdma_tongji
  2018/5/29
  lihui@ruijie.com.cn
  v0.02
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
#include <string.h>
#include <iostream>

#include "Infiniband.h"
#include "ceph_time.h"
#include "Clock.h"

void listFiles(const char *dir);
bool isFolderExist(const char *folder);
bool isFileExist(const char *file);
void listDirFile(char *dirfile);
void savetofile(const char *file);
void cnpinvoke();
void cnprate();
void ethtool(int argc, char *argv[]);

const char *mlnxethtool = "//opt//mellanox//ethtool//sbin//ethtool";
const char *counterspath = "//sys//class//infiniband//mlx5_bond_0//ports//1//counters//";
const char *hwcounterspath = "//sys//class//infiniband//mlx5_bond_0//ports//1//hw_counters//";

void savetofile(const char *file){
	
	FILE *fpw = fopen(file,"w");
	if(fpw == NULL)exit(0);
	
	DIR *p;
	const char *paths[2] = {counterspath,hwcounterspath};
	char rbuffer[4096];
	char wbuffer[4096];
	char counterfilepath[4096];
	
	for(int i=0;i<2;i++){
	if((p = opendir(paths[i])) == NULL)
	{
	printf("not open %s",paths[i]);
	exit(0);
	}
	else
	printf("%s\n",paths[i]);
	struct dirent *dirp;
	while((dirp = readdir(p)) != NULL){
		if(isFileExist(dirp->d_name))
		continue;
		int len;
		sprintf(counterfilepath,"%s%s",paths[i],dirp->d_name);
		FILE *fp = fopen(counterfilepath,"r");
		fseek(fp,0L,SEEK_END);
		len = ftell(fp);
		rewind(fp);
		fread(rbuffer,len,1,fp);
		int i = 0;
		while(i<len&&rbuffer[i]!='\n')
			i++;
		rbuffer[i] = '\0';
		sprintf(wbuffer,"%s %s\n",dirp->d_name,rbuffer);
		fwrite(wbuffer,strlen(wbuffer),1,fpw);
		fclose(fp);
	}//while
	}//for
	printf("savetofile done\n");
	fclose(fpw);
	closedir(p);

}//void

void listFiles(const char *dir){
	DIR *p;
	if((p = opendir(dir)) == NULL)
	{
	printf("not open %s",dir);
	exit(0);
	}//if
	else
	printf("%s\n",dir);

	struct dirent *dirp;
	char buffer[4096];
	char counterfilepath[4096];
	while((dirp = readdir(p)) != NULL){
		if(isFileExist(dirp->d_name))	 
		continue;
		int len;
		sprintf(counterfilepath,"%s%s",dir,dirp->d_name);
		//printf("%s\n",counterfilepath);
		FILE *fp = fopen(counterfilepath,"r");
		fseek(fp,0L,SEEK_END);
		len = ftell(fp);
		rewind(fp);
		fread(buffer,len,1,fp);
		int i = 0;
		while(i<len&&buffer[i]!='\n')
			i++;
		buffer[i] = '\0';
		printf("%100s\t%s\n",dirp->d_name,buffer);
		fclose(fp);
	}//while
	closedir(p);
}//void

void listEntry(const char *dir, const char *entry){
	DIR *p;
	if((p = opendir(dir)) == NULL)
	{
	printf("not open %s",dir);
	exit(0);
	}//if
	//printf("%s %s\n",dir,entry);
	struct dirent *dirp;
	char buffer[4096];
	char counterfilepath[4096];
	while((dirp = readdir(p)) != NULL){
		if(isFileExist(dirp->d_name))
		continue;
		if(strcmp(dirp->d_name,entry) != 0)
		continue;	
		int len;
		sprintf(counterfilepath,"%s%s",dir,dirp->d_name);
		FILE *fp = fopen(counterfilepath,"r");
		fseek(fp,0L,SEEK_END);
		len = ftell(fp);
		rewind(fp);
		fread(buffer,len,1,fp);
		int i = 0;
		while(i<len&&buffer[i]!='\n')
			i++;
		buffer[i] = '\0';
		printf("%s\t:%s\n",dirp->d_name,buffer);
		fclose(fp);
	}//while
	closedir(p);
}//listEntry

void cnpinvoke(){
#if 1
	//char *pcmd ="./cnp.sh -d mlx5_bond_0 -i 1";
	cnprate();
#endif
}//void

void cnprate(){
	
	utime_t t1= ceph_clock_now();
	char *pcmd ="./cnp.sh -d p3p1";
	FILE *stream;
	char rbuf[4096];
	char cbuf[1024];
	sprintf(cbuf,"./cnp.sh -d p3p1");
	stream = popen(cbuf,"r");
	fread(rbuf,sizeof(char),sizeof(rbuf),stream);

	const char *pset ="Total CNPs sent  (by receiver):";
	const char *phdl ="Total CNPs handled (by sender):";
#if 0
	//"Total CNPs sent  (by receiver): 0x0
	//"Total CNPs handled (by sender): 0x0
#endif

	char *pEND;
	int val_set_t1 = strtol(rbuf,&pEND,16);
	int val_hdl_t1 = strtol(rbuf,&pEND,16);
	int val_3 = strtol(rbuf,&pEND,16);

	//printf("%d %d %d\n",val_set_t1,val_hdl_t1,val_3);
	sleep(1);
	utime_t t2= ceph_clock_now();
	stream = popen(cbuf,"r");

	fread(rbuf,sizeof(char),sizeof(rbuf),stream);
	int val_set_t2 = strtol(rbuf,&pEND,16);
	int val_hdl_t2 = strtol(rbuf,&pEND,16);
	
	utime_t duration = t2 - t1;
	uint64_t msec = duration.to_msec();

	printf("sent msec:%ld rate:%lf n/s\n",msec,(float)(val_set_t2-val_set_t1)/(msec/1000.0));
	printf("handle msec:%ld rate:%lf n/s\n",msec,(float)(val_hdl_t2-val_hdl_t1)/(msec/1000.0));
	fclose(stream);	
		
}//cnprate

#if 0
#endif

void ethtool(int argc, char *argv[]){

	//char *pdevice = argv[2];
	//char *pentry  = argv[3];
	//char *rate    = argv[4];
	FILE *stream;
	char rbuf[409600];
	char cbuf[1024];
	memset(rbuf,'\0',sizeof(rbuf));
	memset(cbuf,'\0',sizeof(cbuf));
	char *pcmd = "//opt//mellanox//ethtool//sbin//ethtool";

	sprintf(cbuf,"%s -S %s\n",pcmd,argv[2]);
	long int new_val = 0;
	long int old_val = 0;
	utime_t new_time;
	utime_t old_time;
	int wait_secs = 1;
	char *pstr;

	if(argc == 6){
		wait_secs = atoi(argv[5]);
		if(wait_secs<=0){
		printf("atioi error\n");	
		exit(0);
		}
	}
	if(wait_secs < 1)
		return;
	int t = 1;
	while(wait_secs>0){

	stream = popen(cbuf,"r");
	fread(rbuf,sizeof(char),sizeof(rbuf),stream);
	pstr = strstr(rbuf,argv[3]);

	if(pstr == NULL) {
	printf("entry does not exsit in ethtool\n");
	exit(-1);
	}

	int i = 0;
	while(pstr[i++]!='\n'){
	}//while
	pstr[i] = '\0';
	pstr = strstr(pstr,":");
	pstr++;pstr++;
	char *pEND;
	new_val = strtol(pstr,&pEND,10);
	new_time = ceph_clock_now();

	if(argc == 4){
	printf("%s:%ld\n",argv[3],new_val);
	}else if (argc ==6){
	utime_t duration = new_time - old_time;
	uint64_t msec = duration.to_msec();
	if(t<1)
	printf("%s %s:%ld rate:%lf bytes/sec\n",argv[2],argv[3],new_val,(float)(new_val-old_val)/(msec/1000.0));
	t--;
	old_time = new_time;
	old_val = new_val;
	sleep(1);	
	}else {
	}//else

	wait_secs--;
	}//while

}//void
bool isFolderExist(const char *folder)
{
	DIR *dir;
	if(folder == NULL)
	{
	return false;
	}
	if((dir = opendir(folder)) == NULL)
	{
	return false;
	}
	closedir(dir);
	return true;
}
bool isFileExist(const char *file)
{
	if(file == NULL)
	{
	return false;
	}
	if(access(file,F_OK) == 0)
	return true;
	return false;
}//
void listDirFile(char *dirfile)
{
	char childpath[200];
	memset(childpath,0,sizeof(childpath));
	DIR *dp;
	struct dirent *ent;
	dp = opendir(dirfile);
	while(NULL !=(ent = readdir(dp)))
	{
		if(ent->d_type &DT_DIR)
		{
			if(strcmp(ent->d_name,".")==0||strcmp(ent->d_name,"..")==0)
			continue;
			sprintf(childpath,"%s/%s",dirfile,ent->d_name);
			printf("%s\n",childpath);
			listDirFile(childpath);	
		}
	}//while

}

static void usage()
{
	printf("usage: rdma_tongji \n\n\n");
	printf("  -l [entry]    		list entries\n");
	printf("  -a        			see all entries' values\n");
	printf("  -s [fname]    		save to file\n");
	printf("  -p [port]   			port\n");
	printf("  -c        			cnp counters\n");
	printf("  -q				query device\n");
	printf("  -e [device] [entiry] ['rate'] ['sec']	ethtool\n");

}//static

//const char *counterspath = "//sys//class//infiniband//mlx5_bond_0//ports//1//counters//";
//const char *hwcounterspath = "//sys//class//infiniband//mlx5_bond_0//ports//1//hw_counters//";

int main(int argc, char *argv[])
{

	if(argc <=1){
	printf("rdma_tongji\n");
	printf("\tprogram to take statistics of rdma devices, counters and status.\n");
	printf("\t-h for usage. version 0.01.\n\n");
	}

	int op;
	int ret = 0;
	int port = -1;
	int server = 0;
	char *cb = NULL;
	while ((op = getopt(argc, argv, "Pp:lsachqe")) != -1) {
		switch (op) {
		case 'a':
			listFiles(counterspath);
			listFiles(hwcounterspath);
			break;
		case 'c':
			cnpinvoke();
			break;
		case 'p':
			port = htons(atoi(optarg));
			printf("port:%d\n",port);
			break;
		case 's':
			server = 1;
			savetofile(argv[optind]);	
			break;
		case 'l':
			cb = optarg;
			//printf("cb:%s optind:%d\n",argv[optind],optind);
			if(argv[optind] == NULL){
				printf("missing entry\n");
				exit(-1);
			}
			listEntry(counterspath,argv[optind]);
			listEntry(hwcounterspath,argv[optind]);
			break;
		case 'h':
			usage();
			break;
		case 'q':
			query_rdma_device();
			break;
		case 'e':
			ethtool(argc, argv);
			break;
		default:
			usage();
			ret = -EINVAL;
		}//default
	}//while
	return ret;
}
#endif
