#!/usr/bin/env python3

"""
BASICS

Returns user files or information about them
"""

from flask import Flask, request, jsonify, send_file, after_this_request
import os, sys, shutil
import tarfile
from werkzeug.utils import secure_filename

import base_functions as bf
import checksums as ch






app = Flask(__name__)
GREYFISH_FOLDER = os.environ['greyfish_path']+"/sandbox/"
CURDIR = dir_path = os.path.dirname(os.path.realpath(__file__)) # Current directory



# Checks if reef cloud storage is available
@app.route('/grey/status')
def api_operational():
    return 'External Greyfish cloud storage is available'


# Returns a json object of all the files obtained from the user
@app.route('/grey/all_user_files/<gkey>/<toktok>')
def all_user_files(toktok, gkey):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    return jsonify(bf.structure_in_json(GREYFISH_FOLDER+'DIR_'+toktok))


# Returns the contents of an entire directory
@app.route('/grey/user_files/<gkey>/<toktok>/<DIR>')
def user_files(toktok, gkey, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    # Accounts for users without a sandbox yet
    try:
        return jsonify(bf.structure_in_json(GREYFISH_FOLDER+'DIR_'+toktok+'/'+'/'.join(DIR.split('++'))))

    except:
        return 'Sandbox not set-up, create a sandbox first'


# Uploads one file
# Directories must be separated by ++

@app.route("/grey/upload/<gkey>/<toktok>/<DIR>", methods=['POST'])
def result_upload(toktok, gkey, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    file = request.files['file']
    fnam = file.filename

    # Avoids empty filenames and those with commas
    if fnam == '':
       return 'INVALID, no file uploaded'
    if ',' in fnam:
       return "INVALID, no ',' allowed in filenames"

    # Ensures no commands within the filename
    new_name = secure_filename(fnam)
    if not os.path.exists(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))):
        os.makedirs(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')))

    file.save(os.path.join(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')), new_name))
    return 'File succesfully uploaded to Greyfish'


# Deletes a file already present in the user
@app.route('/grey/delete_file/<gkey>/<toktok>/<FILE>/<DIR>')
def delete_file(toktok, gkey, FILE, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    try:       
        os.remove(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'+str(FILE))
        return 'File succesfully deleted from Greyfish storage'

    except:
        return 'File is not present in Greyfish'


# Deletes a directory
@app.route("/grey/delete_dir/<gkey>/<toktok>/<DIR>")
def delete_dir(toktok, gkey, DIR):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"

    try:
        shutil.rmtree(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/')
        return "Directory deleted"
    except:
        return "User directory does not exist"


# Returns a file
@app.route('/grey/grey/<gkey>/<toktok>/<FIL>/<DIR>')
def grey_file(gkey, toktok, FIL, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    USER_DIR = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'
    if str(FIL) not in os.listdir(USER_DIR):
       return 'INVALID, File not available'

    return send_file(USER_DIR+str(FIL), as_attachment=True)


# Uploads one directory, it the directory already exists, then it deletes it and uploads the new contents
# Must be a tar file
@app.route("/grey/upload_dir/<gkey>/<toktok>/<DIR>", methods=['POST'])
def upload_dir(gkey, toktok, DIR):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    file = request.files['file']
    fnam = file.filename

    # Avoids empty filenames and those with commas
    if fnam == '':
        return 'INVALID, no file uploaded'
    if ',' in fnam:
        return "INVALID, no ',' allowed in filenames"

    # Untars the file, makes a directory if it does not exist
    if ('.tar.gz' not in fnam) and ('.tgz' not in fnam):
        return 'ERROR: Compression file not accepted, file must be .tgz or .tar.gz'

    new_name = secure_filename(fnam)

    try:

        if os.path.exists(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))):
            shutil.rmtree(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')))

        os.makedirs(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')))
        file.save(os.path.join(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')), new_name))
        tar = tarfile.open(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'+new_name)
        tar.extractall(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++')))
        tar.close()
        os.remove(GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'+new_name)


    except:
        return "Could not open tar file" 

    return 'Directory succesfully uploaded to Greyfish'


# Downloads a directory
# Equivalent to downloading the tar file, since they are both equivalent
@app.route('/grey/grey_dir/<gkey>/<toktok>/<DIR>')
def grey_dir(gkey, toktok, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
        return 'INVALID, User directory does not exist'

    USER_DIR = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'

    if not os.path.exists(USER_DIR):
        return 'INVALID, Directory not available'

    os.chdir(USER_DIR)

    tar = tarfile.open("summary.tar.gz", "w:gz")
    for ff in os.listdir('.'):
        tar.add(ff)
    tar.close()

    os.chdir(CURDIR)
    
    return send_file(USER_DIR+"summary.tar.gz")



# Downloads a directory with a checksum as a tar file
# The file is name after the first 8 characters of the checksum
# The tar file is moved onto a temporary directory afterwards, where it can be deleted if the checksum is correct
@app.route('/grey/download_checksum_dir/<gkey>/<toktok>/<DIR>')
def download_checksum_dir(gkey, toktok, DIR=''):

    IP_addr = request.environ['REMOTE_ADDR']
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if str('DIR_'+toktok) not in os.listdir(GREYFISH_FOLDER):
       return 'INVALID, User directory does not exist'

    USER_DIR = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/'+'/'.join(DIR.split('++'))+'/'

    if not os.path.exists(USER_DIR):
       return 'INVALID, Directory not available'

    os.chdir(USER_DIR)

    tar = tarfile.open("summary.tar.gz", "w:gz")
    to_be_tarred = [x for x in os.listdir('.') if x != "summary.tar.gz"]

    for ff in to_be_tarred:
        tar.add(ff)
        os.remove(ff)
    tar.close()

    checksum8_name = ch.sha256_checksum("summary.tar.gz")[:8]+".tar.gz"
    checksum_dir = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/checksum_files/'

    # If the temporary directory does not exist, it creates it
    if not os.path.isdir(checksum_dir):
        os.makedirs(checksum_dir)

    shutil.move("summary.tar.gz", checksum_dir + checksum8_name)
    os.chdir(CURDIR)

    return send_file(checksum_dir + checksum8_name, as_attachment=True)



# Deletes a checksum file given its file name
@app.route('/grey/delete_checksum_file/<gkey>/<toktok>/<FILE>')
def delete_checksum_file(toktok, gkey, FILE):

    IP_addr = request.environ['REMOTE_ADDR']
    checksum_dir = GREYFISH_FOLDER+'DIR_'+str(toktok)+'/checksum_files/'
    if not bf.valid_key(gkey, toktok):
        return "INVALID key"
    if not os.path.exists(checksum_dir+FILE):
        return 'Checksum file is not present in Greyfish'
    
    os.remove(checksum_dir+FILE)
    return 'Checksum file succesfully deleted from Greyfish storage'



if __name__ == '__main__':
    app.run()
