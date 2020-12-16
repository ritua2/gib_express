### Portable, transferrable cloud storage

Greyfish is an out of the box, simple cloud storage framework.  
It will store files and directories without changes on the go.  
All your files will remain protected and visible only to you.  
Keep your use data available in InfluxDB.

Powered with a wsgi server, access your files through multiple threads. 
Data can be easily monitored using grafana or any other app.  

Allows single use tokens for specifc actions. These tokens are stored within an attached redis server on port 6379, and can be accessed, created, or deleted
from other another server or container within the same machine.




#### Installation  

```bash
git clone https://github.com/noderod/greyfish
cd greyfish
# Change the influxdb log credentials
vi credentials.yml
# Set the appropriate passwords and base URL (without / and http(s)://
# Define the number of threads using "greyfish_threads", default is set to 4
REDIS_AUTH="examplepass" URL_BASE=example.com greyfish_key="examplegrey" docker-compose up -d
```


#### Instructions  

To activate or switch off the APIs, enter the docker container and do:  

```bash
# Enter container
docker exec -it greyfish_greyfish_1 bash
cd /grey
# Start the needed databases and assign permission (APIs will not be started)
/grey/setup.sh
# Activate (change the number of threads if needed, standard is 4)
./API_Daemon.sh -up
# Deactivate
./API_Daemon.sh -down
```

Note: deactivating the APIs will not change or delete any data, it will simply no longer be able to accept communications from outside.




#### Usage 

The Greyfish APIs can be called from any system as long as the greyfish key is known.  


```bash
	
gk=$Greyfish_Key # Set up in the docker-compose.yml

# Create a new user
curl http://$SERVER_IP:2003/grey/create_user/$gk/$USER_ID
# Delete a user
curl http://$SERVER_IP:2003/grey/delete_user/$gk/$USER_ID

# Get a JSON object of all user files
curl http://$SERVER_IP:2000/grey/all_user_files/$gk/$USER_ID
curl http://$SERVER_IP:2001/grey/all_user_files/$gk/$USER_ID

# Get contents of an entire directory in JSON (using ++ instead of / for paths)
curl http://$SERVER_IP:2000/grey/user_files/$gk/$USER_ID/PATH++TO++DIR
# Upload one file (will create the directory if needed
curl -F file=@$LOCAL_PATH_TO_FILE http://$SERVER_IP:2000/grey/upload/$gk/$USER_ID/PATH++TO++DIR
# Deletes a file
curl http://$SERVER_IP:2000/grey/delete_file/$gk/$USER_ID/$FILENAME/PATH++TO++DIR
# Deletes a directory (recursive)
curl http://$SERVER_IP:2000/grey/delete_dir/$gk/$USER_ID/PATH++TO++DIR
# Returns a file
curl http://$SERVER_IP:2000/grey/grey/$gk/$USER_ID/$FILENAME/PATH++TO++DIR
# Uploads a directory (must be compressed into .tgz or .tar.gz),
# if it already exists, it substitutes all files inside
curl -F file=@$LOCAL_PATH_TO_TAR http://$SERVER_IP:2000/grey/upload_dir/$gk/$USER_ID/PATH++TO++DIR
# Downloads a directory as a .tar.gz file
curl http://$SERVER_IP:2000/grey/grey_dir/$gk/$USER_ID/PATH++TO++DIR

# Gets all the data currently in the user directory
curl http://$SERVER_IP:2001/grey/get_all/$gk/$USER_ID
# Replaces all current data
curl -F file=@$TARRED_CONTENT  http://$SERVER_IP:2002/grey/push_all/$gk/$USER_ID

# Checksum actions
# Download a directory as a checksum file (first 8 characters of SHA256 checksum + tar.gz)
# This will move the tar file to a temporary checksum directory in case it needs to be checked later
# and delete the constituent directory files
# Both the -O and -J flags are required
curl -O -J http://$SERVER_IP:2000/grey/download_checksum_dir/$gk/$USER_ID/PATH++TO++DIR
# Or using wget:
wget --content-disposition http://$SERVER_IP:2000/grey/download_checksum_dir/$gk/$USER_ID/PATH++TO++DIR
# Delete a checksum file given its full name (i.e. FILENAME=y78t4jha.tar.gz) 
curl http://$SERVER_IP:2000/grey/delete_checksum_file/$gk/$USER_ID/$FILENAME


# Admin actions

# self_ID refers to how the admin wishes to refer to itself, useful in case of using temporary tokens
# Check all available usernames
curl -X POST -H "Content-Type: application/json" -d '{"key":"examplegrey", "self_ID":"admin1"}' http://$SERVER_IP:2004/grey/admin/users/usernames/all
# Purges all files older than Xsec seconds
curl -X POST -H "Content-Type: application/json" -d '{"key":"examplegrey", "self_ID":"admin1"}' http://$SERVER_IP:2004/grey/admin/purge/olderthan/$Xsec
``` 
