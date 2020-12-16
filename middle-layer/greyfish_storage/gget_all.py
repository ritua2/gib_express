#!/usr/bin/env python3

"""
BASICS

Returns all the files the user has in the form of a tar file
"""

import os
from flask import Flask, send_file, jsonify, request
import tarfile

import base_functions as bf



app = Flask(__name__)
GREYFISH_FOLDER = os.environ['greyfish_path']+"/sandbox/"
CURDIR = dir_path = os.path.dirname(os.path.realpath(__file__)) # Current directory


# JSON object with all the files the user has
@app.route('/grey/all_user_files/<gkey>/<toktok>')
def all_user_files(toktok, gkey):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    return jsonify(bf.structure_in_json(GREYFISH_FOLDER+'DIR_'+toktok))


# Downloads a tar file with all the contents
@app.route('/grey/get_all/<gkey>/<toktok>')
def get_all(toktok, gkey):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    USER_DIR = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'
    os.chdir(USER_DIR)

    user_data = [x for x in os.listdir('.') if x != 'alldata.tar.gz']

    tar = tarfile.open("alldata.tar.gz", "w:gz")

    for content in user_data:
    	tar.add(content)
    tar.close()

    os.chdir(CURDIR)

    return send_file(USER_DIR+"alldata.tar.gz")



if __name__ == '__main__':
   app.run()
