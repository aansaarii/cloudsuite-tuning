docker stats > log.txt &
ID=$!
echo "ID is $ID"
sleep 15
pkill "docker-current" 
echo "kill called"
sleep 10
