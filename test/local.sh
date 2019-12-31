for x in `seq 1 15`; do 
    curl -X POST "http://localhost:3000/counter/?to=$(((RANDOM%1000)+1000))"; 
done
