#!/bin/bash


# If the container was left as waiting:
if [ -f "/etc/wait.key" ]; then
    
    wait_key_file="/etc/wait.key"

    # Gets the key
    wait_key=$(head -n 1 "$wait_key_file")

    # Provides the path to the bug DB CLI
    alias bug_db_cli=/shared/bug_db_cli

    # Gets the username
    export USER=$(head -2 "$wait_key_file" | tail -1)

    # Asks the user to enter the key value
    printf "\nEnter the WAIT key (this process is done automatically): "
    read user_provided_wait_key

    if [ "$user_provided_wait_key" = "$wait_key" ]; then

        # Deletes the wait file
        curl -s http://0.0.0.0:3100/delete_wait
        export GS=$(curl -s http://$MANAGER_NODE:5000/api/greyfish/location)
        printf "\n\033[0;32mWelcome back\033[0m\n\n"

    else
        export USER="Empty"
        printf "Access not allowed\n"
        exit
    fi


    # IPT variables
    export JAVA_HOME=/mnt/rosedocker/roseCompile/jdk1.8.0_131
    export JAVA_TOOL_OPTIONS="-Xms2G -Xmx2G"
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server
    export PATH=/mnt/rosedocker/roseCompile/lib/bin:$PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/lib/lib/:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/boost_install/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/roseCompileTree/lib:$LD_LIBRARY_PATH

    alias IPT=/home/ipt/src/IPT



    # No need to setup the rest of the container

# New user
else

    # Gets the username
    export USER=$(curl -s http://$MANAGER_NODE:5000/api/instance/whoami/$UUID_f10)

    # If the user is not what is expected, it exits
    if [ "$USER" = "Empty" ]; then
       printf "Access not allowed\n"
       exit
    fi

    # Provides the path to the bug DB CLI
    alias bug_db_cli=/shared/bug_db_cli

    # Gets the greyfish server location
    export GS=$(curl -s http://$MANAGER_NODE:5000/api/greyfish/location)

    # Gets two greyfish keys
    GK1=$(curl -s http://$MANAGER_NODE:5000/api/greyfish/new/single_use_token/$UUID_f10)
    GK2=$(curl -s http://$MANAGER_NODE:5000/api/greyfish/new/single_use_token/$UUID_f10)


    # Gets all the user files and results
    curl -s http://$GS:2000/grey/grey_dir/$GK1/$USER/home++gib++home++gib > summary.tar.gz

    # Checks that the previous data is actually tarred
    if { tar ztf "summary.tar.gz" || tar tf "summary.tar.gz"; } >/dev/null 2>&1; then
       tar -xzf summary.tar.gz
       rm -rf /home/gib/home
    fi

    rm -f summary.tar.gz

    # Gets the results
    curl -s http://$GS:2000/grey/grey_dir/$GK2/$USER/results > results.tar.gz

    if [ ! -d /home/gib/results ]; then
        mkdir /home/gib/results
    fi


    if { tar ztf "results.tar.gz" || tar tf "results.tar.gz"; } >/dev/null 2>&1; then
       tar -xzf results.tar.gz -C /home/gib/results/
    fi

    rm -f results.tar.gz

    # IPT variables

    export JAVA_HOME=/mnt/rosedocker/roseCompile/jdk1.8.0_131
    export JAVA_TOOL_OPTIONS="-Xms2G -Xmx2G"
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server
    export PATH=/mnt/rosedocker/roseCompile/lib/bin:$PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/lib/lib/:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/boost_install/lib:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/roseCompileTree/lib:$LD_LIBRARY_PATH

    alias IPT=/home/ipt/src/IPT

fi




# Gets the project
export PROJECT=$(curl -s http://$MANAGER_NODE:5000/api/project/name)

# Changes the terminal prompt to [/PROJECT/USERNAME: ~] $ 
PS1="$USER@$PROJECT: $PWD \$ " 



function slurm_submit     {

    # Requests a new greyfish key for the user
    GK_slurm=$(curl -s http://$MANAGER_NODE:5000/api/greyfish/new/commonuser_token/$UUID_f10)


    # Colors, helpful for printing
    GREENGREEN='\033[0;32m'
    REDRED='\033[0;31m'
    YELLOWYELLOW='\033[1;33m'
    BLUEBLUE='\033[1;34m'
    NCNC='\033[0m' # No color



    # Creates a directory
    RNAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    newdir="$USER"_"$RNAME"
    mkdir $newdir
    jfile="$newdir/meta.json"
    printf "{\n" >> $jfile
    printf "\"User\":\"$USER\",\n" >>  $jfile


    ###############
    # Modules
    ###############
    printf "${BLUEBLUE}  Enter the list of modules as you would in a terminal, space separated${NCNC}\n"
    printf "${BLUEBLUE}  Press enter to finish ${NCNC}\n"
    read modules_used


    ###############
    # Commands
    ###############

    printf "${BLUEBLUE}  Enter the list of compile commands (must be bash compatible), as you would in a terminal${NCNC}\n"
    printf "${BLUEBLUE}  Empty command to finish ${NCNC}\n"

    compile_commands=0

    while true
    do
        read COM
        COMSAFE="${COM//\"/\\\\\"}" 

        if [ -z "$COM" ]; then
            break
        fi

        printf "\"C$compile_commands\":\"$COMSAFE\",\n" >> $jfile

        compile_commands=$(($compile_commands + 1))

    done

    printf "\n\n\n"
    printf "${BLUEBLUE}  Enter the list of run commands (must be bash compatible), as you would in a terminal${NCNC}\n"
    printf "${BLUEBLUE}  Empty command to finish ${NCNC}\n"

    run_commands=0

    while true
    do
        read COM
        COMSAFE="${COM//\"/\\\\\"}" 

        if [ -z "$COM" ]; then
            break
        fi

        printf "\"R$run_commands\":\"$COMSAFE\",\n" >> $jfile

        run_commands=$(($run_commands + 1))

    done


    #######################################
    # Necessary files and subdirectories
    #######################################

    printf "\n\n\n"
    printf "${YELLOWYELLOW}  Enter the list of input directories, one per line${NCNC}\n"
    printf "${YELLOWYELLOW}  Empty command to finish ${NCNC}\n"


    while true
    do

        read user_dir

        if [ -z "$user_dir" ]; then
            printf "No more directories have been added\n"
            break
        fi

        if [ ! -d "$user_dir" ]; then
            printf "${REDRED}$user_dir does not exist${NCNC}\n"
            continue
        fi

        cp -r "$user_dir" $newdir

    done



    printf "\n\n"
    printf "${YELLOWYELLOW}  Enter the list of input files, one per line${NCNC}\n"
    printf "${YELLOWYELLOW}  Empty command to finish ${NCNC}\n"


    while true
    do

        read user_fil

        if [ -z "$user_fil" ]; then
            printf "No more files have been added\n"
            break
        fi

        if [ ! -f "$user_fil" ]; then
            printf "${REDRED}$user_fil does not exist${NCNC}\n"
            continue
        fi

        cp -r "$user_fil" $newdir

    done


    ###############
    # Output files and directories
    ###############

    # All files are retrieved

    #printf "${BLUEBLUE}  Enter the list of output files and directories, files may not have spaces in them, space separated${NCNC}\n"
    #printf "${BLUEBLUE}  Press enter to finish ${NCNC}\n"
    #read output_files

    #for possible_output in $output_files
    #do

        # Problematic characters
    #    if [[ ! "$possible_output" =~ ^[a-zA-Z0-9\._\-]+$  ]]; then
    #        printf "Error in filename ${REDRED}$possible_output${NCNC}\n"
    #        printf "${REDRED}Invalid character detected, only alphanumeric, _, - characters are allowed${NCNC}\n"
    #        return 1
    #    fi

    #done



    ##########################
    # Zip and metadata
    ##########################


    # Gets the date in format YYYY-MM-DD hh:mm:ss 
    YYYYMMDD="$(date +%F) $(date +%H):$(date +%M):$(date +%S)" 
    unix_time=$(date +%s)

    # Adds other metadata

    total_commands=$(($compile_commands + $run_commands))

    case "$total_commands" in
        "2")
            printf "\"CC\":\"$compile_commands\",\n" >> $jfile
            printf "\"RC\":\"$run_commands\",\n" >> $jfile
            printf "\"Job\":\"Both\",\n" >> $jfile

            # Selects the system
            declare -A available_systems=( ["1"]="Comet" ["2"]="Stampede2" ["3"]="Lonestar5")
            printf "Select system:\n"
            printf "  [1] Comet\n  [2] Stampede2\n  [3] Lonestar5\n\n"
            read selected_system

            if [[ ! $selected_system =~ ^(1|2|3)$  ]]; then
                printf "${REDRED}Please enter '1', '2', or '3'${NCNC}\n"
                return 1
            fi

            system_to_be_used=${available_systems["$selected_system"]}
            printf "\"sc_system\":\"$system_to_be_used\",\n" >> $jfile

            # Selects the queues
            # Marked as system,number. i.e. : Stampede2 normal = 2,1

            declare -A queues=(["1,1"]="gpu-shared" ["1,2"]="gpu" ["1,3"]="debug" ["1,4"]="compute"
                                ["2,1"]="normal" ["2,2"]="development" ["2,3"]="flat-quadrant" ["2,4"]="skx-dev" ["2,5"]="skx-normal"
                                ["3,1"]="normal" ["3,2"]="development" ["3,3"]="gpu" ["3,4"]="vis"
                                )

            printf "Select queue:\n"
            valid_queues=""

            for k in "${!queues[@]}"
            do
                if [[ ! "$k" =~ ^"$selected_system""," ]]; then
                    continue
                fi

                numbered_queue=${k/$selected_system,/}
                valid_queues="$valid_queues""  [$numbered_queue] ${queues[$k]}\n"
            done

            printf "$valid_queues\n" | sort

            read user_chosen_queue

            if [ -z ${queues["$selected_system,$user_chosen_queue"]} ]; then
                printf "${REDRED}INVALID queue${NCNC}\n"
                return 3
            fi

            queue_to_be_used=${queues["$selected_system,$user_chosen_queue"]}
            printf "\"sc_queue\":\"$queue_to_be_used\",\n" >> $jfile


            # Select nodes and cores
            printf "Select number of nodes: "
            read n_nodes

            if [[ ! "$n_nodes" =~ ^[1-9][0-9]*$ ]]; then
                printf "${REDRED}INVALID number of nodes, must be integer${NCNC}\n"
                return 3
            fi

            printf "\"n_nodes\":\"$n_nodes\",\n" >> $jfile

            printf "Select number of cores: "
            read n_cores

            if [[ ! "$n_cores" =~ ^[1-9][0-9]*$ ]]; then
                printf "${REDRED}INVALID number of cores, must be integer${NCNC}\n"
                return 3
            fi

            printf "\"n_cores\":\"$n_cores\",\n" >> $jfile   
            ;;


        "1")

            # Selects the system
            declare -A available_systems=( ["1"]="Comet" ["2"]="Stampede2" ["3"]="Lonestar5")
            printf "Select system:\n"
            printf "  [1] Comet\n  [2] Stampede2\n  [3] Lonestar5\n\n"
            read selected_system

            if [[ ! $selected_system =~ ^(1|2|3)$  ]]; then
                printf "${REDRED}Please enter '1', '2', or '3'${NCNC}\n"
                return 1
            fi

            system_to_be_used=${available_systems["$selected_system"]}
            printf "\"sc_system\":\"$system_to_be_used\",\n" >> $jfile



            if [ "$compile_commands" -ne "0" ]; then
                printf "\"CC\":\"$compile_commands\",\n" >> $jfile
                printf "\"Job\":\"Compile\",\n" >> $jfile


                # Queue, n-cores, n_nodes are not relevant
                printf "\"sc_queue\":\"NA\",\n" >> $jfile
                printf "\"n_nodes\":\"1\",\n" >> $jfile
                printf "\"n_cores\":\"1\",\n" >> $jfile

            fi


            if [ "$run_commands" -ne "0" ]; then
                printf "\"RC\":\"$run_commands\",\n" >> $jfile
                printf "\"Job\":\"Run\",\n" >> $jfile

                # Selects the queues
                # Marked as system,number. i.e. : Stampede2 normal = 2,1

                declare -A queues=(["1,1"]="gpu-shared" ["1,2"]="gpu" ["1,3"]="debug" ["1,4"]="compute"
                                    ["2,1"]="normal" ["2,2"]="development" ["2,3"]="flat-quadrant" ["2,4"]="skx-dev" ["2,5"]="skx-normal"
                                    ["3,1"]="normal" ["3,2"]="development" ["3,3"]="gpu" ["3,4"]="vis"
                                    )

                printf "Select queue:\n"
                valid_queues=""

                for k in "${!queues[@]}"
                do
                    if [[ ! "$k" =~ ^"$selected_system""," ]]; then
                        continue
                    fi

                    numbered_queue=${k/$selected_system,/}
                    valid_queues="$valid_queues""  [$numbered_queue] ${queues[$k]}\n"
                done

                printf "$valid_queues\n" | sort

                read user_chosen_queue

                if [ -z ${queues["$selected_system,$user_chosen_queue"]} ]; then
                    printf "${REDRED}INVALID queue${NCNC}\n"
                    return 3
                fi

                queue_to_be_used=${queues["$selected_system,$user_chosen_queue"]}
                printf "\"sc_queue\":\"$queue_to_be_used\",\n" >> $jfile


                # Select nodes and cores
                printf "Select number of nodes: "
                read n_nodes

                if [[ ! "$n_nodes" =~ ^[1-9][0-9]*$ ]]; then
                    printf "${REDRED}INVALID number of nodes, must be integer${NCNC}\n"
                    return 3
                fi

                printf "\"n_nodes\":\"$n_nodes\",\n" >> $jfile

                printf "Select number of cores: "
                read n_cores

                if [[ ! "$n_cores" =~ ^[1-9][0-9]*$ ]]; then
                    printf "${REDRED}INVALID number of cores, must be integer${NCNC}\n"
                    return 3
                fi

                printf "\"n_cores\":\"$n_cores\",\n" >> $jfile

            fi

            ;;


        "0")
            # No commands submitted
            printf "${REDRED}INVALID job, no commands provided${NCNC}\n\n"
            rm -rf "$newdir"*
            return 2
            ;;
    esac


    # Asks the user for a time estimate in the form HH:MM:SS
    if [ "$run_commands" -ne "0" ]; then

        printf "What is the time estimate for the job (HH:MM:SS): "
        read runtime

        if [[ ! "$runtime" =~ [0-9]{2}:[0-5][0-9]:[0-5][0-9] ]]; then

            printf "${REDRED}INVALID expected runtime, must be in the format HH:MM:SS${NCNC}\n"
            return 3
        fi

        printf "\"runtime\":\"$runtime\",\n" >> $jfile

    else
        # Only compile job, placeholder of 10:00
        # Does not matter, since compile jobs are run in login nodes
        printf "\"runtime\":\"00:10:00\",\n" >> $jfile
    fi


    job_id=$(curl -s http://$MANAGER_NODE:5000/api/jobs/uuid)

    printf "\"ID\":\"$job_id\",\n" >> $jfile
    printf "\"origin\":\"wetty\",\n" >> $jfile
    printf "\"key\":\"wetty\",\n" >> $jfile
    printf "\"modules\":\"$modules_used\",\n" >> $jfile
    printf "\"dirname\":\"$newdir\",\n" >> $jfile
    printf "\"output_files\":\"$output_files\",\n" >> $jfile
    printf "\"Unix_time\":\"$unix_time\",\n" >> $jfile
    printf "\"Date\":\"$YYYYMMDD\"\n}\n" >> $jfile


    zip -r "$newdir".zip "$newdir"
    printf "\n\n"

    # Uploads the result to Greyfish
    curl -s -F file=@"$newdir".zip http://$GS:2000/grey/upload/$GK_slurm/commonuser/jobs_left

    # Uploads job to server
    curl -s -X POST -H "Content-Type: application/json" -d @$jfile http://$MANAGER_NODE:5000/api/jobs/new

    rm -rf "$newdir"*

    printf "\nJobs uploaded and waiting to be executed"

    printf "\n\n"
}
