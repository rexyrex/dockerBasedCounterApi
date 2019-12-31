source ../server_ip.config
for x in `seq 1 100`; do 
    curl -X POST "http://"{$MY_IP}"/counter/?to=$(((RANDOM%1000)+1000))"; 
done
