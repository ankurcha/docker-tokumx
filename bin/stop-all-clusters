#!/bin/bash

set -e

if sudo docker ps | grep "ankurcha/tokumx" >/dev/null; then
    sudo docker ps | grep "ankurcha/tokumx" | awk '{ print $1 }' | xargs -r sudo docker stop >/dev/null
    echo "Stopped the cluster and cleared all of the running containers."
fi
