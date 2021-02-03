# Gateway-In-a-Box (GIB)
Gateway-In-a-Box: A Portable Solution for Developing Science Gateways that Support Interactive and Batch Computing Modes. 

GIB is a reusable and a portable framework for building web portals that support computation and analyses on remote computing resources from the convenience of the web-browser. It is mainly written in Java/Java EE. It provides support for an interactive terminal emulator, batch job submission, file management, storage-quota management, message board, user account management, and also provides an admin console. GIB can be easily deployed on the resources in the cloud or on-premises. 

GIB is derived from the software funded by NSF awards # 1642396 and 2039142 - some of the deliverables associated with both these awards involved the development of the web-portals/science gateways with features such as persistent cloud-based storage, file/folder management, and discussion forums. 

Here is a video-demo of a raw (not secured with SSL certificates) instance of GIB that is fully-customizable:

https://youtu.be/AImrskhIrVw

Installation videos:

Step 1: https://www.youtube.com/watch?v=nWyZgWAy0Ag

Step 2: https://www.youtube.com/watch?v=so1tQQYUFZY

Thanks to the National Science Foundation (NSF) for awards # 1642396 and #2039142 - these awards supported products from which GIB has been derived.

## License
Copyright (c) 2021, The University of Texas at San Antonio
Copyright (c) 2021, Ritu Arora
 
All rights reserved. 
 
Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:    
* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.    
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.     
* Neither the name of the organizations (The University of Texas at San Antonio) nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission. 

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL RITU ARORA BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


## Instructions

* **Installing the front-end and middle layer**

The process may take up to six minutes, particularly the tomcat_springipt container.

The middle-layer contains:
1. Manager node
2. Greyfish, cloud storage. More information about greyfish can be obtained on its README, both for [this project](https://github.com/ritua2/gib/tree/master/middle-layer/greyfish_storage) or in its [original repository](https://github.com/noderod/greyfish).


```bash
# If not running as root, become root first
sudo su -

# Download the git repository
git clone https://github.com/ritua2/gib_express.git

# Change the directory to the setup script
cd gib_express

# Modify the environment variables for the middle layer
# The variale values  are used for setting up the credentails and using them later
vi middle-layer/.env

# Set the values of the following variables as per your choice in the .env file.          
# Mysql will be set with default credentials defined in three lines below. If user would like to change it, update credentials here now and update the relavent values in start.sql after updating this(.env) file
MYSQL_ROOT_PASSWORD=password
MYSQL_USER=iptuser
MYSQL_PASSWORD=password
orchestra_key=orchestra
URL_BASE=127.0.0.1
greyfish_key=greyfish
SENDER_EMAIL=a@example.com
SENDER_EMAIL_PASSWORD=a1
# Replace ${URL_BASE} with the value of URL_BASE set above
MYSQL_CONN_URL=jdbc:mysql://${URL_BASE}:6603/iptweb?useUnicode=true&characterEncoding=UTF-8&zeroDateTimeBehavior=CONVERT_TO_NULL
# Save the changes and update the start.sql file if needed using "vi springipt/initdb/start.sql" command

# Update client_id, redirect_uri, scope under login_cilogon function and client_id, client_secret, scope under welcome function according to your CILogon registration details
vi springipt/src/main/java/com/ipt/web/controller/LoginUserController.java

# Make the setup script executable
chmod +x gib_setup.sh

# Run the script
./gib_setup.sh

# While executing trhe script, it will propmpt for password. user can type "password" to match with default configuration and fill out other details
# If user would like to set different password, then type it on the prompt and update "password" in below tag inside server.xml with "vi springipt/server.xml" command after script finishes execution
<Connector port="8443" protocol="HTTP/1.1" SSLEnabled="true"
               maxThreads="150" scheme="https" secure="true"
               clientAuth="false" sslProtocol="TLS" 
	       keystoreFile="/usr/local/tomcat/keystore"
	       keystorePass="password" />

# Go to the springipt directory
cd springipt

# Edit docker-compose.yml by removing '#' from line "#- ./keystore:/usr/local/tomcat/keystore"
vi docker-compose.yml

# rebuild the containers
docker-compose up -d --build

# Access the application by visiting following link in browser after few minutes, replace URL_BASE with it's value from .env file'
https://URL_BASE:8443
```


* **Installing the wetty terminal**

Notes:

Wetty should be installed on the different VMs than the one on which the middle-layer and front-end are installed.
To setup Wetty with Docker Swarm cluster, at least two VMs are required for the Wetty cluster. There will be two types of nodes in the cluster:

1. Manager Node – Pick any VM as manager node
2. Worker Node – all other VMs except manager node will act as worker nodes

In total, a minimum of three VMs are needed - one for the front-end and the middle-layer, and the other two VMs for the Wetty containers.

*manager_node_ip* refers to the manager node VM’s IP address

*conductor* refers to the IP or URL (without http://, https://, or the ending /) where springIPT is located at.

*orchestra_key* refers to the manager's node key, declared in gib/middle-layer/.env


1. On the manager node, initiate Docker swarm and create volume for local storage.

```bash
# Initiate docker swarm on manager node and copy the docker swarm join command appeared on the console after execution
docker swarm init --advertise-addr manager_node_ip

# Create shared volume for rsync on manager node
docker volume create --name=rsync_data
```


2. Add all worker nodes to the docker swarm cluster using swarm join command.

```bash
# Sample docker swarm join command shown below. Execute the copied command in step 1(generated after executing docker swarm init) on each worker node. 
docker swarm join --token SWMTKN-1-09qr5nh49km67h2b30p84jqwqyxpap3mnivk0b4dbj9x7av70s-bz6a00c5cwlht10h3sye9n12y manager_node_ip:2377
```



3. On manager node, start ssh server first and then startup wetty. Starting any container on manager node will replicate it on all of the nodes in swarm cluster.

```bash
# Start ssh server on manager node
docker service create -d --name "ssh-wetty" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 4646:22 --mount src=rsync_data,dst=/home/rsync_user/data saumyashah/swarm_easy_wetty_ssh

# Wetty startup on manager node
docker service create -d --name "w0" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7000:3000 -p 7100:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
docker service create -d --name "w1" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7001:3000 -p 7101:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
docker service create -d --name "w2" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7002:3000 -p 7102:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
docker service create -d --name "w3" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7003:3000 -p 7103:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
docker service create -d --name "w4" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7004:3000 -p 7104:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
docker service create -d --name "w5" --mode global -e conductor=" IP_ADDRESS_OF_SPRINGIPT" -e orchestra_key="orchestra" -p 7005:3000 -p 7105:3100 --mount src=rsync_data,dst=/gib/global/data saumyashah/swarm_easy_wetty_standalone main_daemon
```



* **Testing the installation**
The front-end would be accessible at the IP address associated with the VM on which the installation was done as shown below:
http://IPAddress:8443/



* **Removing the gib containers**

To kill and remove the gib containers, except wetty instances:
```bash
docker kill manager_node && docker rm manager_node
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


NB: By default GIB supports Stampede2, Lonestar5 (Texas Advanced Computing Center), and Comet (San Diego Supercomputer Center). The developers will need to customize GIB for supporting additional supercomputing platforms. For example, the names of the preferred systems will need to be updated on the "Compile and Run" (compileRun) page, and the appropriate commands for supporting batch job submission will need to be added - by default Slurm job scheduler is supported and the support for other schedulers will need to be added.

