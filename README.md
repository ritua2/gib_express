# Gateway-In-a-Box (GIB)
Gateway-In-a-Box: A Portable Solution for Developing Science Gateways that Support Interactive and Batch Computing Modes. 

GIB is a reusable and a portable framework for building web portals that support computation and analyses on remote computing resources from the convenience of the web-browser. It is mainly written in Java/Java EE. It provides support for an interactive terminal emulator, batch job submission, file management, storage-quota management, message board, user account management, and also provides an admin console. GIB can be easily deployed on the resources in the cloud or on-premises.

-----------------

## Instructions

* **Installing the front-end and middle layer**

The process may take up to six minutes, particularly the tomcat_springipt container.

The middle-layer contains:
1. Manager node
2. Greyfish, cloud storage. More information about greyfish can be obtained on its README, both for [this project](https://github.com/ritua2/gib/tree/master/middle-layer/greyfish_storage) or in its [original repository](https://github.com/noderod/greyfish).


```bash
# Download the git repository
git clone https://github.com/ritua2/gib

# Create the necessary volumes
docker volume create --name=myvol
docker volume create --name=greyfish

# Modify the environment variables for the middle layer
# The variale values  are used for setting up the credentails and using them later
cd gib/middle-layer

vi .env
# Set the values of the following variables as per your choice in the .env file.

orchestra_key=orchestra
URL_BASE=127.0.0.1
REDIS_AUTH=redpassword
MYSQL_ROOT_PASSWORD=Root_Password
MYSQL_USER=Create_User_Name
MYSQL_PASSWORD=Your_password
MYSQL_SERVER=IP_ADDRESS
greyfish_key=greyfish
SENDER_EMAIL=a@example.com
SENDER_EMAIL_PASSWORD=a1



# Copy the environment variables file to springIPT directory
cp .env ../springipt/envar.txt
cp .env ../springipt/.env

# Only change the values of <IPaddress> <portnumber>(generally 6603) and <databasename>(same to MYSQL_DATABASE variable) in the .env files above.

#MYSQL_CONN_URL=jdbc:mysql://<IPaddress>:<portnumber>/<databasename>?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=CONVERT_TO_NULL


# Modify the springIPT variables to be the same as above, including the VM IP
vi ../springipt/src/main/resources/application.properties
  

# Start the middle layer
# if not already in the directory named middle-layer then switch to it - uncomment the command below
#cd middle-layer
docker-compose up -d

# Enter manager node container
docker exec -it manager_node bash

# If first time, generate an ssh key to allow rsync
ssh-keygen -t rsa -N ""  -f rsync_wetty.key

# Activate (change the number of threads if needed with the -w flag, defined in .env)
gunicorn -w $gthreads -b 0.0.0.0:5000 traffic:app &

# Leave container
exit

# Enter greyfish (storage) container
docker exec -it greyfish bash
cd /grey
# Activate the APIs (change the number of threads if needed, standard is 4)
./API_Daemon.sh -up

# Leave container
exit


# Start springIPT and MySQL containers
cd ../springipt

# Edit DB settings
vi initdb/start.sql

# Replace original <db_user> with value for environment variable: MYSQL_USER and <DB user's Password> with value for environment variable:  MYSQL_PASSWORD

# Edit LDAP settings
vi src/main/webapp/WEB-INF/appconfig-security.xml

# Edit tag <authentication-manager>
# Edit "user-dn-pattern" attribute of tag <ldap-authentication-provider>
# Edit "url", "manager-dn" and "password" attributes of tag <ldap-server> with correct LDAP server IP, port and dn pattern

# Edit docker-compose.yml by replacing values of tags enclosed by {} in services:web:volumes... e.g {LOCAL_ENVAR}->./envar.txt
vi docker-compose.yml

# Edit the values of keystoreFile(<connecter port=8443>) and keystorePass(<connecter port=8443>) in server.xml by removing values enclosed with "<>" and update it later after installing secure version of SpringIPT
vi server.xml

# Install Maven if not already installed, then execute maven build 
mvn clean package

# if rebuilding: docker kill tomcat_springipt; docker rm tomcat_springipt
docker-compose up -d --build
```

* **Installing secure version of SpringIPT**

```bash

#Enter IPT container
docker exec -it tomcat_springipt bash

#Generate Keystore, change the variable <keystore> as per your choice
$JAVA_HOME/bin/keytool -genkey -alias tomcat -keyalg RSA -keystore <keystore>

#Create password for keystore and enter the details as required.
#Verify the deatils and enter 'yes'
#Press "Enter/Return" when asked for password again

#Exit the container
exit

#Pull generated keystore file from container
docker cp tomcat_springipt:/usr/local/tomcat/<keystore> .

#Change server.xml
vi server.xml

#Change the following values: <path and name of keystore file>, <password>(with password of generated keystore file)
<Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
               maxThreads="150" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS" 
	       keystoreFile="/usr/local/tomcat/<path and name of keystore file>"
	       keystorePass="<password>" />
		   
#Edit docker-compose.yml file to add keystore file and edited server.xml
vi docker-compose.yml

#Add the following lines after line #20, take care of indentation.
- ./keystore:/usr/local/tomcat/keystore
- ./server.xml:/usr/local/tomcat/conf/server.xml

# Bring down the running containers
docker-compose down -v

# Rebuild the containers
docker-compose up -d --build
```



* **Installing the wetty terminal**

Notes:

This should be done on a different VM than the one on which the middle-layer and front-end are installed.

*conductor* refers to the IP or URL (without http://, https://, or the ending /) where springIPT is located at.

*orchestra_key* refers to the manager's node key, declared in gib/middle-layer/.env


1. Build the wetty and ssh server images
```bash
git clone https://github.com/ritua2/gib

cd gib/new-wetty

# ssh server
docker build -f Dockerfile.ssh -t easy_wetty/ssh:latest .
# Wetty image
docker build -f Dockerfile.wetty -t easy_wetty/standalone:latest .
```


2. Start the ssh server for a temporary volume for local storage

```bash
# Create shared volume for rsync
docker volume create --name=rsync_data

# Start image
docker run -d -e conductor="example.com" -e orchestra_key="orchestra" -p 4646:22 -v rsync_data:/home/rsync_user/data easy_wetty/ssh
```



3. Wetty startup

Requires the ssh server to be setup beforehand


```bash
docker run -d -e conductor="example.com" -e orchestra_key="orchestra" -p 7005:3000 -p 7105:3100 -v rsync_data:/gib/global/data easy_wetty/standalone main_daemon
```

4. Run the commands below to start 6 instances of the Wetty container on the VM (each VM will support 6 Wetty instances - additional Wetty instances for this project could be provisioned on new VMs - Docker Swarm cluster)

```
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7000:3000 -p 7100:3100 -v rsync_data:/gib/global/data --name w0 easy_wetty/standalone main_daemon
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7001:3000 -p 7101:3100 -v rsync_data:/gib/global/data --name w1 easy_wetty/standalone main_daemon
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7002:3000 -p 7102:3100 -v rsync_data:/gib/global/data --name w2 easy_wetty/standalone main_daemon
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7003:3000 -p 7103:3100 -v rsync_data:/gib/global/data --name w3 easy_wetty/standalone main_daemon
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7004:3000 -p 7104:3100 -v rsync_data:/gib/global/data --name w4 easy_wetty/standalone main_daemon
docker run -d -e conductor="IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7005:3000 -p 7105:3100 -v rsync_data:/gib/global/data --name w5 easy_wetty/standalone main_daemon
```



* **Testing the installation**
The front-end would be accessible at the IP address associated with the VM on which the installation was done as shown below:
http://IPAddress:9090/



* **Removing the gib containers**

To kill and remove the gib containers, except wetty instances:
```bash
docker kill manager_node && docker rm manager_node
docker kill redis && docker rm redis
docker kill greyfish && docker rm greyfish
docker kill tomcat_springipt && docker rm tomcat_springipt
docker kill mysql_springipt && docker rm mysql_springipt
```



If all the containers belong to gib:
```bash
docker kill $(docker ps -aq) && docker rm $(docker ps -aq)
```



* **Receiving Jobs**

GIB will run user jobs in a supercomputer with the Slurm scheduler. In order to take advantage of this, execute the following commands from the supercomputer
to set up the necessary directories and environmental variables
```bash
git clone https://github.com/ritua2/gib
cd Backend

# Mofidy the .env file with data corresponding to GIB, supercomputer user information (username and allocation name), etc.
# sc_server: Stampede2/Lonestar5/Comet
# execution_directory: Directory in which jobs are run and temporarily stored
vi .env

chmod +x iter2-backend.sh
chmod +x delete_run_jobs.sh
```

Requests available jobs from the server (may also run as a cron job):
```bash
./iter2-backend.sh
```

Delete data corresponding to jobs already run (may be run as a cron job):
```bash
./delete_run_jobs.sh
```


NB: As of right now, GIB only supports Stampede2, Lonestar5 (Texas Advanced Computing Center), and Comet (San Diego Supercomputer Center).

