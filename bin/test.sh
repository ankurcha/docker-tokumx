#!/bin/sh

PORT=10000

if [ ! -z "$1" ]; then
PORT=$1
fi
echo $PORT
