#!/bin/bash
#fullmesh scripts version 3.0
# changes since from version 1.0
# 1)fix error msg output
# 2)show ib_write processes
# 3)fix error msg output for iperf
# 4)show iperf processes

# killallpid() clean up all ib_write_bw process
# fullmeshserver()  the server
# fullmeshclient()  the client

# author: huili@ruijie.com.cn
# update date:2018/8/7

size=7
hosts2="rdma27 rdma26 rdma25 rdma24 rdma23 rdma22 rdma21"
#hosts2="rdma21 rdma24"
ports2="18000 20000 22000 23000 24000 25000"
#ports2="10002"
ports4="5000 5020 5040 5060 5080 5100"
#ports4="5000"

OLD_IFS="$IFS"
IFS=" "
ports2arr=($ports2)
ports4arr=($ports4)
IFS="$OLD_IFS"

function usage(){
 echo "fullmesh.sh usage"
 echo "set size = 2"
 echo "set hosts2 = rdma25 rdma24"
 echo "set ports2 = 1000"
 echo ""
}

function killalliperfpid(){
echo "kill all iperf"
for h in $hosts2
do
   rpids=$(ssh $h ps -aux|grep iperf3|grep -v grep|awk -F' ' '{print $2}')
   for rp in $rpids
   do
   echo "ssh" $h "kill -9 " $rp
   ssh $h kill -9 $rp	
   done
done
echo ""
}

function killallpid(){
echo "kill all ib_write_bw"
for h in $hosts2
do
  rpids=$(ssh $h ps -aux|grep ib_write_bw|grep -v grep|awk -F' ' '{print $2}')
  for rp in $rpids
  do
  echo "ssh" $h "kill -9 " $rp
  ssh $h kill -9 $rp
  done
done
echo ""
}

function checkiperfserverstate(){
echo "check iperf states"
for h in $hosts2
do
count=0
  for p in $ports4
  do
    #echo "ssh $h ps -aux|grep 'iperf3 -p $p'"
    iperfoutput=$(ssh $h ps -aux|grep 'iperf3 -p'|grep -v 'ssh'|grep -v 'grep')
    #echo $iperfoutput
    result=$(echo $iperfoutput|grep "iperf3 -p $p")
    if [[ "$result" != "" ]]
    then
      count=$(($count+1))
    else
      echo "No"
    fi
  done
totalcount=$(($size-1))
echo $h "has " $count "processes" $(awk 'BEGIN{printf "%.2f%\n",('$count'/'$totalcount')*100}')
done
echo ""
}

function checkofedserverstate(){
echo "check server states"
for h in $hosts2
do
count=0
  for p in $ports2
  do
    ibwriteoutput=$(ssh $h ps -aux|grep 'ib_write_bw -p '$p|grep -v 'ssh'|grep -v 'grep')
    result=$(echo $ibwriteoutput|grep "ib_write_bw -p "$p)
    if [[ "$result" != "" ]]
    then
      count=$(($count+1))
    else
      echo "No"
    fi
  done
totalcount=$(($size-1))
echo $h "has " $count "processes" $(awk 'BEGIN{printf "%.2f%\n",('$count'/'$totalcount')*100}')
done
echo ""
}

function iperfserver(){
echo "iperfserver"
for o1 in $hosts2
do
  for p1 in $ports4
  do
    echo "ssh " $o1 "iperf3 -p" $p1 "-s &"
    ssh $o1 iperf3 -p $p1 -s >/dev/null 2>&1 &
  done 
done
echo ""
}

function fullmeshserver(){
echo "fullmeshserver"
for o1 in $hosts2
do
  for p1 in $ports2
  do
    echo "ssh " $o1 "ib_write_bw -p " $p1 "-q 100 -D 1000" "&"
    ssh $o1 ib_write_bw -p $p1 -q 100 -D 1000 --tclass=136 >/dev/null 2>&1 &
  done
done
echo ""
}

function iperfclient(){
echo "iperfclient"
step1=0
step2=0
for o1 in $hosts2
do
  for o2 in $hosts2
  do
    if [ "$o1"x != "$o2"x ];then
       if [ $step1 -lt $((size-1)) ];then
       echo "ssh " $o1 " iperf3 -p " ${ports4arr[$step1]} "-c" $o2 "&"
       ssh $o1 iperf3 -t 1000 -p ${ports4arr[$step1]} -c $o2 >/dev/null 2>&1 &
       fi
       if [ $step1 -eq $(($size-1)) ];then
       echo "ssh " $o1 " iperf3 -c -p " ${ports4arr[$step2]} "-c" $o2 "&"
       ssh $o1 iperf3 -t 1000 -p ${ports4arr[$step2]} -c $o2 >/dev/null 2>&1 &
       step2=$(($step2+1))
       fi
    fi
  done
step1=$(($step1+1))
done
echo ""
}

function fullmeshclient(){
echo "fullmeshclient"
step1=0
step2=0
for o1 in $hosts2
do
  for o2 in $hosts2
  do
    if [ "$o1"x != "$o2"x ];then
	if [ $step1 -lt $(($size-1)) ];then
        echo "ssh " $o1 "ib_write_bw -p " ${ports2arr[$step1]} $o2 "-q 100 -D 1000" "&"
	ssh $o1 ib_write_bw -p ${ports2arr[$step1]} -q 100 -D 1000 --tclass=136 $o2 >/dev/null 2>&1 &
	fi
	if [ $step1 -eq $(($size-1)) ];then
	echo "ssh " $o1 "ib_write_bw -p " ${ports2arr[$step2]} $o2 "-q 100 -D 1000" "&"
	ssh $o1 ib_write_bw -p ${ports2arr[$step2]} -q 100 -D 1000 --tclass=136 $o2 >/dev/null 2>&1 &
	step2=$(($step2+1))
	fi
    fi
  done
step1=$(($step1+1))
done
echo ""
}

usage
#killallpid
killalliperfpid

iperfserver
checkiperfserverstate
iperfclient
#fullmeshserver
#checkofedserverstate
#fullmeshclient
