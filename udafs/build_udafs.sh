#!/bin/bash

rm -rf /udafs
git clone https://github.com/seqpipe/gpf-impala-udafs.git /udafs
cd /udafs
cmake .
make
