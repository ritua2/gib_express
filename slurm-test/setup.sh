# Changes to the original setup
git clone https://github.com/giovtorres/docker-centos7-slurm
cat docker-compose.yml > docker-centos7-slurm/docker-compose.yml

cat Dockerfile > docker-centos7-slurm/Dockerfile
cat docker-entrypoint.sh > docker-centos7-slurm/docker-entrypoint.sh

mv json_parser.py docker-centos7-slurm/json_parser.py

cd docker-centos7-slurm

# Needed environmental variables
printf "Enter middle layer IP (without http://): "
read CONDUCTOR_IP
printf "Enter orchestration password: "
read CONDUCTOR_PASSWORD
printf "Enter output data path: "
read ODP

# Creates the necessary volumes
docker volume create --name=lib
docker volume create --name=spool
docker volume create --name=log
docker volume create --name=db

# Starts the docker containers
CONDUCTOR_IP="$CONDUCTOR_IP"  CONDUCTOR_PASSWORD="$CONDUCTOR_PASSWORD" output_data_path="$ODP" docker-compose up -d --build
cd ..
