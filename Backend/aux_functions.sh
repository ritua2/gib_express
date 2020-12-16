#!/bin/bash


# Calls the JSON parser
function jparser {
    python "$currentdir/json_parser.py" "$@"
}




# Ensures that a JSON file contains a certain field (no spaces)
# Leaves program if not
function enforce_json_field {

    json_file_path="$1"
    field_to_check="$2"

    if [[ $(jparser "$1" "$2") =~ ^("Incorrect Number of Arguments"|"File or key do not exist")$ ]]; then
        printf "\033[0;31mError: ""$(jparser "$1" "$2")""\033[0m\n"
        exit
    fi
}


# Ensures that a JSON file contains a certain field (no spaces)
# Returns "False" if not
function soft_enforce_json_field {

    json_file_path="$1"
    field_to_check="$2"

    if [[ $(jparser "$1" "$2") = "File or key do not exist" ]]; then
        printf "False"
    else
        printf "True"
    fi
}



# Enforces that two lists in a JSON file have the same length
function enforce_same_length_json_lists {

    json_file_path="$1"
    field1="$2"
    field2="$3"

    l1=$(jparser "$json_file_path" "$field1" "len")
    l2=$(jparser "$json_file_path" "$field2" "len")

    if [[ $l1 != $l2 ]]; then
        printf "\033[0;31mError: Both lists have different lengths\033[0m\n"
        exit
    fi
}



# Prints the elements in JSON list, one per line 
function json_list_by_line {
    jparser "$1" "$2" "each"
}


# Prints the JSON list nth element
function json_list_elem {
    jparser "$1" "$2" "elem" "$3"
}


# Computes the checksum of a file
# Returns the first 8 digits
function checksum8 {
    cat "$1" | sha256sum |cut -c1-8
}


# Updates the status of a job on the server
function update_job_status {


    curl -s -X POST -H "Content-Type: application/json" -d '{"key":"'"$orchestra_key"'", "job_ID":"'"$1"'", "status":"'"$2"'", "error":"'"$3"'"}' \
        http://$manager_node_ip:5000/api/jobs/status/update
}


# Updates the execution time of a job on the server
function update_job_execution_time {


    curl -s -X POST -H "Content-Type: application/json" -d '{"key":"'"$orchestra_key"'", "job_ID":"'"$1"'", "sc_execution_time":"'"$2"'", "notes_sc":"'"$3"'"}' \
        http://$manager_node_ip:5000/api/jobs/status/update_execution_time
}
