### Middle-layer for *gateway-in-a-box*


**Installation**  

All setup is automatic after the repository has been downloaded. Modify the environmental variables in *.env*.  
It is strongly recommended that the user change all the passwords and keys provided.

Note: If any variable has the same value as another, the user must repeat them (using $VARIABLE is not allowed).



```bash
docker-compose up -d --build
```

To activate or switch off the cloud storage APIs, enter the greyfish docker container and do:  

```bash
# Enter container
docker exec -it greyfish bash
cd /grey
# Activate the APIs (change the number of threads if needed, standard is 4)
./API_Daemon.sh -up
# Deactivates the APIs
./API_Daemon.sh -down
```


To activate or switch off the manager node APIs, enter the greyfish docker container and do:  

```bash
# Enter container
docker exec -it manager_node bash

# If first time, generate an ssh key to allow rsync
ssh-keygen -t rsa -N ""  -f rsync_wetty.key

# Activate (change the number of threads if needed with the -w flag, defined in .env)
gunicorn -w $gthreads -b 0.0.0.0:5000 traffic:app &
# Deactivate
pkill gunicorn
```

**Note**

A previous version of the current code, written in go is available [here](./manager_node/gocode). Both are similar as of May 27th, 2019 but the go version will no longer be maintained.
