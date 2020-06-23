########################
# huili@ruijie.com.cn  #
# 2020/6/23            #
########################
LDFLAGS += -O3 -libverbs -lrdmacm -lpthread
CPPFLAGS += -O3 -std=c++11
CFLAGS += -O3
CC=gcc
CPP=g++
INC=-I./inc
BUILD_OUTPUT=./obj

.PHONY:all

all: Clock.o ceph_time.o rdma.o rdma_tongji.o Infiniband.o
	@if [ ! -d ${BUILD_OUTPUT} ]; then mkdir -p ${BUILD_OUTPUT}; fi
	$(CPP) -o rdma_tongji obj/Clock.o obj/rdma.o obj/rdma_tongji.o obj/Infiniband.o $(LDFLAGS) $(CPPFLAGS)

Clock.o:
	@if [ ! -d ${BUILD_OUTPUT} ]; then mkdir -p ${BUILD_OUTPUT}; fi
	$(CPP) $(INC) -c src/Clock.cc -o obj/Clock.o $(CPPFLAGS)

rdma.o:
	$(CC) $(INC) -c src/rdma.c -o obj/rdma.o $(CFLAGS)

rdma_tongji.o:
	$(CPP) $(INC) -c src/rdma_tongji.cpp -o obj/rdma_tongji.o $(CPPFLAGS)

Infiniband.o:
	$(CPP) $(INC) -c src/Infiniband.c -o obj/Infiniband.o $(CPPFLAGS)

ceph_time.o:
	$(CPP) $(INC) -c src/ceph_time.cc -o obj/ceph_time.o $(CPPFLAGS)
	
clean:
	@rm -rf rdma_tongji *.o ${BUILD_OUTPUT} ${BUILD_OUTPUT}/*.o
