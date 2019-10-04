#!/bin/bash

# the default node number is 2
N=${1:-2}

tag="latest"
if [ ! -z "$2" ]
  then
	tag=$2 
fi

echo "Checking Docker network..."
if  ! docker network ls | grep -q 'hadoop'; then
    echo "Creating Docker network..."
    docker network create --driver bridge hadoop
else
    echo "Hadoop network exists"
fi

# Create namenode container
echo "Check existing namenode container..."
if  ! docker container ls -a | grep -q 'namenode'; then
    echo "Creating namenode container..."
    docker create -it -p 8088:8088 -p 4040:4040 -p 50070:50070 -p 50075:50075 -p 2122:2122 --net hadoop --name namenode --hostname namenode --memory 1024m --cpus 2 denivaldocruz/hadoop_cluster:$tag
else
    echo "Namenode container exists"
fi

# Create [if does not exist] and start hadoop slave containers
for i in $(seq 1 $N)
do
    # Create datanode container
    echo "Check existing datanode$i container..."
    if  ! docker container ls -a | grep -q "datanode$i"; then
        echo "Creating and starting datanode$i container..."
        docker run -itd --name datanode$i --net hadoop --hostname datanode$i --memory 1024m --cpus 2 denivaldocruz/hadoop_cluster:$tag
    else
        echo "Starting datanode$i container"
        docker start datanode$i
    fi
done

echo "Starting namenode container..."
docker start namenode
echo "Starting hadoop cluster..."
docker exec -it namenode //etc//bootstrap.sh start_cluster

echo "You can check Resource Manager UI at <DOCKER_HOST>:8088 and HDFS UI at <DOCKER_HOST>:50070"
echo "You can login using any SSH and SFTP client on port 2122 using username 'hdpuser' and password 'hdppassword'"
