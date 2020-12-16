"""
BASICS

Creates a JSON file with the data that is required
Useless for the web interface, which may not have permission to write files
Assumes all fields exist
"""


import datetime
import json





# Compile jobs interface
# path_to_json_file (str): Full path to the json file, excluding the file at the end and the slash
# full_data (dict) (str): Contains the full data
# job_type (str)
def json_to_file(path_to_json_file, full_data):

    A = full_data

    with open(path_to_json_file+"/meta.json", "w") as jf:
        jf.write(json.dumps(A))
