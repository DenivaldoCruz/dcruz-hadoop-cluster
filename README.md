Hadoop cluster using Docker
==========
This repository contains Docker file to build a Docker image with Hadoop, Spark, HBase, Hive, Zookeeper and Kafka. The accompanying scripts can be used to start and stop the clusters easily.

## Pull the image

The image is released as an official Docker image from Docker's automated build repository - you can always pull or refer the image when launching containers.
```
docker pull denivaldocruz/hadoop_cluster
```

## Build the image

If you would like to try directly from the Dockerfile you can build the image as:
```
docker build --rm --no-cache -t denivaldocruz/hadoop_cluster .
```

# Create network, containers and start cluster

## Through script
You can use the start_cluster.sh and stop_cluster.sh scripts to start and stop the hadoop cluster using bash or Windows Powershell.
* Default is 1 namenode with 2 datanodes (upto 8 datanodes currently possible, to add more edit "/usr/local/hadoop/etc/hadoop/slaves" and restart the cluster)
* Each node takes 1GB memory and 2 virtual cpu cores
```
sh start_cluster.sh 2
sh stop_cluster.sh
```
## Manual procedure
### Create bridge network
```
docker network create --driver bridge hadoop
```
### Create and start containers
Create a namenode container with the Docker image you have just built or pulled
```
docker create -it -p 8088:8088 -p 50070:50070 -p 50075:50075 -p 2122:2122  --net hadoop --name namenode --hostname namenode --memory 1024m --cpus 2 denivaldocruz/hadoop_cluster
```
Create and start datanode containers with the Docker image you have just built or pulled (upto 8 datanodes currently possible, to add more edit "/usr/local/hadoop/etc/hadoop/slaves" and restart the cluster)
```
docker run -itd --name datanode1 --net hadoop --hostname datanode1 --memory 1024m --cpus 2 denivaldocruz/hadoop_cluster
docker run -itd --name datanode2 --net hadoop --hostname datanode2 --memory 1024m --cpus 2 denivaldocruz/hadoop_cluster
...
```
Start namenode container
```
docker start namenode
```
### Start cluster
```
docker exec -it namenode //etc//bootstrap.sh start_cluster
```

After few minutes, you should be able to view Resource Manager UI at

http://<host>:8088

You should be able to access the HDFS UI at

http://<host>:50070

## Credentials
You can connect through SSH and SFTP clients to the namenode of the cluster using port 2122
```
Username: hdpuser
Password: hdppassword
```

### Miscellaneous information
* You can login as root user into namenode using "docker exec -it namenode bash"
* To start HBase manually, log in as root (as described above) and executing the command "$HBASE_HOME/bin/start-hbase.sh"
* To start Kafka manually, log in as root (as described above) and executing the command "$KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties"
* Kafka topics can be created by "hdpuser" with root priviledges
```
sudo $KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper namenode:2181 --replication-factor 1 --partitions 1 --topic test

$KAFKA_HOME/bin/kafka-topics.sh --create --zookeeper namenode:2181 --replication-factor 1 --partitions 3 --topic msgtopic

$KAFKA_HOME/bin/kafka-console-producer.sh --create --broker-list namenode:9092 --topic msgtopic

$KAFKA_HOME/bin/kafka-console-consumer.sh –bootstrap-server namenode:9092 --topic msgtopic --from-beginning
```

### Known issues
* Spark application master is not reachable from host system
* HBase and Kafka services do not start automatically sometimes (increasing memory of the container might solve this issue)
* No proper PySpark setup
* Unable to get Hive to work on Tez (current default MapReduce)

# Credits
* SequenceIQ - [https://github.com/sequenceiq](https://github.com/sequenceiq)
* Luciano Resende - [https://github.com/lresende](https://github.com/lresende)
# dcruz-hadoop-cluster
