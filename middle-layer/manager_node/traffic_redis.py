"""
BASICS

Redirects a user, doing all the necessary actions
Checks that a user is valid after login into wetty
"""


from flask import after_this_request, Flask, jsonify, redirect, request, send_file
import hashlib
import json
import os, shutil
import random
import re
import redis
import requests
import signal
import subprocess
import tarfile
from urllib.parse import unquote
import uuid
from werkzeug.utils import secure_filename
import zipfile

import email_common as ec
import ldap_validate
import mysql_interactions as mints
import web_data_to_json_file





URL_BASE = os.environ["URL_BASE"]
REDIS_AUTH = os.environ["REDIS_AUTH"]
orchestra_key = os.environ["orchestra_key"]
PROJECT = os.environ["PROJECT"]
GREYFISH_URL = URL_BASE
GREYFISH_REDIS_KEY = REDIS_AUTH
CURDIR = os.path.dirname(os.path.realpath(__file__)) # Current directory



hhmmss_pattern = re.compile("^[0-9]{2}:[0-5][0-9]:[0-5][0-9]$")




# Adds to the list of available containers
def change_container_availability(a1):
    misc = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)
    misc.incrby("Available containers", a1)


def l2_contains_l1(l1, l2):
    return[elem for elem in l1 if elem not in l2]


def valid_adm_passwd(apass):
    if apass == orchestra_key:
        return True
    else:
        return False


# Gets the keys in a certain redis database
# rdb (Redis connection object)
def redkeys(rdb):
    return [x.decode("UTF-8") for x in rdb.keys()]


# Checks if a particular key exists in a redis DB
# tested_key (str): Key to be checked
def red_key_check(rdb, tested_key):
    if rdb.get(tested_key) == None:
        return False
    else:
        return True


def available_instances():
    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    instances_av = []
    for insip in redkeys(r_occupied):
        abav = r_occupied.hget(insip, "Available").decode("UTF-8")
        if abav == "Yes":
            instances_av.append(insip)

    return instances_av



# Finds the list of occupied ports for certain instance, each port is a string
# instance (str)
def ports_occupied(instance):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    redports = int(r_occupied.hget(instance, "Ports").decode("UTF-8"))
    # Shows the ports in binary: 0b100 = 4, and reverses it
    portsn = bin(redports)[2:][::-1]
    pav = []

    for loc, port_used in zip(range(0, len(portsn)), portsn):
        if port_used == "1":
            pav.append(str(7000+loc))

    return pav



# vmip (str): VM IP
def empty_ports(vmip):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    ep = []
    abav = r_occupied.hget(vmip, "Available").decode("UTF-8")
    if abav == "No":
        return ep

    for pn in ports_occupied(vmip):
        ava = r_occupied.hget(vmip, "Available_"+pn).decode("UTF-8")
        if ava == "Yes":
            ep.append(pn)

    return ep

# Fetch if there is any occupied port by a user 
def busy_port_with_curuser(vmip,user_id):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    op = None
    abav = r_occupied.hget(vmip, "Available").decode("UTF-8")
    if abav == "No":
        return op

    for pn in ports_occupied(vmip):
        ava = r_occupied.hget(vmip, "Available_"+pn).decode("UTF-8")
        usr = r_occupied.hget(vmip, "current_user_"+pn).decode("UTF-8")
        if ava == "No" and usr == user_id:
            op=pn
            return op

    return op

# Gets the long key of a wetty container
# vmip (str): VM IPv4
# port_used (str)
def PK_32(vmip, port_used):
    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    return r_occupied.hget(vmip, "id_"+port_used).decode("UTF-8")


# Verifies that a port key key is valid
# vmip (str): VM IPv4
# kk (str): key
# port_used (str)
def Valid_PK(vmip, kk, port_used):
    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    expected_key = r_occupied.hget(vmip, "id_"+port_used).decode("UTF-8")
    if expected_key == kk:
        return True
    else:
        return False



# Checks the port of a 10 character hash
# If the port is not associated with anything, it returns ["NA", 1]
def Porter10(vmip, kk):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    for pn in ports_occupied(vmip):
        expected_key = r_occupied.hget(vmip, "id_"+pn).decode("UTF-8")
        if kk in expected_key:
            return [pn, 0]
    else:
        return ["NA", 1]




# Creates a random string of fixed length
# n (int): length
def random_string(n):

    A = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n",
        "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    random.shuffle(A)

    return "".join(A)[:n]



# Allows or disallows synchronization between the user and the shared wetty volume for a certain VM
# Returns [Server str, Error]
def sync_wetty_volume(vm_ip, vm_port, username, wetty_key, sync_action="start"):

    miniserver_port = str(int(vm_port)+100)
    req = requests.post("http://"+vm_ip+":"+miniserver_port+"/user/volume/sync", data={"key": wetty_key, "username":username,
                                                                        "action":sync_action})
    return req.text



