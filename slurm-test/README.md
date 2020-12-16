## Slurm Test server

Largely based on that provided by [Giovanni Torres](https://github.com/giovtorres/docker-centos7-slurm).

---------------


### Installation

Run setup.sh:

```bash
source setup.sh
```  


### Reinstallation

If a user has already started the server and brought it down, it can be restarted by:

* Restart docker-compose issuing the values from terminal:
```bash
CONDUCTOR_IP="example.com"  CONDUCTOR_PASSWORD="password1" output_data_path="/gib/data/" docker-compose up -d --build
```


**or**

* Modify *.env* file and restart:
```bash
vi .env
docker-compose up -d
```


Downloading the necessary information and all the steps executed will require a few minutes.
