docker volume create --name=myvol
docker volume create --name=greyfish
cp ./middle-layer/.env ./springipt/envar.txt
cp ./middle-layer/.env ./springipt/.env
cd ./middle-layer/
docker-compose up -d
docker exec -itd manager_node /bin/bash -c "ssh-keygen -t rsa -N newpass  -f rsync_wetty.key; gunicorn -w \$gthreads -b 0.0.0.0:5000 traffic:app \&; exit;"
docker exec -itd greyfish /bin/bash -c "cd \/grey; \/grey\/API_Daemon.sh \-up;sleep 10;"
cd ../springipt
apt install maven
mvn clean package
docker-compose up -d --build
docker exec -it tomcat_springipt /bin/bash -c "rm \-rf keystore; sleep 5; \$JAVA_HOME\/bin\/keytool \-genkey \-alias tomcat \-keyalg RSA \-keystore keystore; echo \"out of springipt after generating key \"; exit"
rm -rf keystore;
docker cp tomcat_springipt:/usr/local/tomcat/keystore .
echo "Copied the keystore"
docker-compose down -v