# Computes the SHA 256 checksum of a file given its name
# Based on https://gist.github.com/rji/b38c7238128edf53a181
def sha256_checksum(filename, block_size=65536):
    sha256 = hashlib.sha256()
    with open(filename, 'rb') as f:
        for block in iter(lambda: f.read(block_size), b''):
            sha256.update(block)
    return sha256.hexdigest()



# Translates an IP into hostname if this has been pre-defined by the user
# If not, it returns the IP
# IP_to_be_translated (string) -> defined_hostname (str)
def IP_to_hostname(IP_to_be_translated):

    r_hostnames = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=9)

    possible_hostname = r_hostnames.get(IP_to_be_translated)

    if possible_hostname == None:
        # No translation or the IP has not been added
        return IP_to_be_translated
    else:
        return possible_hostname.decode("UTF-8")



app = Flask(__name__)



####################
# WETTY ACTIONS
####################


# Returns the startup script
@app.route("/api/scripts/startup", methods=['GET'])
def startup_supplier():
    return send_file("/scripts/startup.sh")



# Returns the project name
@app.route("/api/project/name", methods=['GET'])
def project_name():
    return PROJECT



# Returns a string of available docker containers
@app.route("/api/status/containers/available", methods=['GET'])
def AvCon_API():
    misc = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)
    return misc.get("Available containers").decode("UTF-8")



@app.route("/api/active", methods=['GET'])
def active():
    return "Orchestration node is active"



# Requests an available container for a user
@app.route("/api/assign/users/<user_id>", methods=['POST'])
def assigner(user_id):

    r_redirect_cache = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=1)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "sender"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Checks all instances to restrict one port per user
    for instance in available_instances():

        # Checks if any port is assigned to current user
        occupied_port=busy_port_with_curuser(instance,user_id)
        if occupied_port is not None:
            return instance+":"+occupied_port

    # Checks all instances with at least one port open
    for instance in available_instances():

        # Adds '_' at the end
        instance_ = instance+"_"

        # Checks only ports not assigned yet
        for emp in empty_ports(instance):
            if red_key_check(r_redirect_cache, instance_+emp):
                # Ignores ports in cache
                continue

            # Sets the instance as occupied, the server now has 20 s to redirect the user
            r_redirect_cache.setex(instance_+emp, 20, user_id)
            return instance+":"+emp

    # All instances are occupied
    else:
        return "False"



# Redirects a user after an available IP has been provided to him
# target_ip may also be the hostname
@app.route("/api/redirect/users/<user_id>/<target_ip>", methods=['GET'])
def redirect_to_wetty(user_id, target_ip):

    r_redirect_cache = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=1)

    target_ip = IP_to_hostname(target_ip)

    # Finds if the user is attached to any instance
    available_redirect = [x.decode("UTF-8") for x in r_redirect_cache.keys(target_ip+"_*")]
    for avred in available_redirect:

        expected_user = r_redirect_cache.get(avred)
        if expected_user == None:
            # Avoids race conditions
            continue

        if expected_user.decode("UTF-8") == user_id:
            user_instance = avred
            break
    else:
        return "INVALID: "+target_ip+" has already been assigned to another user"

    # Deletes the copy in Redis
    r_redirect_cache.delete(user_instance)
    # Gets the port number
    user_instance = user_instance.replace("_", ":")
    # 20 s to complete redirect
    r_redirect_cache.setex(user_instance, 20, user_id)
    
    return "Redirecting https://"+user_instance+"/wetty"



# Adds a new container by port and IP
@app.route("/api/instance/attachme", methods=['POST'])
def attachme():

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "sender", "port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    # There may be multiple containers per instance
    iport = ppr["port"]
    sender_ID = ppr["sender"]
    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])

    if not valid_adm_passwd(key):
        return "INVALID key"

    instances = redkeys(r_occupied)
    port_number = int(iport)

    # Instance IP has already been added
    if reqip in instances:
        occports = ports_occupied(reqip)
        if not (iport in occports):
            r_occupied.hincrby(reqip, "Ports", 2**((port_number-7000)%10))
            r_occupied.hset(reqip, "Available", "Yes")
            r_occupied.hset(reqip, "Available_"+iport, "Yes")
            r_occupied.hset(reqip, "current_user_"+iport, "Empty")
            r_occupied.hset(reqip, "id_"+iport, sender_ID)
            change_container_availability(1)
            return "Added port "+iport

        else:
            return "Port has already been added"

    else:

        # All IPs are stored in Redis with the following data:
        # Available, id, current_user, whoami_count, address
        new_instance = {
                        "address":reqip, # Could be a hostname
                        "IP":request.environ['REMOTE_ADDR'], # IP
                        "Available":"Yes",
                        "Ports":str(int(2**((port_number-7000)%10))),

                        # Varies per instance
                        "id_"+iport:sender_ID,
                        "current_user_"+iport:"Empty",
                        "Available_"+iport:"Yes"
        }

        r_occupied.hmset(reqip, new_instance)
        change_container_availability(1)
        return "Instance correctly attached"



