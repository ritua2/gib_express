#!/usr/bin/env python3

"""
BASICS

After receiving a ping request, calls a greyfish system for the output files
"""

import os, sys, shutil
from flask import Flask, request
import requests
import tarfile
import uuid


app = Flask(__name__)
DOWNLOAD_PATH = os.environ['output_data_path']
CURDIR = dir_path = os.path.dirname(os.path.realpath(__file__)) # Current directory
PSSWRD = os.environ['listener_password']


# Provided a tar file path, it will untar all its contents into a second directory
# It will also delete the tar file
# tpath, destination (str): Full paths
def unpack_tar(tpath, destination):

    tar = tarfile.open(tpath)
    tar.extractall(destination)
    tar.close()
    os.remove(tpath)



@app.route("/listener/api/users/output_data", methods=['POST'])
def output_data():

    # Gets the entire output 
    INFO = request.get_json()
    greyfish_url = os.environ['greyfish_url']
    greyfish_key = os.environ['greyfish_key']

    """
    {
    # REQUIRED
    Job_ID:"str"
    User: "str"
    password: "str"
    OUTPUT_DIRS : [...] # Empty if nothing, each directory must be done following greyfish convention
    EXTRA_FILES :[{path:'',filename;''}, ...] # Empty if nothing, each path must be written with greyfish syntax 

    # OPTIONAL
    greyfish_url = "new url"
    greyfish_key = "new password"
    
    }
    """

    try:
        Job_ID = INFO['Job_ID']
        User_ID = INFO['User']
        EXTRA_DIRS = INFO['OUTPUT_DIRS']
        EXTRA_FILES = INFO['OUTPUT_FILES']
        psword = INFO["password"] 
    except:
        return "INVALID, mandatory fields not provided"


    # Password check
    if psword != PSSWRD:
        return "INVALID password"


    # Deals with the optional parameters for greyfish
    if 'greyfish_url' in INFO:
        greyfish_url = INFO['greyfish_url'].replace("http://", '')
    if 'greyfish_key' in INFO:
        greyfish_key = INFO['greyfish_key']

    URL="http://"+greyfish_url+":2000/grey/grey_dir/"+greyfish_key+"/"+User_ID+"/"+Job_ID

    # Downloads the required data
    fnam = "/listener/tmp/"+str(uuid.uuid4())+".tar.gz"

    r = requests.get(URL, stream=True)
    with open(fnam, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024): 
            if chunk: # filter out keep-alive new chunks
                f.write(chunk)

    JOB_FOLDER = DOWNLOAD_PATH+"/"+User_ID+"/"+Job_ID

    try:
        # Deletes any folders with outputs corresponding to the sam Job_ID
        if os.path.exists(JOB_FOLDER):
            shutil.rmtree(JOB_FOLDER)

        os.makedirs(JOB_FOLDER)
        unpack_tar(fnam, JOB_FOLDER)

    except:
        shutil.rmtree(JOB_FOLDER)
        return "Could not read output data, greyfish key may be incorrect"


    # Downloads all the extra directories within the same folder but one folder down
    # Any files already present with the same name will be rewritten
    for D2 in EXTRA_DIRS:
        URL = "http://"+greyfish_url+":2000/grey/grey_dir/"+greyfish_key+"/"+User_ID+"/"+D2
        fnam = "/listener/tmp/"+str(uuid.uuid4())+".tar.gz"
        r = requests.get(URL, stream=True)
        with open(fnam, 'wb') as f:
            for chunk in r.iter_content(chunk_size=1024): 
                if chunk: # filter out keep-alive new chunks
                    f.write(chunk)
        unpack_tar(fnam, JOB_FOLDER)


    # Downloads all the extra files
    # Any files already present with the same name will be rewritten
    for F2 in EXTRA_FILES:
        URL = "http://"+greyfish_url+":2000/grey/grey/"+greyfish_key+"/"+User_ID+"/"+F2['filename']+"/"+F2['path']
        r = requests.get(URL, stream=True)
        with open(JOB_FOLDER+'/'+F2['filename'], 'wb') as f:
            for chunk in r.iter_content(chunk_size=1024): 
                if chunk: # filter out keep-alive new chunks
                    f.write(chunk)

    return "Data received by IPT"



if __name__ == '__main__':
    app.run()
