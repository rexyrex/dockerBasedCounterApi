for x in $(curl -s http://localhost:3000/counter/); 
do
     curl -s http://localhost:3000/counter/${x}/ 
done