# Removes the current IP as a wetty instance
@app.route("/api/instance/removeme", methods=['POST'])
def removeme():

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])

    if not valid_adm_passwd(key):
        return "INVALID key"

    if not (reqip in redkeys(r_occupied)):
        return "INVALID, instance is not associated with the project"

    change_container_availability(-1)
    r_occupied.delete(reqip)
    return "Instance removed"



# Removes a port from an instance
# If the instance has no more ports, it deletes it
# This is an instantaneous action and it does not matter if there is a user already in the instance
@app.route("/api/instance/remove_my_port", methods=['POST'])
def remove_my_port():

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "sender", "port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    # There may be multiple containers per instance
    iport = ppr["port"]
    sender_ID = ppr["sender"]
    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])

    if not valid_adm_passwd(key):
        return "INVALID key"

    instances = redkeys(r_occupied)
    port_number = int(iport)
    if not (reqip in redkeys(r_occupied)):
        return "INVALID, instance is not associated with the project"

    # Port must be added
    occports = ports_occupied(reqip)
    if not (iport in occports):
        return "Port is not associated with the instance"

    if (len(occports) == 1) and (Valid_PK(reqip, sender_ID, iport)):
        # If last port, delete the instance from database
        change_container_availability(-1)
        r_occupied.delete(reqip)
        return "Instance removed"

    else:
        # Check for valid key
        if Valid_PK(reqip, sender_ID, iport):
            # Removes all the provided characteristics
            r_occupied.hdel(reqip, "Available_"+iport, "current_user_"+iport, "id_"+iport)
            # Changes the port number
            r_occupied.hincrby(reqip, "Ports", -1*2**((port_number-7000)%10))
            change_container_availability(-1)
            return "Removed port from instance"



# Frees an instance
# Must be called from springIPT
@app.route("/api/instance/free", methods=['POST'])
def free_instance():

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    greyfish_server = redis.Redis(host=GREYFISH_URL, port=6379, password=GREYFISH_REDIS_KEY, db=3)
    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "IP", "Port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqip = IP_to_hostname(ppr["IP"])
    port = str(ppr["Port"])

    if not valid_adm_passwd(key):
        return "INVALID key"

    if not r_occupied.hexists(reqip, "Available_"+port):
        return "INVALID, port not attached"

    if r_occupied.hget(reqip, "Available_"+port).decode("UTF-8") != "No":
        return "INVALID, wetty instance is empty at the moment"

    current_wetty_user = r_occupied.hget(reqip, "current_user_"+port).decode("UTF-8")
    miniserver_port = str(int(port) + 100)

    # Generates a single-use greyfish token
    new_token = random_string(24)
    greyfish_server.setex(new_token, 60, current_wetty_user)

    wetty_key = PK_32(reqip, port)

    # Issues a call to the wetty miniserver
    # The miniserver will then prepare the instance for a new user
    sync_wetty_volume(reqip, port, current_wetty_user, wetty_key, "stop")
    req = requests.post("http://"+reqip+":"+miniserver_port+"/user/purge", data={"key": wetty_key, "username":current_wetty_user,
                                                                                "greyfish_url":URL_BASE, "gk":new_token})

    # Frees the instance
    r_occupied.hset(reqip, "Available_"+port, "Yes")
    r_occupied.hset(reqip, "current_user_"+port, "Empty")
    # Sets the instance as globaly available
    r_occupied.hset(reqip, "Available", "Yes")
    change_container_availability(1)

    # Removes the user as occupying a VM
    r_user_to_.delete(current_wetty_user)

    return "Correctly freed instance"
	
	
	
# Called when "Refresh" is clicked, to get the latest image of wetty folder.
# Must be called from springIPT
@app.route("/api/instance/get_latest", methods=['POST'])
def get_instance():

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    greyfish_server = redis.Redis(host=GREYFISH_URL, port=6379, password=GREYFISH_REDIS_KEY, db=3)
    
    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "IP", "Port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqip = IP_to_hostname(ppr["IP"])
    port = str(ppr["Port"])

    if not valid_adm_passwd(key):
        return "INVALID key"

    if not r_occupied.hexists(reqip, "Available_"+port):
        return "INVALID, port not attached"

    if r_occupied.hget(reqip, "Available_"+port).decode("UTF-8") != "No":
        return "INVALID, wetty instance is empty at the moment"

    current_wetty_user = r_occupied.hget(reqip, "current_user_"+port).decode("UTF-8")
    miniserver_port = str(int(port) + 100)

    # Generates a single-use greyfish token
    new_token = random_string(24)
    greyfish_server.setex(new_token, 60, current_wetty_user)

    wetty_key = PK_32(reqip, port)

    # Issues a call to the wetty miniserver
    # The miniserver will then prepare the instance for a new user
    #sync_wetty_volume(reqip, port, current_wetty_user, wetty_key, "stop")
    req = requests.post("http://"+reqip+":"+miniserver_port+"/get/latest", data={"key": wetty_key, "username":current_wetty_user,
                                                                                "greyfish_url":URL_BASE, "gk":new_token})

    return "Correctly sent data"
	
	
	
	
	



