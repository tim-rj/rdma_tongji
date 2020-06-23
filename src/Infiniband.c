/*
 * rdma device code
 */

#include "Infiniband.h"
//lihui 2018/3/19
//Test RDMA Device Code

#include <stdio.h>
#include <stdlib.h>

void query_rdma_device()
{
        struct ibv_device **list;
        struct ibv_device *ibv_dev;
        int err = 0;
        struct ibv_context *attr_ctx = NULL;
        struct ibv_device_attr device_attr;
        unsigned int sriov;
        unsigned int mps;
        int idx;
        int i;
        //dx = mlx5_dev_idx(&pci_dev->addr);
        /*if (idx == -1) {
                return -ENOMEM;
        }*/
        list = ibv_get_device_list(&i);
  	ibv_device *device = list[0];
  	if (device == NULL) {
  	printf("device null\n");
  	}
  	const char *name = ibv_get_device_name(device);
  	printf("%s\n",name);
  	if (ibv_open_device(device) == NULL) {
	printf("open rdma device failed\n");  
	}else
	printf("open rdma successful\n");
	#if 0
  	int r = ibv_query_device(ctxt, device_attr);
	#endif
}
