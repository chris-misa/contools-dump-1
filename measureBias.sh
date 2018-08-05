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
export NATIVE_DEV="eno1d1"

# Container ping command
export PING_IMAGE_NAME="chrismisa/contools:ping"
export PING_CONTAINER_NAME="ping-container"
export PING_CONTAINER_CMD="docker exec $CONTAINER_NAME ping"

# Argument sequence is an associative array
# between file suffixes and argument strings
declare -A ARG_SEQ=(
  ["i0.5_s56_0.ping"]="-c 5 -i 0.5 -s 56"
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
echo "uname -a -> $(uname -a)" >> $META_DATA
echo "docker -v -> $(docker -v)" >> $META_DATA
echo "sudo lshw -> $(sudo lshw)" >> $META_DATA

# Start ping container as service
echo $B Spinning up the ping container $B
docker run --rm -itd --name=$CONTAINER_NAME \
                     --entrypoint="/bin/bash" \
                     $PING_IMAGE_NAME

# Wait for container to be ready
until [ "`docker inspect -f '{{.State.Running}}' $CONTAINER_NAME`" \
        == "true" ]
do
  sleep 1
done

# Go through tests
for i in "${!ARG_SEQ[@]}"
do
  # Run control

  # native -> target
  # container -> target

  # Run under instrumentation

  # native -> target
  # container -> target
done

# Clean up
$BIG_SLEEP
docker stop $CONTAINER_NAME

echo Done.