# Returns the current user
# Sets up the Redis table with the instance as occupied
@app.route("/api/instance/whoami/<uf10>", methods=['GET'])
def whoami(uf10):


    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    r_redirect_cache = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=1)

    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])
    user_port, err = Porter10(reqip, uf10)

    if err:
        # If it does not exist, the user is either already there or the VM is not attached
        return "Empty"

    proper_location = reqip+":"+user_port
    expected_user = r_redirect_cache.get(proper_location)

    if expected_user == None:
        return "Empty"

    # Deletes the cache
    r_redirect_cache.delete(proper_location)
    # Sets the port as occupied
    r_occupied.hset(reqip, "Available_"+user_port, "No")
    r_occupied.hset(reqip, "current_user_"+user_port, expected_user.decode("UTF-8"))

    # If all ports are occupied, it sets the available tag as no
    if len(empty_ports(reqip)) == 0:
        r_occupied.hset(reqip, "Available", "No")
    
    # Sets the user as already occupying a container
    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)
    r_user_to_.hset(expected_user.decode("UTF-8"), "IP:port", proper_location)

    wetty_key = PK_32(reqip, user_port)
    sync_wetty_volume(reqip, user_port, expected_user.decode("UTF-8"), wetty_key, "start")
    change_container_availability(-1)
    return expected_user.decode("UTF-8")



# Checks if a user is logged in 
# Returns 'False' if not, and the IP:port if yes
@app.route("/api/users/logged_in", methods=['POST'])
def logged_in():

    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "username"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    username = ppr["username"]

    if not valid_adm_passwd(key):
        return "INVALID key"


    # Checks all instances with at least one port open
    if r_user_to_.exists(username) == 0:
        return "False"
    else:
        return r_user_to_.hget(username, "IP:port").decode("UTF-8")



