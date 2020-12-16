#!/usr/bin/env python3

"""
BASICS

Admin functionalities
"""


from flask import Flask, request
import glob
import os
import time
import base_functions as bf
import remove_files as rmf



app = Flask(__name__)
GREYFISH_FOLDER = os.environ['greyfish_path']+"/sandbox/"





# Gets a list of all available users, comma-separated
# If there are no users, it will return an emprty string: ''
@app.route('/grey/admin/users/usernames/all', methods=['POST'])
def all_usernames():

    if not request.is_json:
        return "INVALID: Request is not json"

    proposal = request.get_json()

    # Checks the required fields
    # self_ID (str) refers to the self-identity of the user, only useful for checking with Redis in case a temporary token is used 
    req_fields = ["key", "self_ID"]
    req_check = bf.l2_contains_l1(req_fields, proposal.keys())

    if req_check != []:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in req_check])

    gkey = proposal["key"]
    self_ID = proposal["self_ID"]

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, self_ID):
        bf.failed_login(gkey, IP_addr, self_ID, "Get all usernames")
        return "INVALID key"

    bf.greyfish_admin_log(IP_addr, self_ID, "Get all usernames")
    # Checks the number of subdirectories, one assigned per user 
    return ','.join([f.path.replace(GREYFISH_FOLDER+"DIR_", '') for f in os.scandir(GREYFISH_FOLDER) if f.is_dir()])    



# Removes all files older than X seconds
@app.route('/grey/admin/purge/olderthan/<Xsec>', methods=['POST'])
def purge_olderthan(Xsec):

    if not request.is_json:
        return "INVALID: Request is not json"

    proposal = request.get_json()

    # Checks the required fields
    # self_ID (str) refers to the self-identity of the user, only useful for checking with Redis in case a temporary token is used 
    req_fields = ["key", "self_ID"]
    req_check = bf.l2_contains_l1(req_fields, proposal.keys())

    if req_check != []:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in req_check])

    gkey = proposal["key"]
    self_ID = proposal["self_ID"]

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, self_ID):
        bf.failed_login(gkey, IP_addr, self_ID, "Get all usernames")
        return "INVALID key"

    try:
        XS = float(Xsec)
    except:
        return Xsec+" cannot be transformed into a float"

    # Gets the list of user directories
    user_dirs = [f.path for f in os.scandir(GREYFISH_FOLDER) if f.is_dir()]
    now = time.time()
    files_deleted = 0

    # Purges empty files
    for udir in user_dirs:
        for ff in glob.iglob(udir+"/**/*", recursive=True):
            if (os.stat(ff).st_mtime < (now - XS)) and (os.path.isfile(ff)):
                os.remove(ff)
                files_deleted += 1

        # Purges empty subdirectories for the users, does not delete the user directory itself
        rmf.remove_empty_dirs(udir, udir)

    bf.greyfish_admin_log(IP_addr, self_ID, "Purged old files", str(files_deleted))
    return "Deleted "+str(files_deleted)+" files"




if __name__ == '__main__':
   app.run()


