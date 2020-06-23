#/bin/bash

##################################
# fullmesh scripts version 1.0   #
# author: huili@ruijie.com.cn    #
# update date:2018/8/7		 #
##################################

hosts2=""
iperf_ports=""
ofed_ports=""
iperf_ports_base=2000
ofed_ports_base=3000

function usage(){
 echo "fullmesh.sh v1.0 usage"
 echo "fullmesh.sh -f HOST_FILE -t [Iperf/OFED]"
 echo "		start fullmesh test with Iperf or OFED tools on servers in HOST_FILE."
 echo ""
 echo "fullmesh.sh -f HOST_FILE -k [Iperf/OFED]"
 echo "		kill all Iperf or OFED processes on servers in HOST_FILE."
 echo ""
 exit 1
}

if [ $# -lt 1 ] ; then
usage
fi

size=0
if [ $1 == "-f" ] ; then
 FILE_NAME="$2"
 echo "$FILE_NAME"

 for LINE in  `cat $FILE_NAME`
 do
 hosts2=${hosts2}" "${LINE}
 size=$((size+1))
 done

 for ((I=1;I<$size;I++));do
 iperf_ports=$iperf_ports" "$iperf_ports_base
 iperf_ports_base=$((iperf_ports_base+20))
 ofed_ports=$ofed_ports" "$ofed_ports_base
 ofed_ports_base=$((ofed_ports_base+20))
 done

 OLD_IFS="$IFS"
 IFS=" "
 iperf_ports_arr=($iperf_ports)
 ofed_ports_arr=($ofed_ports)
 IFS="$OLD_IFS"

fi

if [ $3 == "-t" ] ; then
TYPE_NAME="$4"
echo "$TYPE_NAME"
fi

function kill_iperf(){
echo "kill iperf"
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

function kill_ofed(){
echo "kill ofed"
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

if [ $3 == "-k" ] ; then
 if [ $4 == "Iperf" ] ; then
 kill_iperf
 fi
 if [ $4 == "OFED" ] ; then 
 kill_ofed
 fi
fi

function checkiperfserverstate(){
echo "check iperf states"
for h in $hosts2
do
count=0
  for p in $ofed_ports
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
  for p in $iperf_ports
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
  for p1 in $ofed_ports
  do
    echo "ssh " $o1 "iperf3 -p" $p1 "-s &"
    ssh $o1 iperf3 -p $p1 -s >/dev/null 2>&1 &
  done 
done
echo ""
}

function ofedserver(){
echo "ofedserver"
for o1 in $hosts2
do
  for p1 in $iperf_ports
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
       echo "ssh " $o1 " iperf3 -p " ${ofed_ports_arr[$step1]} "-c" $o2 "&"
       ssh $o1 iperf3 -t 1000 -p ${ofed_ports_arr[$step1]} -c $o2 >/dev/null 2>&1 &
       fi
       if [ $step1 -eq $(($size-1)) ];then
       echo "ssh " $o1 " iperf3 -c -p " ${ofed_ports_arr[$step2]} "-c" $o2 "&"
       ssh $o1 iperf3 -t 1000 -p ${ofed_ports_arr[$step2]} -c $o2 >/dev/null 2>&1 &
       step2=$(($step2+1))
       fi
    fi
  done
step1=$(($step1+1))
done
echo ""
}

function ofedclient(){
echo "ofedclient"
step1=0
step2=0
for o1 in $hosts2
do
  for o2 in $hosts2
  do
    if [ "$o1"x != "$o2"x ];then
	if [ $step1 -lt $(($size-1)) ];then
        echo "ssh " $o1 "ib_write_bw -p " ${iperf_ports_arr[$step1]} $o2 "-q 100 -D 1000" "&"
	ssh $o1 ib_write_bw -p ${iperf_ports_arr[$step1]} -q 100 -D 1000 --tclass=136 $o2 >/dev/null 2>&1 &
	fi
	if [ $step1 -eq $(($size-1)) ];then
	echo "ssh " $o1 "ib_write_bw -p " ${iperf_ports_arr[$step2]} $o2 "-q 100 -D 1000" "&"
	ssh $o1 ib_write_bw -p ${iperf_ports_arr[$step2]} -q 100 -D 1000 --tclass=136 $o2 >/dev/null 2>&1 &
	step2=$(($step2+1))
	fi
    fi
  done
step1=$(($step1+1))
done
echo ""
}


if [ $3 == "-t" ] ; then
 if [ $4 == "Iperf" ] ; then
 iperfserver
 checkiperfserverstate
 iperfclient
 fi

 if [ $4 == "OFED" ] ; then
 ofedserver
 checkofedserverstate
 ofedclient
 fi
fi
