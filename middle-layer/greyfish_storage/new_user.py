#!/usr/bin/env python3

"""
BASICS

Creates a new user, specified by their token
If the user already exists, an error result is returned
"""

import os, shutil
from flask import Flask, request
import base_functions as bf

app = Flask(__name__)
GREYFISH_FOLDER = os.environ['greyfish_path']+"/sandbox/"


# toktok (str): User token
@app.route("/grey/create_user/<gkey>/<toktok>")
def create_user(toktok, gkey):

    # Gets the IP address
    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        # Records all failed logins
        return "INVALID key, cannot create a new user"

    try:
        os.makedirs(GREYFISH_FOLDER+'DIR_'+str(toktok))

        return "Greyfish cloud storage now available"
    except:
        return "User already has an account"


# Deletes an entire user directory
@app.route("/grey/delete_user/<gkey>/<toktok>")
def delete_user(toktok, gkey):

    IP_addr = request.environ['REMOTE_ADDR']

    if not bf.valid_key(gkey, toktok):
        return "INVALID key, cannot create a new user"

    try:
        shutil.rmtree(GREYFISH_FOLDER+'DIR_'+str(toktok))

        return "User files and data have been completely deleted"
    except:
        return "User does not exist"


if __name__ == '__main__':
   app.run()
