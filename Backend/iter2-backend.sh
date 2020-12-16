#! /bin/bash

###############
# BASICS
#
# Assumptions: Download and processing is fast enough to never be in a situation where two cron jobs are executing at the same time
###############

currentdir=$(pwd)
source .env
source aux_functions.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
NC='\033[0m' # No color



# Finds how many jobs are currently running in Slurm
jobs_currently_running=$(squeue | grep "$slurm_user" | wc -l)

# Enforces a constraint in the maximum amount of jobs run at the same time
jobs_to_be_run_now=$(($max_jobs_run_at_same_time - $jobs_currently_running))

# Enforces a positive integer
# Avoids cases with 0 jobs or where slurm may return an error message
if [[ ! "$jobs_to_be_run_now" =~ ^\-?[1-9][0-9]*$ ]]; then
    printf "${RED}The number of jobs is not an integer, this may be an error with the SLURM squeue command${NC}\n"
    exit
fi

if [[ "$jobs_to_be_run_now" -lt "1" ]]; then
    printf "${RED}Maximum number of jobs is reached, no more jobs can be run at this time${NC}\n"
    exit
fi

printf "${GREEN}A maximum of $jobs_to_be_run_now jobs will be run.${NC}\n"


# Processes the jobs
curl -s -X POST -H "Content-Type: application/json" -d '{"key":"'"$orchestra_key"'", "number":"'"$jobs_to_be_run_now"'", "sc_system":"'"$sc_server"'"}' \
    http://$manager_node_ip:5000/api/jobs/request > tmp-available_job_list.json

enforce_json_field tmp-available_job_list.json "IDs"
enforce_json_field tmp-available_job_list.json "directory_locations"
enforce_same_length_json_lists tmp-available_job_list.json "IDs" "directory_locations"


if [[ $(jparser tmp-available_job_list.json "IDs" "len") = "0" ]]; then
    printf "\nNo jobs available\n"
    exit
fi



json_fullpath="$PWD"/tmp-available_job_list.json

# Processes the jobs
counter=0

all_job_IDs=()
all_dirlocs=()

tmp_jfil1=tmp-j1.json
tmp_jfil2=tmp-j2.json

printf "{\n    \"IDs\":[" > "$tmp_jfil1"
printf "    \"directory_locations\":[" > "$tmp_jfil2"

declare -A jobID_to_dirloc
declare -A dirloc_to_jobID


while read job_id
do
    
    dirloc=$(json_list_elem tmp-available_job_list.json "directory_locations" "$counter")

    all_job_IDs+=("$job_id")
    all_dirlocs+=("$dirloc")

    jobID_to_dirloc["$job_id"]+="$dirloc"
    dirloc_to_jobID["$dirloc"]+="$job_id"


    if [ "$counter" = "0" ]; then
        printf "\"$job_id\"" >> "$tmp_jfil1"
        printf "\"$dirloc\"" >> "$tmp_jfil2"
    else
        printf ", \"$job_id\"" >> "$tmp_jfil1"
        printf ", \"$dirloc\"" >> "$tmp_jfil2"
    fi

    counter=$(($counter + 1))

done < <(json_list_by_line tmp-available_job_list.json "IDs")


printf "],\n\"key\":\"$orchestra_key\",\n" >> "$tmp_jfil1"
printf "]\n}\n" >> "$tmp_jfil2"

cat "$tmp_jfil1" "$tmp_jfil2" > tmp-get_job_data.json


# Requests the jobs in bulk
curl -s -X POST -H "Content-Type: application/json" -d @tmp-get_job_data.json \
    http://$manager_node_ip:5000/api/jobs/request/data/bulk > bulk_data.tar.gz

rm "$json_fullpath"
rm "$tmp_jfil1" "$tmp_jfil2" tmp-get_job_data.json

# Checks the checksums
# Jobs with an incorrect checksum will be marked as defective arrival
tar -xvzf bulk_data.tar.gz -C $execution_directory/

rm -f bulk_data.tar.gz

cd $execution_directory

