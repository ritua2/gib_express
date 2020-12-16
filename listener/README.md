Recovers the output files from a greyfish server.


## Installation

```bash

# Modify the docker volume to the host's directory twice, onece for env and another for the volume
# Change password (recommended)
# Change the basic greyfish URL and key (these values can be altered by requests)
vi docker-compose.yml

# Start the container
docker-compose up -d
# Enter the container and start APIs

exec -it $CONTAINER_ID bash
cd /listener

gunicorn -w 4 -b 0.0.0.0:5000 listener:app &
exit

```  


## Usage

```bash

LID=$IPT_SERVER_IP

# Download all files for a specific Job ID
curl --header "Content-Type: application/json" --request POST \
	--data '{"Job_ID":"example", "password":"abc123" "User":"i87u", "OUTPUT_DIRS":[], "OUTPUT_FILES":[]}' \
   	http://$IPT_SERVER_IP:5000/listener/api/users/output_data

# Adds extra directories (optional) and extra files (optional)
# Extra files: [{path:file}, {}]
# Both cases must follow greyfish standards
curl --header "Content-Type: application/json" --request POST --data '{"Job_ID":"example", "User":"i87u", "OUTPUT_DIRS":["ool", "d34"], "OUTPUT_FILES":[{"path":d1++a3", "filename":"f1.txt"}], "password":"abc123"}'  http://$IPT_SERVER_IP:5000/listener/api/users/output_data


# Change the URL of a URL server and/or the key (optional)
curl --header "Content-Type: application/json" --request POST --data '{"Job_ID":"example", "User":"i87u", "OUTPUT_DIRS":["ool", "d34"], "OUTPUT_FILES":[{"path":d1++a3", "filename":"f1.txt"}], "password":"abc123", "greyfish_url":"$new_url", "greyfish_key":"$new_key"}' \
     http://$IPT_SERVER_IP:5000/listener/api/users/output_data
```  
