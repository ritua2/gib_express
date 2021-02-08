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

# Update client_id, scope, redirect_uri under login_cilogon function and client_id, client_secret, redirect_uri under welcome function according to your CILogon registration details
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

This should be done on a different VM than the one on which the middle-layer and front-end are installed.

*conductor* refers to the IP or URL (without http://, https://, or the ending /) where springIPT is located at.

*orchestra_key* refers to the manager's node key, declared in gib/middle-layer/.env

```bash
# If not running as root, become root first
sudo su -

# Download the git repository
git clone https://github.com/ritua2/gib_express.git

# Change the directory to the setup script
cd gib_express

# Make the setup script executable
chmod +x wetty_setup.sh

# Run the script
./wetty_setup.sh

# Provide URL_BASE and orchestra key from .env file when promptes. Also provide number of terminals to be run ranging from 1 to 6
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


* **Authentication Customization**

By default, authentication is enabled via web portal (that is, using the web portal credentials) and CILogon(after updating CILogon configuration while setting up the web portal).
To enable LDAP authentication, follow the instructions(with keyword "enable ldap") mentioned on each page mentioned below:
1. login_normal.jsp
2. traffic.py
3. UploadController.java
4. appconfig-security.xml

* **Customizing access to "compile and run" page**

By default, all the users have access to the "compile and run" page.

To restrict access such that only:

1. LDAP and CILogon users can access this page, uncomment the code under compileRunStatus function inside UploadController.java as instructed on the second last line of the method (line #509).
2. LDAP users can access the page, uncomment the code under compileRunStatus function inside UploadController.java as instructed on the second last line of the method (line #509) and remove " request.getSession().getAttribute("is_cilogon").toString()=="true" || " from the if-condition at line #499
3. CIlogon users can access the page, then uncomment the following code on line #499 & line #500
```bash
if( request.getSession().getAttribute("is_cilogon").toString()=="true" || authentication.getPrincipal().toString().contains("ROLE_ADMIN"))
return "compileRun_v5";
```
and append following lines,

```bash
else
return "accessDenied";
```

Note:

If user is already using terminal in one browser and tries to access terminal in different browser simultaneously then they won't be able to access it. We are working on this and will release a new feature/fix related to this soon. The new feature/fix will allow developers to customize the number of simultaneous terminal sessions allowed per user.
