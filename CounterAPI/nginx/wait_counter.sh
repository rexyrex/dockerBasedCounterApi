source ../server_ip.config

while true;
do
COUNT=$(curl http://$MY_IP/counterCount/)
echo "Counters left: $COUNT"
if [ ${COUNT} -eq '0' ];
then
break;
fi
sleep 1;
done
