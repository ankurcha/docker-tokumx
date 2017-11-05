#!/bin/bash

N=$1
for (( RS=0; RS<$N; RS++ ))
do

PORT=$(((( 1 + $RS))*10000))
echo starting rs$RS on port $PORT
./start_singleShard.sh $PORT $RS &

done
