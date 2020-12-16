# Replication procedure to start a new springIPT instance

------------

## Prerequisites

* Docker and Docker-Compose

If using Ubuntu ≥ 16.04 install using the script below or using the following [file](./install_docker.sh):

```bash
# Installs docker and erases the previous version
# Valid for Ubuntu >= 16.04
# ------------------------------------------------

apt-get remove docker docker-engine docker.io
apt-get update

apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common -y

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -



add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update

apt-get install docker-ce -y


printf "Succesfully installed docker\n"

# Installs docker compose as well
#----------------------------------

curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

printf "Succesfully installed docker-compose\n"
```


## Installation instructions

0. Download the gib repository:

```bash
git clone https://github.com/ritua2/gib
cd gib/springipt
```



1. Set the root, ipt user passwords, and the IP of the local machine:

```bash
export MYSQL_ROOT_PASSWORD=root_passwd
export MYSQL_USER=spring
export MYSQL_PASSWORD=spring_passwd
export MYSQL_SERVER=127.0.0.1
```


2. If a springIPT server already exists, remove this server and delete the corresponding volume:

```bash
docker-compose down -v
docker volume rm myvol
```


3. Create the necessary volume and start the containers:

```bash
docker volume create --name=myvol
docker-compose up -d
```





