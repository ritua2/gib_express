read -p "Enter GIB URL/IP: " conductor
read -p "Enter orchestra key: " okey
read -p "Enter number of wetty terminals to run: " noc
if [[ ! $noc =~ ^[0-9]+$ ]] ; then
	echo "Invalid number for terminals to run"
	exit
fi
if [ $noc -lt 1 ] || [ $noc -gt 6 ] ; then
	echo "Number of terminals must be betweeen 1 and 6"
	exit
fi

cd ./new-wetty

# ssh server
docker build -f Dockerfile.ssh -t easy_wetty/ssh:latest .

# Wetty image
docker build -f Dockerfile.wetty -t easy_wetty/standalone:latest .

# Create shared volume for rsync
docker volume create --name=rsync_data

docker run -d -e conductor="$conductor" -e orchestra_key="$okey" -p 4646:22 -v rsync_data:/home/rsync_user/data easy_wetty/ssh

count=0
while [ $count -lt $noc ]
do
	port=7000 
	port=$(($port+$count))
	miniport=100
	miniport=$(($port+$miniport))
	name=w$count
	
	docker run -d -e conductor="$conductor" -e orchestra_key="$okey" -p $port:3000 -p $miniport:3100 -v rsync_data:/gib/global/data --name "$name" easy_wetty/standalone main_daemon
	count=$(( $count + 1 ))
done

