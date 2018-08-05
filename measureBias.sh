#!/bin/bash
#
# Dump Strategy 1
#
# Take pcap dump from various interface and
# try to use to predict observed bias.
#

# Address to ping to
export TARGET_IPV4="10.10.1.2"
export TARGET_IPV6="fd41:98cb:a6ff:5a6a::2"

# Native (local) ping command
export PING_NATIVE_CMD="$(pwd)/iputils/ping"
export NATIVE_DEV="eth1"

# Container ping command
export PING_IMAGE_NAME="chrismisa/contools:ping"
export PING_CONTAINER_NAME="ping-container"
export PING_CONTAINER_CMD="docker exec $PING_CONTAINER_NAME ping"
export CONTAINER_DEV="eth0"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5_s56_0"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_1"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_2"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_3"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_4"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_5"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_6"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_7"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_8"]="-c 100 -i 0.5 -s 56"
  ["i0.5_s56_9"]="-c 100 -i 0.5 -s 56"
)

# Tag for data directory
export DATE_TAG=`date +%Y%m%d%H%M%S`
# File name for metadata
export META_DATA="Metadata"
# Sleep for putting time around measurment
export LITTLE_SLEEP="sleep 3"
export BIG_SLEEP="sleep 10"
# Cosmetics
export B="------------"

# Make a directory for results
echo $B Starting Experiment: creating data directory $B
mkdir $DATE_TAG
cd $DATE_TAG

# Get some basic meta-data
# echo "uname -a -> $(uname -a)" >> $META_DATA
# echo "docker -v -> $(docker -v)" >> $META_DATA
# echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Start ping container as service
echo $B Spinning up the ping container $B
docker run -itd --name=$PING_CONTAINER_NAME \
                --entrypoint="/bin/bash" \
                $PING_IMAGE_NAME

# Wait for container to be ready
until [ "`docker inspect -f '{{.State.Running}}' $PING_CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Grab container's network namespace and put it somewhere useful
PING_CONTAINER_PID=`docker inspect -f '{{.State.Pid}}' $PING_CONTAINER_NAME`
mkdir -p /var/run/netns
ln -sf /proc/$PING_CONTAINER_PID/ns/net /var/run/netns/$PING_CONTAINER_NAME

# Go through tests
for i in "${!ARG_SEQ[@]}"
do
  # Run control
  echo $B Running control . . . $B

  $BIG_SLEEP

  # native -> target
  echo "  native -> target"
  $PING_NATIVE_CMD ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_control_native_target${i}.ping

  $LITTLE_SLEEP

  # container -> target
  echo "  container -> target"
  $PING_CONTAINER_CMD ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_control_container_target${i}.ping

  $LITTLE_SLEEP

  # Run under instrumentation
  echo $B Running instrumented ... $B
  echo "  Starting packet capture"
  # Start dump on host's outbound iface
  tcpdump -i $NATIVE_DEV -w v4_host${i}.pcap icmp &
  HOST_DUMP_PID=$!
  # Start dump on container's veth end
  ip netns exec $PING_CONTAINER_NAME tcpdump -i $CONTAINER_DEV -w v4_container${i}.pcap icmp &
  CONTAINER_DUMP_PID=$!
  
  $BIG_SLEEP

  # native -> target
  echo "  native -> target"
  $PING_NATIVE_CMD ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_native_target${i}.ping

  $LITTLE_SLEEP

  # container -> target
  echo "  container -> target"
  $PING_CONTAINER_CMD ${ARG_SEQ[$i]} $TARGET_IPV4 > v4_container_target${i}.ping

  $LITTLE_SLEEP

  # Stop instrumentation
  echo "  Stopping packet capture"
  kill $HOST_DUMP_PID
  kill $CONTAINER_DUMP_PID

  $LITTLE_SLEEP

done

# Clean up
$BIG_SLEEP
docker stop $PING_CONTAINER_NAME
docker rm $PING_CONTAINER_NAME
rm -f /var/run/netns/$PING_CONTAINER_NAME

echo Done.
