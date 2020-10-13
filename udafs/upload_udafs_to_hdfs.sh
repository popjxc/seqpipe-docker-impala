#!/bin/bash

hdfs dfs -rm -f /user/hive/udafs/libgpfuda.so
hdfs dfs -mkdir -p /user/hive/udafs
hdfs dfs -put /udafs/build/libgpfuda.so /user/hive/udafs/libgpfuda.so
