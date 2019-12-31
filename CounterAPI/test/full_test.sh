#!/bin/bash 
source ../server_ip.config



echo "Delete all docker containers for fresh start? (y/n) "
read delDocs

if [ "$delDocs" == 'y' ]
then
./eraseAll.sh
fi

cd ../apiServer
echo "Creating Counter API Server Docker..."
docker build --tag counter:v1 .

cd ../test
./init.sh
sleep 2
clear
echo "step 1: 3 hosts"
for x in `seq 1 100`; do curl -s http://$MY_IP/ ; done | sort | uniq
sleep 3
clear

echo "step 2,3 running..."
sleep 2
./clearRedis.sh
cd ../nginx
echo "running create_counter.sh"
./create_counter.sh
echo "running list_counter.sh"
./list_counter.sh
echo "running list_counter.sh | wc -l (Expecting 100 counters)"
if [ $(./list_counter.sh | wc -l) -eq '100' ];
then
echo "counter count==100. Test Successful"
else
echo "Test Failed"
fi
sleep 3
clear

echo "Step 4: reducing api app server count to 0"
./setup_api.sh 0
sleep 4 
echo "Increasing back to 5 and executing step 3"
./setup_api.sh 5
sleep 4
for x in `seq 1 100`; do curl -s http://$MY_IP/ ; done | sort | uniq
sleep 4
echo "./list_counter.sh | wc -l"
if [ $(./list_counter.sh | wc -l) -eq '100' ];
then
echo "counter count==100. Test Successful"
else
echo "Test Failed"
fi
cd ../test
./clearRedis.sh
cd ../nginx
sleep 2
clear

echo "Step 5: create and delete counters"
echo "Creating..."
sleep 2
./create_counter.sh
echo "Counter count:"
./list_counter.sh | wc -l

echo "Deleting..."
for x in $(curl -s http://$MY_IP/counter/); do curl -X POST http://$MY_IP/counter/${x}/stop/ ; done
sleep 5
echo "Checking counters left..."
if [ $(./list_counter.sh | wc -l) -eq '0' ];
then
echo "0 Counters remaining. Test Successful"
else
echo "Test Failed"
fi
sleep 2
clear

echo "Step 6: wait_counter.sh"
sleep 2
cd ../test
./clearRedis.sh
cd ../nginx
echo "Creating 100 Counters"
sleep 2
./create_counter.sh
echo "Waiting for all counters to expire..."
sleep 2
clear
./wait_counter.sh

