#!/bin/bash

supervisorctl start impala-state-store
/wait-for-it.sh impala:25010 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n---------------------------------------"
    echo -e "     Impala statestore not ready! Exiting..."
    echo -e "---------------------------------------"
    exit $rc
fi

supervisorctl start impala-catalog
/wait-for-it.sh impala:25020 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n---------------------------------------"
    echo -e "     Impala catalog not ready! Exiting..."
    echo -e "---------------------------------------"
    exit $rc
fi

supervisorctl start impala-server

/wait-for-it.sh impala:21000 -t 120
/wait-for-it.sh impala:22000 -t 120
/wait-for-it.sh impala:21050 -t 120
/wait-for-it.sh impala:25000 -t 120
rc=$?
if [ $rc -ne 0 ]; then
    echo -e "\n---------------------------------------"
    echo -e "     Impala not ready! Exiting..."
    echo -e "---------------------------------------"
    exit $rc
fi

echo -e "\n\n--------------------------------------------------------------------------------"
echo -e "You can now access to the following Impala UIs:\n"
echo -e "Impala Server           http://impala:25000"
echo -e "Impala State Store      http://impala:25010"
echo -e "Impala Catalog          http://impala:25020"
echo -e "--------------------------------------------------------------------------------\n\n"