# Sets the container assigned to user X as waiting
@app.route("/api/users/container_wait", methods=['POST'])
def container_wait():

    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "username"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    username = ppr["username"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Finds if the user is logged in
    if r_user_to_.exists(username) == 0:
        return "User is not available at any container"

    user_ip_port_container = r_user_to_.hget(username, "IP:port").decode("UTF-8")
    [ip_used, port_used] = user_ip_port_container.split(":")

    ip_used = IP_to_hostname(ip_used)

    wetty_key = PK_32(ip_used, port_used)

    miniserver_port = str(int(port_used) + 100)

    # Calls the miniserver
    req = requests.post("http://"+ip_used+":"+miniserver_port+"/wait", data={"key": wetty_key, "username":username})
    
    if req.text == "INVALID key":
        return "Could not set wetty terminal as WAIT"

    r_user_to_.hset(username, "WAIT key", req.text)
    return "Set wetty at "+user_ip_port_container+" as WAIT"



# Returns the WAIT key for a user
# Returns false if not
@app.route("/api/users/wetty_wait_key", methods=['POST'])
def wetty_wait_key():

    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "username"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    username = ppr["username"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Checks all instances with at least one port open
    if r_user_to_.exists(username) == 0:
        return "False"
    else:

        if r_user_to_.hexists(username, "WAIT key"):
            return r_user_to_.hget(username, "WAIT key").decode("UTF-8")
        else:
            return "User is logged in, no waiting containers"




# Synchronizes the user container to its attached 
@app.route("/api/users/container_sync", methods=['POST'])
def container_sync_volume():

    r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "username", "action"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    username = ppr["username"]
    action = ppr["action"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    if action not in ["start", "stop"]:
        return "INVALID action. Action '"+action+"' is not allowed. Allowed actions are: 'start', 'stop'."

    # Finds if the user is logged in
    if r_user_to_.exists(username) == 0:
        return "User is not available at any container"

    user_ip_port_container = r_user_to_.hget(username, "IP:port").decode("UTF-8")
    [ip_used, port_used] = user_ip_port_container.split(":")
    ip_used = IP_to_hostname(ip_used)

    wetty_key = PK_32(ip_used, port_used)

    server_response = sync_wetty_volume(ip_used, port_used, username, wetty_key, action)

    return server_response



@app.route("/api/instance/whatsmyip", methods=['GET'])
def whatsmyip():
    return request.environ['REMOTE_ADDR']



# Returns the server public key
@app.route("/api/manager_node/public_key", methods=['GET'])
def public_key():

    with open("rsync_wetty.key.pub", "r") as rsync_pub:
        pkey = rsync_pub.readline()

    return pkey




####################
# GREYFISH ACTIONS
####################



# Returns the location of the greyfish server (without 'http://')
@app.route("/api/greyfish/location", methods=['GET'])
def grey_locator():
    return GREYFISH_URL



# Creates a new key for the user located at the present instance
# Simply returns the key
# Cannot be called from outside the instance
@app.route("/api/greyfish/new/single_use_token/<uf10>", methods=['GET'])
def grey_stoken(uf10):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    greyfish_server = redis.Redis(host=GREYFISH_URL, port=6379, password=GREYFISH_REDIS_KEY, db=3)

    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])
    instances = redkeys(r_occupied)

    if not (reqip in redkeys(r_occupied)):
        return "INVALID: instance not attached"

    pnn, err = Porter10(reqip, uf10)
    if err:
        return "INVALID: port not attached"

    curuser = r_occupied.hget(reqip, "current_user_"+pnn).decode("UTF-8")
    if curuser != "Empty":
        # Creates a random string of characters (24 length), sets it as a token, and returns it
        # Each token will last a maximum of 2 hours
        new_token = random_string(24)
        greyfish_server.setex(new_token, 7200, curuser)
        return new_token

    else:
        return "INVALID user"



# Creates a new key for the user 'commonuser', used to store the job information
# Simply returns the key
# Cannot be called from outside the instance
@app.route("/api/greyfish/new/commonuser_token/<uf10>", methods=['GET'])
def grey_commonuser_token(uf10):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    greyfish_server = redis.Redis(host=GREYFISH_URL, port=6379, password=GREYFISH_REDIS_KEY, db=3)

    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])
    instances = redkeys(r_occupied)

    if not (reqip in redkeys(r_occupied)):
        return "INVALID: instance not attached"

    pnn, err = Porter10(reqip, uf10)
    if err:
        return "INVALID: port not attached"

    curuser = r_occupied.hget(reqip, "current_user_"+pnn).decode("UTF-8")
    if curuser != "Empty":
        # Creates a random string of characters (24 length), sets it as a token, and returns it
        # Each token will last a maximum of 2 hours
        new_token = random_string(24)
        greyfish_server.setex(new_token, 7200, "commonuser")
        return new_token

    else:
        return "INVALID user"



# Creates a temporary key for a greyfish user
@app.route("/api/greyfish/users/<user_id>/create_greyfish_key", methods=['POST'])
def tmp_greyfish_key_for_user(user_id):

    greyfish_server = redis.Redis(host=GREYFISH_URL, port=6379, password=GREYFISH_REDIS_KEY, db=3)

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "user"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Sets a greyfish key for the user for a maximum of 120 s
    new_token = random_string(24)
    greyfish_server.setex(new_token, 120, user_id)

    return new_token



# Uploads a file to a given wetty
@app.route("/api/greyfish/users/<user_id>/upload_file", methods=['POST'])
def upload_file(user_id):

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(["key", "filepath", "IP", "Port"], ppr.keys())

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    filepath = ppr["filepath"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Absolute path starting after username, not including username
    if not os.path.exists("/greyfish/sandbox/DIR_"+user_id+"/"+filepath):
        return "Error, file does not exist"

    [ip_used, port_used] = [ppr["IP"], ppr["Port"]]
    ip_used = IP_to_hostname(ip_used)

    wetty_key = PK_32(ip_used, port_used)

    miniserver_port = str(int(port_used) + 100)

    # Calls the miniserver
    req = requests.post("http://"+ip_used+":"+miniserver_port+"/"+wetty_key+"/upload",
        files={"filename": open("/greyfish/sandbox/DIR_"+user_id+"/"+filepath, "rb")})

    return "File uploaded to wetty"



# Uploads a directory to a given wetty
@app.route("/api/greyfish/users/<user_id>/upload_dir", methods=['POST'])
def upload_dir(user_id):

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    # basepath: Where the dir is stored
    # dirname: Directory in particular that must be uploaded
    check = l2_contains_l1(["key", "basepath", "dirname", "IP", "Port"], ppr.keys())

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    dirname = ppr["dirname"]
    greyfish_path = "/greyfish/sandbox/DIR_"+user_id+"/"+ppr["basepath"]+"/"

    if not valid_adm_passwd(key):
        return "INVALID key"

    # Absolute path starting after username, not including username
    if not os.path.isdir(greyfish_path+dirname):
        return "Error, directory does not exist or is not a directory"

    [ip_used, port_used] = [ppr["IP"], ppr["Port"]]
    ip_used = IP_to_hostname(ip_used)

    wetty_key = PK_32(ip_used, port_used)

    miniserver_port = str(int(port_used) + 100)

    # Creates a compressed file
    os.chdir(greyfish_path)

    tar = tarfile.open("tmp-dir-upload.tar.gz", "w:gz")
    tar.add(dirname)
    tar.close()
    os.chdir(CURDIR)

    with open(greyfish_path+"tmp-dirname.txt", "w") as tmp_dirname_file:
        tmp_dirname_file.write(dirname)

    # Calls the miniserver
    req = requests.post("http://"+ip_used+":"+miniserver_port+"/"+wetty_key+"/upload_dir",
        files={"dirname": open(greyfish_path+"tmp-dir-upload.tar.gz", "rb"),
            "original_dir_name":open(greyfish_path+"tmp-dirname.txt", "rb")})
    os.remove(greyfish_path+"/tmp-dir-upload.tar.gz")
    os.remove(greyfish_path+"/tmp-dirname.txt")

    return "Directory uploaded to wetty"



####################
# JOB ACTIONS
####################


# Returns an UUID
# Can only be called from wetty instances
@app.route("/api/jobs/uuid", methods=['GET'])
def get_uuid():

    reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])
    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

    if reqip.encode("UTF-8") in r_occupied.keys():
        return str(uuid.uuid4())
    else:
        return "INVALID, not a wetty container"


