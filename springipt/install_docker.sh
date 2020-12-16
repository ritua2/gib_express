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
