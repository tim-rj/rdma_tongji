./rdma_tongji -e p3p1 tx_prio5_pause rate 2
./rdma_tongji -e p3p2 tx_prio5_pause rate 2
./rdma_tongji -e p3p1 rx_prio5_pause rate 2
./rdma_tongji -e p3p2 rx_prio5_pause rate 2
./rdma_tongji -e p3p1 tx_prio5_pause_duration rate 2
./rdma_tongji -e p3p2 tx_prio5_pause_duration rate 2
./rdma_tongji -e p3p1 rx_prio5_pause_duration rate 2
./rdma_tongji -e p3p2 rx_prio5_pause_duration rate 2
./rdma_tongji -c
n=$(ls -l /sys/kernel/debug/mlx5/0000\:06\:00.0/QPs |grep "^d"|wc -l)
echo "QPs:" $n
./rdma_tongji -l np_ecn_marked_roce_packets
./rdma_tongji -l rp_cnp_ignored
./rdma_tongji -l out_of_buffer
./rdma_tongji -l out_of_sequence
free -k | grep "Mem:" |awk '{print $4}'