# Receives a job either from wetty or the web interface
# Requires the username and job ID
# Uploads a directory to a given wetty
@app.route("/api/jobs/new", methods=['POST'])
def new_job():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "ID", "User", "origin", "Job", "modules", "output_files", "dirname", "sc_system",
                            "sc_queue", "n_cores", "n_nodes", "runtime"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    username = ppr["User"]

    # Allowed access for:
    #   - Systems with orchestra key, springIPT mainly
    #   - Calls from wetty where the user is a TACC user


    invalid_access = True

    if valid_adm_passwd(key):
        invalid_access = False
    else:
        reqip = IP_to_hostname(request.environ['REMOTE_ADDR'])
        r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

        # Valid IP and user is in the IP
        if (reqip in redkeys(r_occupied)) and (not (mints.get_ip_port(username, reqip)[1])):
            invalid_access = False

    if invalid_access:
        return "INVALID: Access not allowed"


    job_ID = ppr["ID"]
    origin = ppr["origin"]
    job_type = ppr["Job"]
    modules = ppr["modules"]
    output_files = ppr["output_files"]
    dirname = ppr["dirname"]
    sc_system = ppr["sc_system"]
    sc_queue = ppr["sc_queue"]
    n_cores = ppr["n_cores"]
    n_nodes = ppr["n_nodes"]
    runtime = ppr["runtime"]


    # If the user is not TACC, job cannot be submitted
    [type_of_user, error_in_db] = mints.current_user_status(username)
    greyfish_commonuser_job_loc = "/greyfish/sandbox/DIR_commonuser/jobs_left/"+dirname+".zip"


    if error_in_db:

        # Deletes the job data if it exists
        if os.path.exists(greyfish_commonuser_job_loc):
            os.remove(greyfish_commonuser_job_loc)

        return "User is not logged in correctly"

    if type_of_user[0] == "false":

        # Deletes the job data if it exists
        if os.path.exists(greyfish_commonuser_job_loc):
            os.remove(greyfish_commonuser_job_loc)

        return "User is not authorized to submit jobs"



    if hhmmss_pattern.match(runtime) == None:
        return "INVALID: time mut be specified as HH:MM:SS"

    if job_type not in ["Compile", "Run", "Both"]:
        return "INVALID: Job type not accepted, must be 'Compile', 'Run', or 'Both'"


    # Processes the commands
    if job_type == "Compile":

        check_compile = l2_contains_l1(["CC"], ppr_keys)
        if check_compile:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_compile])

        number_compile_instructions = int(ppr["CC"])
        compile_instruction_tags = ["C"+str(c) for c in range(0, number_compile_instructions)]
        check_compile2 = l2_contains_l1(compile_instruction_tags, ppr_keys)
        if check_compile2:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_compile2])

        compile_instructions = [ppr[c_tag] for c_tag in compile_instruction_tags]
        run_instructions = None

    elif job_type == "Run":
        check_run = l2_contains_l1(["RC"], ppr_keys)
        if check_run:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_run])

        number_run_instructions = int(ppr["RC"])
        run_instruction_tags = ["R"+str(c) for c in range(0, number_run_instructions)]
        check_run2 = l2_contains_l1(run_instruction_tags, ppr_keys)
        if check_run2:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_run2])

        compile_instructions = None
        run_instructions = [ppr[r_tag] for r_tag in run_instruction_tags]

    elif job_type == "Both":
        check_both = l2_contains_l1(["CC", "RC"], ppr_keys)
        if check_both:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_compile])

        number_compile_instructions = int(ppr["CC"])
        compile_instruction_tags = ["C"+str(c) for c in range(0, number_compile_instructions)]
        check_compile2 = l2_contains_l1(compile_instruction_tags, ppr_keys)
        if check_compile2:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_compile2])

        compile_instructions = [ppr[c_tag] for c_tag in compile_instruction_tags]

        number_run_instructions = int(ppr["RC"])
        run_instruction_tags = ["R"+str(c) for c in range(0, number_run_instructions)]
        check_run2 = l2_contains_l1(run_instruction_tags, ppr_keys)
        if check_run2:
            return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check_run2])

        run_instructions = [ppr[r_tag] for r_tag in run_instruction_tags]


    # Adds the data to a json file if using the web interface
    # Warning, only the directory with same name will be added
    if origin == "web":
        GREYFISH_DIR = "/greyfish/sandbox/DIR_commonuser/jobs_left/"
        zip_location = GREYFISH_DIR+dirname+".zip"

        os.mkdir(GREYFISH_DIR+dirname)
        os.chdir(GREYFISH_DIR+dirname)

        with zipfile.ZipFile(zip_location, 'r') as zf:
            zf.extractall(".")

        # Must have a directory with the same name as the zipfile
        dirs_inside = [adir for adir in os.listdir('.') if os.path.isdir(GREYFISH_DIR+dirname+"/"+adir)]

        if len(dirs_inside) != 1:
            return "INVALID: "+str(len(dirs_inside)+" were provided, only one directory containing all the necessary data can be inside the zip file")

        only_dir_with_info = dirs_inside[0]
        os.rename(only_dir_with_info, dirname)

        for item in os.listdir('.'):

            if item == dirname:
                continue

            if os.path.isdir(item):
                shutil.rmtree(item)
            else:
                # for files
                os.remove(item)


        web_data_to_json_file.json_to_file(dirname, ppr)

        os.remove(zip_location)
        shutil.make_archive(GREYFISH_DIR+dirname, "zip", ".")

        os.chdir(CURDIR)
        shutil.rmtree(GREYFISH_DIR+dirname)


    mints.add_job(job_ID, username, compile_instructions, run_instructions, job_type, origin, modules, output_files, dirname,
                    sc_system, sc_queue, n_cores, n_nodes)

    return "New job added to database"


