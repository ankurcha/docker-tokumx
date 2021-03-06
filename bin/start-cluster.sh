#!/bin/bash



PORT=10000

if [ ! -z "$1" ]; then
PORT=$1
fi

PORT_1=$(( $PORT - 1 ))
PORT1=$(( $PORT + 1 ))
PORT2=$(( $PORT + 2 ))


set -e

if sudo docker ps | grep "ankurcha/tokumx" >/dev/null; then
    echo ""
    echo "It looks like you already have some containers running."
    echo "Please take them down before attempting to bring up another"
    echo "cluster with the following command:"
    echo ""
    echo "  make stop-cluster"
    echo ""

    exit 1
fi

# start docker containers for 3xreplicaset rs0
SHARD00_ID=$(sudo docker run -d ankurcha/tokumx mongod --replSet rs0 --shardsvr --logpath /dev/stdout --bind_ip 0.0.0.0 --port $PORT)
SHARD00_IP=$(sudo docker inspect ${SHARD00_ID} | grep "IPAddress" | cut -d':' -f2 | cut -d'"' -f2)
echo "Your shard container ${SHARD00_ID} listen on ip: ${SHARD00_IP} (waiting that becomes ready)"
until sudo docker logs ${SHARD00_ID} | grep "replSet info you may need to run replSetInitiate" >/dev/null;
do
    sleep 2
done

SHARD01_ID=$(sudo docker run -d ankurcha/tokumx mongod --replSet rs0 --shardsvr --logpath /dev/stdout --bind_ip 0.0.0.0 --port $PORT1)
SHARD01_IP=$(sudo docker inspect ${SHARD01_ID} | grep "IPAddress" | cut -d':' -f2 | cut -d'"' -f2)
echo "Your shard container ${SHARD01_ID} listen on ip: ${SHARD01_IP} (waiting that becomes ready)"
until sudo docker logs ${SHARD01_ID} | grep "replSet info you may need to run replSetInitiate" >/dev/null;
do
    sleep 2
done

SHARD02_ID=$(sudo docker run -d ankurcha/tokumx mongod --replSet rs0 --shardsvr --logpath /dev/stdout --bind_ip 0.0.0.0 --port $PORT2)
SHARD02_IP=$(sudo docker inspect ${SHARD02_ID} | grep "IPAddress" | cut -d':' -f2 | cut -d'"' -f2)
echo "Your shard container ${SHARD02_ID} listen on ip: ${SHARD02_IP} (waiting that becomes ready)"
until sudo docker logs ${SHARD02_ID} | grep "replSet info you may need to run replSetInitiate" >/dev/null;
do
    sleep 2
done


echo "initialize replicaset"
mongo ${SHARD00_IP}:$PORT --eval "rs.initiate({_id: \"rs0\", members: [{_id:0, host:\"${SHARD00_IP}:$PORT\"}, {_id:1, host:\"${SHARD01_IP}:$PORT1\"}, {_id:2, host:\"${SHARD02_IP}:$PORT2\"}]});"
until sudo docker logs ${SHARD00_ID} | grep "replSet PRIMARY" >/dev/null;
do
    sleep 2
done
echo "The shard replset is available now..."

CONFIG0_ID=$(sudo docker run -d ankurcha/tokumx mongod --configsvr  --dbpath /data/ --logpath /dev/stdout --bind_ip 0.0.0.0 --port $PORT)
CONFIG0_IP=$(sudo docker inspect ${CONFIG0_ID} | grep "IPAddress" | cut -d':' -f2 | cut -d'"' -f2)
echo "Your config container ${CONFIG0_ID} listen on ip: ${CONFIG0_IP} (waiting that becomes ready)"

until sudo docker logs ${CONFIG0_ID} | grep "waiting for connections on port" >/dev/null;
do
    sleep 2
done

echo "The config is available now..."

MONGOS0_ID=$(sudo docker run -p $PORT_1:$PORT_1 -d ankurcha/tokumx mongos --configdb ${CONFIG0_IP}:$PORT --logpath /dev/stdout --bind_ip 0.0.0.0 --port $PORT_1)
MONGOS0_IP=$(sudo docker inspect ${MONGOS0_ID} | grep "IPAddress" | cut -d':' -f2 | cut -d'"' -f2)
echo "Contacting shard and mongod containers"

until sudo docker logs ${MONGOS0_ID} | grep "config servers and shards contacted successfully" >/dev/null;
do
    sleep 2
done

# Add the shard
mongo ${MONGOS0_IP}:$PORT_1 --eval "sh.addShard(\"rs0/${SHARD00_IP}:$PORT\");"

echo "OK, you can connect to mongos using: "
echo "mongo ${MONGOS0_IP}:$PORT_1"

