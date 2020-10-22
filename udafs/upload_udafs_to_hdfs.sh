#!/bin/bash

hdfs dfs -rm -f /user/hive/udafs/libgpfuda.so
sleep 3
hdfs dfs -mkdir -p /user/hive/udafs
sleep 3
hdfs dfs -put /udafs/build/libgpfuda.so /user/hive/udafs/libgpfuda.so