# Returns a list of N jobs
# IDs and directory locations, to be requested later
@app.route("/api/jobs/request", methods=['POST'])
def request_N_jobs():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "number", "sc_system"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    number_requested = int(ppr["number"])
    sc_system = ppr["sc_system"]

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    job_list = mints.jobs_with_status(number_requested, sc_system, status="Received by server")

    job_IDs = []
    job_dir_locations = []

    for a_job_info in job_list:
        job_IDs.append(a_job_info[0])
        job_dir_locations.append(a_job_info[1])

    return jsonify({"IDs":job_IDs, "directory_locations":job_dir_locations})



# Requests a list of jobs in bulk
# Returns a tar file containing all the jobs
# For each job, there will be a JSON file as well which contains the checksums of all files
@app.route("/api/jobs/request/data/bulk", methods=['POST'])
def bulk_data_request():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "IDs"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    job_IDs = ppr["IDs"]

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    # Gets the directory locations
    dirlocs = mints.directory_locations_from_job_ids(job_IDs)
    GREYFISH_DIR = "/greyfish/sandbox/DIR_commonuser/jobs_left/"

    os.chdir(GREYFISH_DIR)
    tar_name = "tmp-"+random_string(5)+".checksum.tar.gz"
    tar = tarfile.open(tar_name, "w:gz")

    checksum_dict = {}

    for job_data in dirlocs:
        tar.add(job_data+".zip")
        checksum_dict[job_data+".zip"] = sha256_checksum(job_data+".zip")[:8]

    with open("checksums.json", "w") as jfil:
        jfil.write(json.dumps(checksum_dict))

    tar.add("checksums.json")
    tar.close()

    os.remove("checksums.json")

    os.chdir(CURDIR)

    # Removes the temporary file
    @after_this_request
    def remove_files(response):

        # Deletes the file
        os.remove(GREYFISH_DIR+tar_name)
        return response

    return send_file(GREYFISH_DIR+tar_name, as_attachment=True)



# Updates the status of a job
@app.route("/api/jobs/status/update", methods=['POST'])
def status_update():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "job_ID", "status", "error"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    job_ID = ppr["job_ID"]
    status = ppr["status"]
    error = ppr["error"]

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    if error == "":
        error = None

    mints.update_job_status(job_ID, status, error)

    return "Updated job status"