for filename in ./*.zip; do


    # Removes all current modules
    module unload

    just_the_filename=${filename/'./'/}
    dirloc_name=${just_the_filename/'.zip'/}

    current_jobID=${dirloc_to_jobID[$dirloc_name]}

    # Enforces that the file is here
    if [[ $(soft_enforce_json_field checksums.json $just_the_filename) = "False" ]]; then

        printf "${PURPLE}Job data $just_the_filename is not in the checksum file, the server will be notified${NC}\n"

        # Notify server about erroneous job
        update_job_status "$current_jobID" "Finished" "Data not present in checksum"
        printf "\n"
        rm "$just_the_filename"
        continue
    fi

    # Enforces that the checksum is the same
    if [[ $(checksum8 "$just_the_filename") != $(jparser checksums.json $just_the_filename) ]]; then

        printf "${PURPLE}Job data $just_the_filename does not have the correct checksum, the server will be notified${NC}\n"

        # Notify server about erroneous job
        update_job_status "$current_jobID" "Finished" "Incorrect checksum"
        printf "\n"
        rm "$just_the_filename"
        continue
    fi

    update_job_status "$current_jobID" "Processing" ""
    printf "\n"

    unzip "$just_the_filename"
    cd "$dirloc_name"

    if [ ! -f meta.json ]; then
        printf "${PURPLE}Job $job_dir cannot be processed, meta.json does not exist${NC}"

        update_job_status "$current_jobID" "Finished" "meta.json does not exist"
        printf "\n"
        # Notify server of faulty job
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    # Gets the date in format YYYY-MM-DD hh:mm:ss 
    date_sc_received="$(date +%F) $(date +%H):$(date +%M):$(date +%S)" 

    # Important only for compute jobs
    if [[ $(soft_enforce_json_field meta.json n_nodes) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'n_nodes' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'n_nodes' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    n_nodes=$(jparser meta.json n_nodes)
    n_cores=$(jparser meta.json n_cores)

    if ! [[ $n_nodes =~ ^[1-9][0-9]*$ ]] ; then
        printf "${PURPLE}Error in $current_jobID. 'n_nodes' must be a positive integer larger than zero${NC}\n"

        update_job_status "$current_jobID" "Finished" "'n_nodes' must be a positive integer larger than zero"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    if [[ $(soft_enforce_json_field meta.json n_cores) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'n_cores' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'n_cores' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    if ! [[ $n_cores =~ ^[1-9][0-9]*$ ]] ; then
        printf "${PURPLE}Error in $current_jobID. 'n_cores' must be a positive integer larger than zero${NC}\n"

        update_job_status "$current_jobID" "Finished" "'n_cores' must be a positive integer larger than zero"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi


    # Enforce output_files
    if [[ $(soft_enforce_json_field meta.json output_files) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'output_files' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'output_files' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi


    # Check modules
    if [[ $(soft_enforce_json_field meta.json modules) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'modules' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'modules' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    modules_used=$(jparser meta.json modules)


    # Queue information
    if [[ $(soft_enforce_json_field meta.json sc_queue) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'sc_queue' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'sc_queue' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    sc_queue=$(jparser meta.json sc_queue)

    # User information
    if [[ $(soft_enforce_json_field meta.json User) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'User' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'User' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    job_user=$(jparser meta.json User)


    # expected runtime information
    if [[ $(soft_enforce_json_field meta.json runtime) = "False" ]]; then

        printf "${PURPLE}Error in $current_jobID. Missing 'runtime' key in meta.json${NC}\n"

        update_job_status "$current_jobID" "Finished" "Missing 'runtime' key in meta.json"
        printf "\n"
        cd ..
        rm -rf "$dirloc_name"
        rm "$just_the_filename"
        continue
    fi

    expected_runtime=$(jparser meta.json runtime)



    # Creates the slurm file
    slurm_file="$current_jobID".slurm
    printf "#!/bin/bash\n\n" > "$slurm_file"

    printf "#SBATCH --job-name=\"$current_jobID\"\n" >> "$slurm_file"
    printf "#SBATCH --output=\"$current_jobID\".%%j.%%N.out\n" >> "$slurm_file"
    printf "#SBATCH --partition=$sc_queue\n" >> "$slurm_file"
    printf "#SBATCH --nodes=$n_nodes\n" >> "$slurm_file"
    printf "#SBATCH --ntasks-per-node=$n_cores\n" >> "$slurm_file"
    printf "#SBATCH --export=ALL\n" >> "$slurm_file"
    printf "$allocation_instructions\n" >> "$slurm_file"

    # TODO
    # Requires changes in wetty
    # Expected time is not handled yet, let's assume 10 min
    printf "#SBATCH -t $expected_runtime\n\n" >> "$slurm_file"


    if [ ! -z "$modules_used" ]; then
        printf "module load $modules_used\n" >> "$slurm_file"
    fi



    printf 'export date_started="'"$date_sc_received""\"\n" >> "$slurm_file"
    printf -- 'unix_started=$(date +%%s)'"\n" >> "$slurm_file"

    # Ensures the existance of basic information
    job_type=$(jparser meta.json Job)


    faulty_cc=""
    faulty_rc=""

    # 3 possible job situations: 
    case "$job_type" in
        "Both")



            # All files can be executed since the user may run any of them
            chmod -R +x .
            chmod -x "$slurm_file"
            chmod -x meta.json


            # Gets the number of compiled instructions

            if [[ $(soft_enforce_json_field meta.json CC) = "False" ]]; then

                printf "${PURPLE}Error in $current_jobID. Missing 'CC' key in meta.json${NC}\n"

                update_job_status "$current_jobID" "Finished" "Missing 'CC' key in meta.json"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_compiled_instructions=$(jparser meta.json CC)

            if ! [[ $n_compiled_instructions =~ ^[1-9][0-9]*$ ]] ; then
                printf "${PURPLE}Error in $current_jobID. 'CC' must be a positive integer larger than zero${NC}\n"

                update_job_status "$current_jobID" "Finished" "'CC' must be a positive integer larger than zero"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_last_compile=$(($n_compiled_instructions - 1))

            for n_cc in $(seq 0 $n_last_compile); do

                n_c_command=$(jparser meta.json C$n_cc)
                if [ "$n_c_command" = "File or key do not exist" ]; then
                    faulty_cc="CC does not exist"
                    break
                fi

                printf "$n_c_command""\n" >> "$slurm_file"
            done


            if [ ! -z "$faulty_cc" ]; then
                printf "${PURPLE}Faulty compile commands, missing one or more instructions${NC}\n"

                update_job_status "$current_jobID" "Finished" "Faulty compile commands, missing one or more instructions"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi



            # Gets the number of run instructions
            n_run_instructions=$(jparser meta.json RC)

            if ! [[ $n_run_instructions =~ ^[1-9][0-9]*$ ]] ; then
                printf "${PURPLE}Error in $current_jobID. 'RC' must be a positive integer larger than zero${NC}\n"

                update_job_status "$current_jobID" "Finished" "'RC' must be a positive integer larger than zero"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_last_run=$(($n_run_instructions - 1))


            for n_rc in $(seq 0 $n_last_run); do

                n_r_command=$(jparser meta.json R$n_rc)
                if [ "$n_r_command" = "File or key do not exist" ]; then
                    faulty_rc="CC does not exist"
                    break
                fi

                printf "$n_r_command""\n" >> "$slurm_file"
            done


            if [ ! -z "$faulty_rc" ]; then
                printf "${PURPLE}Faulty run commands, missing one or more instructions${NC}\n"

                update_job_status "$current_jobID" "Finished" "Faulty run commands, missing one or more instructions"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi
            ;;


        "Compile")

            # Gets the number of compiled instructions

            if [[ $(soft_enforce_json_field meta.json CC) = "False" ]]; then

                printf "${PURPLE}Error in $current_jobID. Missing 'CC' key in meta.json${NC}\n"

                update_job_status "$current_jobID" "Finished" "Missing 'CC' key in meta.json"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_compiled_instructions=$(jparser meta.json CC)

            if ! [[ $n_compiled_instructions =~ ^[1-9][0-9]*$ ]] ; then
                printf "${PURPLE}Error in $current_jobID. 'CC' must be a positive integer larger than zero${NC}\n"

                update_job_status "$current_jobID" "Finished" "'CC' must be a positive integer larger than zero"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_last_compile=$(($n_compiled_instructions - 1))

            for n_cc in $(seq 0 $n_last_compile); do

                n_c_command=$(jparser meta.json C$n_cc)
                if [ "$n_c_command" = "File or key do not exist" ]; then
                    faulty_cc="CC does not exist"
                    break
                fi

                printf "$n_c_command""\n" >> "$slurm_file"
            done


            if [ ! -z "$faulty_cc" ]; then
                printf "${PURPLE}Faulty compile commands, missing one or more instructions${NC}\n"

                update_job_status "$current_jobID" "Finished" "Faulty compile commands, missing one or more instructions"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            ;;


        "Run")

            # All files can be executed since the user may run any of them
            chmod -R +x .
            chmod -x "$slurm_file"
            chmod -x meta.json


            # Gets the number of run instructions
            n_run_instructions=$(jparser meta.json RC)

            if ! [[ $n_run_instructions =~ ^[1-9][0-9]*$ ]] ; then
                printf "${PURPLE}Error in $current_jobID. 'RC' must be a positive integer larger than zero${NC}\n"

                update_job_status "$current_jobID" "Finished" "'RC' must be a positive integer larger than zero"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi

            n_last_run=$(($n_run_instructions - 1))


            for n_rc in $(seq 0 $n_last_run); do

                n_r_command=$(jparser meta.json R$n_rc)
                if [ "$n_r_command" = "File or key do not exist" ]; then
                    faulty_rc="CC does not exist"
                    break
                fi

                printf "$n_r_command""\n" >> "$slurm_file"
            done


            if [ ! -z "$faulty_rc" ]; then
                printf "${PURPLE}Faulty run commands, missing one or more instructions${NC}\n"

                update_job_status "$current_jobID" "Finished" "Faulty run commands, missing one or more instructions"
                printf "\n"
                cd ..
                rm -rf "$dirloc_name"
                rm "$just_the_filename"
                continue
            fi
            ;;


        *)
            printf "${PURPLE}Job type is not accepted${NC}\n"

            update_job_status "$current_jobID" "Finished" "Job type is not accepted"
            printf "\n"
            cd ..
            rm -rf "$dirloc_name"
            rm "$just_the_filename"
            continue
            ;;

    esac
      
    # Compute total time and upload it to server
    printf 'export execution_ended=$(date +%%s)'"\n" >> "$slurm_file"
    printf 'export execution_time=$(($execution_ended - $unix_started))'"\n" >> "$slurm_file"



    # Read output_files
    output_files=$(jparser meta.json output_files)

    # Notify server of completed job
    update_job_status "$current_jobID" "Submitted for Slurm processing" ""

    # Uploads the results
    cp $currentdir/upload_job_files.sh .

    # Files with information
    printf "$orchestra_key" > orchestra_file
    printf "$manager_node_ip" > manager_node_file
    printf "$job_user" > User_file
    printf "$current_jobID" > jobID_file

    printf "bash upload_job_files.sh $output_files""\n" >> "$slurm_file"


    printf 'curl -s -X POST -H "Content-Type: application/json" -d '"'"'{"key":"'"$orchestra_key"'", "job_ID":"'"$current_jobID"'", "status":"Finished", "error":""}'"'    http://$manager_node_ip:5000/api/jobs/status/update\n" >> "$slurm_file"
    printf 'curl -s -X POST -H "Content-Type: application/json" -d '"'"'{"key":"'"$orchestra_key"'", "job_ID":"'"$current_jobID"'", "sc_execution_time":"'"'"'"$execution_time"'"'"'", "notes_sc":""}'"'    http://$manager_node_ip:5000/api/jobs/status/update_execution_time\n" >> "$slurm_file"


    # Compile jobs are run diretcly on the login nodes
    if [ "$job_type" = "Compile" ]; then

        bash "$slurm_file"

        cd ..
        rm "$just_the_filename"
        continue
    fi


    sbatch "$slurm_file"

    cd ..

    # Delete the zip from local storage
    rm "$just_the_filename"

done

rm checksums.json


cd $currentdir

