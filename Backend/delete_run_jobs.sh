#! /bin/bash

###############
# BASICS
#
# Deletes files of jobs already run from the supercomputer
#
###############

currentdir=$(pwd)
source .env

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NC='\033[0m' # No color


cd $execution_directory



# Searches all directories, checks if complete, and deletes them if so
for dir in */ ; do

    # Note: $dir contains the final '/'

    if [ "$dir" = '*/' ]; then
        printf "${RED}No available directories${NC}\n"
        exit
    fi

    job_ID=$(cat ${dir}jobID_file)

    # Gets information about the file
    job_status=$(curl -s -X POST -H \
                "Content-Type: application/json" -d '{"key":"'"$orchestra_key"'", "job_ID":"'"$job_ID"'"}' \
                http://$greyfiship:5000/api/jobs/status)


    if [ "$job_status" = *"INVALID"* ]; then
        printf "${RED}$job_status${NC}\n"
        continue
    fi


    # Only deletes those that are complete
    if [ "$job_status" = "Finished" ]; then

        rm -rf "$dir"
        printf "${GREEN}Removed ""$dir"", corresponding to job ID '$job_ID'${NC}\n"
        continue
    fi


done



cd $currentdir

