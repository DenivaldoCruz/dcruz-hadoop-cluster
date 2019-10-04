#!/bin/bash

# the default node number is 2
N=${1:-2}

# Stop namenode container
echo "Check existing namenode container..."
if docker container ls -a | grep -q 'namenode'; then
    echo "Stopping cluster..."
    docker exec -it namenode //etc//bootstrap.sh stop_cluster
    echo "Stopping namenode container..."
    docker stop namenode
fi

# Stopping hadoop slave containers
echo 'Stopping datanode containers...'
docker stop $(docker container ls -a | grep 'datanode[1-8]' | awk '{print $1}')

echo 'All containers stopped'
