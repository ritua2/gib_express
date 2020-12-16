#!/usr/bin/env python3

"""
BASICS

Substitutes the current content for a user for new content
"""


import os, shutil
from flask import Flask, send_file, request, jsonify
import base_functions as bf
from werkzeug.utils import secure_filename
import tarfile



app = Flask(__name__)
GREYFISH_FOLDER = os.environ['greyfish_path']+"/sandbox/"



@app.route("/grey/push_all/<gkey>/<toktok>", methods=['POST'])
def push_all(toktok, gkey):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    try:
        file = request.files['file']
    except:
        return "No file uploaded"

    fnam = file.filename

    # Avoids empty filenames and those with commas
    if fnam == '':
       return 'INVALID, no file uploaded'

    USER_DIR = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'
    new_name = secure_filename(fnam)


    # Must be a valid tar file
    try:
        file.save(USER_DIR + new_name)
        tar = tarfile.open(USER_DIR+new_name)
        tar.getmembers()
    except:
        os.remove(USER_DIR+new_name)
        return "Tar file cannot be opened, must be .tgz or .tar.gz"



    user_data = [USER_DIR+x for x in os.listdir(USER_DIR) if x != fnam]

    # Deletes all current data and untars the new files
    for content in user_data:

        if os.path.isdir(content):
            shutil.rmtree(content)
            continue
        os.remove(content)

    tar.extractall(USER_DIR)
    tar.close()
    os.remove(USER_DIR+new_name)

    return 'User contents updated in Greyfish'


if __name__ == '__main__':
   app.run()
