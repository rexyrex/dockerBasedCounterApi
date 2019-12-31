source ../server_ip.config
for x in $(curl -s http://$MY_IP/counter/); 
do
     curl -s http://$MY_IP/counter/${x}/ 
done
