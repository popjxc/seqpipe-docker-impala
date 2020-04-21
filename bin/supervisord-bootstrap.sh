#!/bin/bash

rm /etc/ssh/*key* 2> /dev/null
rm /root/.ssh/id_rsa 2> /dev/null

ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

rm -f /tmp/zookeeper 2> /dev/null

supervisorctl start sshd
/wait-for-it.sh localhost:22 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n--------------------------------------------"
    echo -e "      SSHD not ready! Exiting..."
    echo -e "--------------------------------------------"
    exit $rc
fi

supervisorctl start zookeeper


/wait-for-it.sh localhost:2181 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n--------------------------------------------"
    echo -e "      Zookeeper not ready! Exiting..."
    echo -e "--------------------------------------------"
    exit $rc
fi

mkdir -p /data/dn/
chown hdfs:hadoop -R /data/dn

/start-hdfs.sh

echo -e "\n\n--------------------------------------------------------------------------------"
echo -e "You can now access to the following Hadoop Web UIs:"
echo -e ""
echo -e "Hadoop - NameNode:                     http://impala:9870"
echo -e "Hadoop - DataNode:                     http://impala:9864"
echo -e "--------------------------------------------------------------------------------\n\n"



supervisorctl start postgresql

/wait-for-it.sh localhost:5432 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n--------------------------------------------"
    echo -e "      PostgreSQL not ready! Exiting..."
    echo -e "--------------------------------------------"
	exit $rc
fi

# psql -h localhost -U postgres -c "CREATE DATABASE metastore;"

export COUNT=0

while :
do
    export COUNT=COUNT+1
    sleep 2

    export RESULT=$(psql -h localhost -U postgres -c "CREATE DATABASE metastore;" 2>&1)

    if [[ ($RESULT =~ "already exists") || ($RESULT =~ "CREATE DATABASE") ]]; then
            echo "DONE: database 'metastore' exists"
            break
    else
            echo "ERROR: database 'metastore' not created"
            export DONE=0
    fi

    if [[ $COUNT > 10 ]];
    then
            echo -e "\n\n--------------------------------------------------------------------------------"
            echo -e "ERROR: Can't init Hive Metastore"
            echo -e "--------------------------------------------------------------------------------\n\n"
            exit 1
    fi
done

$HIVE_HOME/bin/schematool -dbType postgres -initSchema

mkdir -p /opt/hive/hcatalog/var/log

supervisorctl start hive_metastore

/wait-for-it.sh localhost:9083 -t 240

psql -h localhost -U postgres -d metastore -a -f /fix_default_location.sql

supervisorctl restart hive_metastore

/wait-for-it.sh localhost:9083 -t 240

rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n---------------------------------------"
    echo -e "  Hive Metastore not ready! Exiting..."
    echo -e "---------------------------------------"
    exit 1
fi

echo -e "\n\n--------------------------------------------------------------------------------"
echo -e "Hive Metastore running on localhost:9083"
echo -e "--------------------------------------------------------------------------------\n\n"

/start-impala.sh