# Returns the status of a job
@app.route("/api/jobs/status", methods=['POST'])
def get_job_status():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "job_ID"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    job_ID = ppr["job_ID"]

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    [job_status, error] = mints.status_of_job(job_ID)

    if error:
        return "INVALID, "+job_status

    return job_status



# Updates the execution time of a job
@app.route("/api/jobs/status/update_execution_time", methods=['POST'])
def update_execution_time():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    ppr_keys = ppr.keys()
    check = l2_contains_l1(["key", "job_ID", "sc_execution_time", "notes_sc"], ppr_keys)

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    job_ID = ppr["job_ID"]
    sc_execution_time = ppr["sc_execution_time"]
    notes_sc = ppr["notes_sc"]

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    if notes_sc == "":
        notes_sc = None

    mints.update_job_execution_time(job_ID, sc_execution_time, notes_sc)

    return "Updated job execution time"


# Uploads a tar file containing the job data
@app.route("/api/jobs/upload_results/user/<username>/<job_ID>/key=<key>", methods=['POST'])
def upload_results(username, job_ID, key):

    if not valid_adm_passwd(key):
        return "INVALID: Access not allowed"

    username = unquote(username)

    # Checks if the user directory exists
    GREYFISH_DIR = "/greyfish/sandbox/DIR_"+username+"/"
    if not os.path.isdir(GREYFISH_DIR):
        return "INVALID: User does not exist"

    user_results_dir = GREYFISH_DIR+"results/"
    if not os.path.isdir(user_results_dir):
        os.mkdir(user_results_dir)

    os.mkdir(user_results_dir+job_ID)

    file = request.files['file']
    fnam = file.filename

    # Avoids empty filenames and those with commas
    if fnam == '':
        return 'INVALID, no file uploaded'

    try:

        tar_location = user_results_dir+job_ID+"/data.tar.gz"

        file.save(tar_location)
        tar = tarfile.open(tar_location)
        tar.extractall(user_results_dir+job_ID)
        tar.close()
        os.remove(tar_location)

    except:
        tar.close()
        os.remove(tar_location)

        return "Could not open tar file" 

    mints.update_results_received(job_ID)

    # Now that the job is complete, remove the job files
    location_of_job = mints.directory_locations_from_job_ids([job_ID])[0]
    os.remove("/greyfish/sandbox/DIR_commonuser/jobs_left/"+location_of_job+".zip")

    # If the user is already in a wetty image, it adds the result there
    # The wetty may be active or in WAIT status
    user_is_in_wetty = mints.user_to_ip_port(username)
    if not user_is_in_wetty[1]:
        [ip_used, port_used] = user_is_in_wetty[0][1].split(":")
        ip_used = IP_to_hostname(ip_used)

        miniserver_port = str(int(port_used)+100)
        wetty_key = PK_32(ip_used, port_used)

        # Do not send the original tar file, send a file containing the directory as well
        tmp_tar_name = "/tmp/"+random_string(16)+"_data.tar.gz"

        tmp_tar = tarfile.open(tmp_tar_name, "w|gz")
        tmp_tar.add(user_results_dir+job_ID, arcname = job_ID)
        tmp_tar.close()

        req = requests.post("http://"+ip_used+":"+miniserver_port+"/"+wetty_key+"/upload_result_dir",
            files={"dirname": open(tmp_tar_name, "rb")})

        os.remove(tmp_tar_name)

    return "Updated job results"




####################
# EMAIL ACTIONS
####################



# Sends a generic email, no attachments
@app.route("/api/email/send", methods=['POST'])
def validate_email():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    # basepath: Where the dir is stored
    # dirname: Directory in particular that must be uploaded
    check = l2_contains_l1(["key", "email_address", "subject", "text"], ppr.keys())

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    subject = ppr["subject"]
    email_address = ppr["email_address"]
    text = ppr["text"]

    if not valid_adm_passwd(key):
        return "INVALID key"

    if not ec.correctly_formatted_email_address(email_address):
        return "INVALID email address format"


    # Send the email
    return ec.send_mail_dev(email_address, subject, text, [])



####################
# LDAP ACTIONS
####################


# Validates a user's password and uid using ldap
@app.route("/api/ldap/validate", methods=['POST'])
def validate_ldap():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    # basepath: Where the dir is stored
    # dirname: Directory in particular that must be uploaded
    check = l2_contains_l1(["key", "ldap_host", "username", "password", "before", "after"], ppr.keys())

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    ldap_host = ppr["ldap_host"]
    username = ppr["username"]
    password = ppr["password"]
    before = ppr["before"]
    after = ppr["after"]

    if not valid_adm_passwd(key):
        return "INVALID key"


    # Validates
    if ldap_validate.ldap_check(username, password, ldap_host, before, after):
        return "User validated"
    else:
        return "INVALID: User or password are incorrect"





if __name__ == '__main__':
    app.run()
