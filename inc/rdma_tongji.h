/*
  rdma_tongji.h
*/

#ifndef RDMA_TONGJI_H
#define RDMA_TONGJI_H

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
void test_rdma();

#endif
