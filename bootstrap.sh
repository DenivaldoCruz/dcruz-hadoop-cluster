#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm -f /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

service mysqld start
service sshd start


if [ $1 = "start_cluster" ]; then
  $ZOOKEEPER_HOME/bin/zkServer.sh start
  $HADOOP_PREFIX/sbin/start-dfs.sh
  $HADOOP_PREFIX/sbin/start-yarn.sh
  hdfs dfs -test -d /spark
  if [ $? != 0 ]; then
    echo "Adding spark libraries to hdfs..."
    $HADOOP_HOME/bin/hdfs dfs -put $SPARK_HOME/jars /spark
  fi
  hdfs dfs -test -d /tmp
  if [ $? != 0 ]; then
    echo "Creating tmp directory on hdfs..."
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /tmp/logs/hdpuser/logs
    $HADOOP_HOME/bin/hdfs dfs -chmod -R 777 /tmp
    $HADOOP_HOME/bin/hdfs dfs -chown hdpuser /tmp/logs/hdpuser
  fi
  hdfs dfs -test -d /hbase
  if [ $? != 0 ]; then
    echo "Creating hbase directory on hdfs..."
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /hbase
  fi
  hdfs dfs -test -d /apps
  if [ $? != 0 ]; then
    echo "Creating tez directory and copying libraries on hdfs..."
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /apps/tez
    $HADOOP_HOME/bin/hdfs dfs -put $TEZ_HOME/* /apps/tez/
    $HADOOP_HOME/bin/hdfs dfs -chmod -R 755 /apps/tez
  fi
  hdfs dfs -test -d /user
  if [ $? != 0 ]; then
    echo "Creating user directories on hdfs..."
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/root
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hdpuser
    $HADOOP_HOME/bin/hdfs dfs -mkdir -p /user/hive/warehouse
    $HADOOP_HOME/bin/hdfs dfs -chown hdpuser /user/hdpuser
    $HADOOP_HOME/bin/hdfs dfs -chown root /user/root
    $HADOOP_HOME/bin/hdfs dfs -chmod 777 /user/hive/warehouse
    echo "Setting up hive metastore on MySQL..."
    cd $HIVE_HOME/scripts/metastore/upgrade/mysql/
    service mysqld restart
    mysql -u root -e 'CREATE DATABASE metastore_db;'
    mysql -u root -e "USE metastore_db; CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';"
    mysql -u root -e "USE metastore_db; GRANT all on metastore_db.* to 'hiveuser'@'%' identified by 'hivepassword';"
    mysql -u root -e "USE metastore_db; GRANT all on metastore_db to 'hiveuser'@'%' identified by 'hivepassword';"
    mysql -u root -e "USE metastore_db; CREATE USER 'hiveuser'@'namenode' IDENTIFIED BY 'hivepassword';"
    mysql -u root -e "USE metastore_db; GRANT all on metastore_db.* to 'hiveuser'@'namenode' identified by 'hivepassword';"
    mysql -u root -e "USE metastore_db; GRANT all on metastore_db to 'hiveuser'@'namenode' identified by 'hivepassword';"
    mysql -u root -e "USE metastore_db; flush privileges;"
    mysql -u root -e "USE metastore_db; SOURCE $HIVE_HOME/scripts/metastore/upgrade/mysql/hive-schema-2.3.0.mysql.sql;"
  fi
  $HBASE_HOME/bin/start-hbase.sh
  $KAFKA_HOME/bin/kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
fi

if [ $1 = "stop_cluster" ]; then
  $KAFKA_HOME/bin/kafka-server-stop.sh
  $HBASE_HOME/bin/stop-hbase.sh
  $HADOOP_PREFIX/sbin/stop-yarn.sh
  $HADOOP_PREFIX/sbin/stop-dfs.sh
  $ZOOKEEPER_HOME/bin/zkServer.sh stop
fi

if [[ $1 = "-d" || $2 = "-d" ]]; then
  while true; do sleep 1000; done
fi