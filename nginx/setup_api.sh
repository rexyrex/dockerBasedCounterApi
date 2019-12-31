#!/bin/bash
source ../server_ip.config
COUNT=$1

rm default.conf

cat <<EOF >> default.conf
upstream backend{
EOF

for i in $(seq 1 $COUNT)
do
cat <<EOF >> default.conf
    server ${MY_IP}:300$i;
EOF
done

cat <<EOF >> default.conf
}
server {
    listen 80;
    include /etc/nginx/mime.types;

    location / {
        proxy_pass 'http://backend';
    }
}	
EOF

if [ ${COUNT} -eq '0' ];
then
docker rm $(docker stop $(docker ps -a -q --filter ancestor=counter:v1 --format="{{.ID}}"))
docker rm --force nginx
else
docker run --name nginx -v ${PWD}/default.conf:/etc/nginx/conf.d/default.conf -d -p 80:80 nginx:latest
fi

for i in $(seq 1 $COUNT)
do
docker run --name host${i} -e 'HOSTNUM'=${i} -e 'COUNTERIP'=${MY_IP} -d -p 300${i}:3000 counter:v1
done
