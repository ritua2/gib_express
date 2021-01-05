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
import requests
import signal
import subprocess
import tarfile
from urllib.parse import unquote
import uuid
from werkzeug.utils import secure_filename
import zipfile
import mysql.connector as mysql_con

import email_common as ec
import ldap_validate
import mysql_interactions as mints
import web_data_to_json_file





URL_BASE = os.environ["URL_BASE"]
MYSQL_USER = os.environ["MYSQL_USER"]
MYSQL_PASSWORD = os.environ["MYSQL_PASSWORD"]
MYSQL_DATABASE = os.environ["MYSQL_DATABASE"]
orchestra_key = os.environ["orchestra_key"]
PROJECT = os.environ["PROJECT"]
GREYFISH_URL = URL_BASE
CURDIR = os.path.dirname(os.path.realpath(__file__)) # Current directory



hhmmss_pattern = re.compile("^[0-9]{2}:[0-5][0-9]:[0-5][0-9]$")




def l2_contains_l1(l1, l2):
    return[elem for elem in l1 if elem not in l2]


def valid_adm_passwd(apass):
    if apass == orchestra_key:
        return True
    else:
        return False


# Gets ip for all VMs
def all_instances():
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    ip=[]
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select ip from terminal")
    for row in cursor:
        ip.append(row[0])
    cursor.close()
    ipt_db.close()
    return ip

def available_instances():
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    instances_av = []
    cursor.execute("select ip from terminal where available = TRUE")
    for row in cursor:
        instances_av.append(row[0])
    cursor.close()
    ipt_db.close()
    return instances_av



# Finds the list of occupied ports for certain instance, each port is a string
# instance (str)
def ports_occupied(instance):
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select port from port where ip = %s", (instance,))
    pav=[]
    for row in cursor:
        pav.append(row[0])
    return pav

# vmip (str): VM IP
def empty_ports(vmip):
    ep = []
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select port from port where ip = %s and available = TRUE", (vmip,))
    for row in cursor:
        ep.append(row[0])
    return ep

# Fetch if there is any occupied port by a user 
def busy_port_with_curuser(user_id):

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select ip, port from port where currentuser = %s", (user_id,))
    instance=None
    port=None
    for row in cursor:
        instance=row[0]
        port=row[1]

    cursor.close()
    ipt_db.close()
    return instance,port


# Gets the long key of a wetty container
# vmip (str): VM IPv4
# port_used (str)
def PK_32(vmip, port_used):
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select id from port where ip = %s and port = %s", (vmip,port_used))
    id=""
    for row in cursor:
        id=row[0]
    cursor.close()
    ipt_db.close()
    return id


# Verifies that a port key key is valid
# vmip (str): VM IPv4
# kk (str): key
# port_used (str)
def Valid_PK(vmip, kk, port_used):
    expected_key=PK_32(vmip,port_used)
    if expected_key == kk:
        return True
    else:
        return False



# Checks the port of a 10 character hash
# If the port is not associated with anything, it returns ["NA", 1]
def Porter10(vmip, kk): 
    for pn in ports_occupied(vmip):
        expected_key=PK_32(vmip,pn)
        if kk in expected_key:
            return [pn, 0]
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
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)    
    cursor.execute("select hostname from ip_to_hostname where ip = %s",(IP_to_be_translated,))
    possible_hostname = None
    for row in cursor:
        possible_hostname = row[0]
    cursor.close()
    ipt_db.close()

    if possible_hostname == None:
        # No translation or the IP has not been added
        return IP_to_be_translated
    else:
        return possible_hostname

def hostname_to_IP(host_to_be_translated):
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)    
    cursor.execute("select ip from ip_to_hostname where hostname = %s",(host_to_be_translated,))
    possible_ip = None
    for row in cursor:
        possible_ip = row[0]
    cursor.close()
    ipt_db.close()

    if possible_ip == None:
        # No translation or the IP has not been added
        return host_to_be_translated
    else:
        return possible_ip


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
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select count(*) from port where available = TRUE")
    count = 0
    for row in cursor:
        count=row[0]
    cursor.close()
    ipt_db.close() 
    return count



@app.route("/api/active", methods=['GET'])
def active():
    return "Orchestration node is active"



# Requests an available container for a user
@app.route("/api/assign/users/<user_id>", methods=['POST'])
def assigner(user_id):

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "sender"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]

    if not valid_adm_passwd(key):
        return "INVALID key"
    
    
    # Checks if any port is assigned to current user
    instance,occupied_port=busy_port_with_curuser(user_id)
    if instance is not None and occupied_port is not None:
        return instance+":"+occupied_port


    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)

    # Checks all instances with at least one port open
    for instance in available_instances():

        # Checks only ports not assigned yet
        for emp in empty_ports(instance):
            cursor.execute("select count(*) from redirect_cache where ip = %s and port = %s",(instance,emp))
            count=0
            for row in cursor:
                count=row[0]
            if count>0:
                # Ignores ports in cache
                continue

            # Sets the instance as occupied, the server now has 20 s to redirect the user
            try:
                cursor.execute("insert into redirect_cache(ip,port,username,timeout) values(%s,%s,%s,NOW() + INTERVAL 20 SECOND)",(instance,emp,user_id))
                ipt_db.commit()
            except mysql_con.IntegrityError:
                continue
            cursor.close()
            ipt_db.close() 
            return instance+":"+emp

    # All instances are occupied
    else:
        cursor.close()
        ipt_db.close()
        return "False"



# Redirects a user after an available IP has been provided to him
# target_ip may also be the hostname
@app.route("/api/redirect/users/<user_id>/<target_ip>", methods=['GET'])
def redirect_to_wetty(user_id, target_ip):

    target_ip = IP_to_hostname(target_ip)
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    
    # Finds if the user is attached to any instance   
    cursor.execute("select port from redirect_cache where ip = %s and username = %s",(target_ip,user_id))
    port = None
    for row in cursor:
        port=row[0]

    if port is not None:
        # 20 s to complete redirect
        cursor.execute("update redirect_cache set timeout=NOW() + INTERVAL 20 SECOND where ip = %s and username = %s and port= %s",(target_ip,user_id, port))
        ipt_db.commit()
        cursor.close()
        ipt_db.close()
        return "Redirecting https://"+target_ip+":"+port+"/wetty"
    else:
        cursor.close()
        ipt_db.close()
        return "INVALID: "+target_ip+" has already been assigned to another user"


# Adds a new container by port and IP
@app.route("/api/instance/attachme", methods=['POST'])
def attachme():
 
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
    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']


    if not valid_adm_passwd(key):
        return "INVALID key"
    
    instances = all_instances()
    port_number = int(iport)

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)


    # Instance IP has already been added
    if reqip in instances:
        occports = ports_occupied(reqip)
        if not (iport in occports):
            insert_port = ("INSERT INTO port (ip, port, id, currentuser, available) VALUES (%s, %s, %s, %s, %s)")
            cursor.execute(insert_port, (reqip, iport, sender_ID, "Empty",True))        
            select_ports = ("SELECT ports from terminal where ip=%s")
            cursor.execute(select_ports, (reqip,))
            ports=0
            for sel_ports in cursor:
                ports=sel_ports[0]
            ports+=2**((port_number-7000)%10)
            update_ports = ("UPDATE terminal set ports = %s where ip=%s")
            cursor.execute(update_ports, (ports,reqip))
            ipt_db.commit()
            cursor.close()
            ipt_db.close()
            return "Added port "+iport

        else:
            cursor.close()
            ipt_db.close()
            return "Port has already been added"

    else:

        # All IPs are stored in MYSQL with the following data:
        insert_terminal = ("INSERT INTO terminal (ip, address, available, ports) VALUES (%s, %s, %s, %s)")
        cursor.execute(insert_terminal, (reqip, reqhostname, True, int(2**((port_number-7000)%10))) )
        insert_port = ("INSERT INTO port (ip, port, id, currentuser, available) VALUES (%s, %s, %s, %s, %s)")
        cursor.execute(insert_port, (reqip, iport, sender_ID, "Empty",True))
        ipt_db.commit()
        cursor.close()
        ipt_db.close()
        return "Instance correctly attached"



# Removes the current IP as a wetty instance
@app.route("/api/instance/removeme", methods=['POST'])
def removeme():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']


    if not valid_adm_passwd(key):
        return "INVALID key"

    if not (reqip in all_instances()):
        return "INVALID, instance is not associated with the project"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
   
    cursor.execute("delete from port where ip = %s", (reqip,))
    cursor.execute("delete from terminal where ip = %s", (reqip,))
    ipt_db.commit()
    cursor.close()
    ipt_db.close()
    r_occupied.delete(reqip)
    return "Instance removed"



# Removes a port from an instance
# If the instance has no more ports, it deletes it
# This is an instantaneous action and it does not matter if there is a user already in the instance
@app.route("/api/instance/remove_my_port", methods=['POST'])
def remove_my_port():

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
    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']


    if not valid_adm_passwd(key):
        return "INVALID key"

    #instances = redkeys(r_occupied)
    instances = all_instances()
    port_number = int(iport)
    if not (reqip in instances):
        return "INVALID, instance is not associated with the project"

    # Port must be added
    occports = ports_occupied(reqip)
    if not (iport in occports):
        return "Port is not associated with the instance"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)

    if (len(occports) == 1) and (Valid_PK(reqip, sender_ID, iport)):
        # If last port, delete the instance from database
        cursor.execute("delete from port where ip = %s", (reqip,))
        cursor.execute("delete from terminal where ip = %s", (reqip,))
        ipt_db.commit()
        cursor.close()
        ipt_db.close()
        return "Instance removed"

    else:
        # Check for valid key
        if Valid_PK(reqip, sender_ID, iport):
            # Removes all the provided characteristics
            cursor.execute("delete from port where ip = %s and port = %s", (reqip,iport))
            # Changes the port number
            select_ports = ("SELECT ports from terminal where ip=%s")
            cursor.execute(select_ports, (reqip,))
            ports=0
            for sel_ports in cursor:
                ports=sel_ports[0]
            ports-=2**((port_number-7000)%10)
            update_ports = ("UPDATE terminal set ports = %s where ip=%s")
            cursor.execute(update_ports, (ports,reqip))
            ipt_db.commit()
            cursor.close()
            ipt_db.close()
            return "Removed port from instance"



# Frees an instance
# Must be called from springIPT
@app.route("/api/instance/free", methods=['POST'])
def free_instance():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "IP", "Port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqhostname = IP_to_hostname(ppr["IP"])
    reqip = ppr["IP"]

    port = str(ppr["Port"])

    if not valid_adm_passwd(key):
        return "INVALID key"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)

    cursor.execute("select available,currentuser from port where ip = %s and port = %s", (reqip,port))
    ava=None
    current_wetty_user=""
    for row in cursor:
        ava=row[0]
        current_wetty_user=row[1]

    if ava is None:
        cursor.close()
        ipt_db.close()
        return "INVALID, port not attached"
 
    if ava:
        cursor.close()
        ipt_db.close()
        return "INVALID, wetty instance is empty at the moment"

    #current_wetty_user = r_occupied.hget(reqip, "current_user_"+port).decode("UTF-8")
    miniserver_port = str(int(port) + 100)

    # Generates a single-use greyfish token
    new_token = random_string(24)
    try:
        cursor.execute("insert into greykeys(username,token, timeout) values(%s, %s, NOW() + INTERVAL 60 SECOND)",(current_wetty_user,new_token))
    except mysql_con.IntegrityError:
        cursor.execute("update greykeys set username=%s, timeout= NOW() + INTERVAL 60 SECOND where token=%s",(current_wetty_user,new_token))
    ipt_db.commit()

    wetty_key = PK_32(reqip, port)

    # Issues a call to the wetty miniserver
    # The miniserver will then prepare the instance for a new user
    sync_wetty_volume(reqhostname, port, current_wetty_user, wetty_key, "stop")
    req = requests.post("http://"+reqhostname+":"+miniserver_port+"/user/purge", data={"key": wetty_key, "username":current_wetty_user,
                                                                                "greyfish_url":URL_BASE, "gk":new_token})

    # Frees the instance
    cursor.execute("Update port set available = %s, currentuser = %s, waitkey=NULL where ip = %s and port = %s", (True,"Empty",reqip,port))
    # Sets the instance as globaly available
    cursor.execute("Update terminal set available = %s where ip = %s",  (True,reqip))
    ipt_db.commit()
    cursor.close()
    ipt_db.close()

    return "Correctly freed instance"
	
	
	
# Called when "Refresh" is clicked, to get the latest image of wetty folder.
# Must be called from springIPT
@app.route("/api/instance/get_latest", methods=['POST'])
def get_instance():

    if not request.is_json:
        return "POST parameters could not be parsed"

    ppr = request.get_json()
    check = l2_contains_l1(ppr.keys(), ["key", "IP", "Port"])

    if check:
        return "INVALID: Lacking the following json fields to be read: "+",".join([str(a) for a in check])

    key = ppr["key"]
    reqhostname = IP_to_hostname(ppr["IP"])
    reqip = ppr["IP"]

    port = str(ppr["Port"])

    if not valid_adm_passwd(key):
        return "INVALID key"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE) 
    cursor = ipt_db.cursor(buffered=True)

    cursor.execute("select available,currentuser from port where ip = %s and port = %s", (reqip,port))
    ava=None
    current_wetty_user=""
    for row in cursor:
        ava=row[0]
        current_wetty_user=row[1]
    
    if ava is None:
        cursor.close()
        ipt_db.close()
        return "INVALID, port not attached"


    if ava:
        cursor.close()
        ipt_db.close()
        return "INVALID, wetty instance is empty at the moment"

    miniserver_port = str(int(port) + 100)

    # Generates a single-use greyfish token
    new_token = random_string(24)
    try:
        cursor.execute("insert into greykeys(username,token, timeout) values(%s, %s, NOW() + INTERVAL 60 SECOND)",(current_wetty_user,new_token))
    except mysql_con.IntegrityError:
        cursor.execute("update greykeys set username=%s, timeout= NOW() + INTERVAL 60 SECOND where token=%s",(current_wetty_user,new_token))

    ipt_db.commit()
    cursor.close()
    ipt_db.close()

    wetty_key = PK_32(reqip, port)

    # Issues a call to the wetty miniserver
    # The miniserver will then prepare the instance for a new user
    #sync_wetty_volume(reqip, port, current_wetty_user, wetty_key, "stop")
    req = requests.post("http://"+reqhostname+":"+miniserver_port+"/get/latest", data={"key": wetty_key, "username":current_wetty_user,
                                                                                "greyfish_url":URL_BASE, "gk":new_token})

    return "Correctly sent data"
	
	
	
	
	



# Returns the current user
# Sets up the MYSQL table with the instance as occupied
@app.route("/api/instance/whoami/<uf10>", methods=['GET'])
def whoami(uf10):

    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']
    user_port, err = Porter10(reqip, uf10)

    if err:
        # If it does not exist, the user is either already there or the VM is not attached
        return "Empty"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)    
    cursor.execute("select username from redirect_cache where ip = %s and port = %s",(reqip,user_port))
    expected_user = None
    for row in cursor:
        expected_user=row[0]

    if expected_user == None:
        cursor.close()
        ipt_db.close()
        return "Empty"

    # Deletes the cache
    cursor.execute("delete from redirect_cache where ip = %s and port = %s", (reqip,user_port))

    # Sets the port as occupied
    cursor.execute("update port set available = %s, currentuser = %s where ip = %s and port = %s", (False,expected_user,reqip,user_port))
    ipt_db.commit()

    # If all ports are occupied, it sets the available tag as no
    if len(empty_ports(reqip)) == 0:
        cursor.execute("update terminal set available = %s where ip = %s", (False,reqip))
        ipt_db.commit()

    cursor.close()
    ipt_db.close()
    
    wetty_key = PK_32(reqip, user_port)
    sync_wetty_volume(reqhostname, user_port, expected_user, wetty_key, "start")
    return expected_user



# Checks if a user is logged in 
# Returns 'False' if not, and the IP:port if yes
@app.route("/api/users/logged_in", methods=['POST'])
def logged_in():

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

    ip,port=busy_port_with_curuser(username)

    # Checks all instances with at least one port open
    if ip is None or port is None:
        return "False"
    else:
        return ip+":"+port

# Sets the container assigned to user X as waiting
@app.route("/api/users/container_wait", methods=['POST'])
def container_wait():

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

    ip,port=busy_port_with_curuser(username)

    # Finds if the user is logged in
    if ip is None or port is None:
        return "User is not available at any container"

    #user_ip_port_container = r_user_to_.hget(username, "IP:port").decode("UTF-8")
    user_ip_port_container = ip+":"+port
    [ip_used, port_used] = user_ip_port_container.split(":")

    ip_used = IP_to_hostname(ip_used)

    wetty_key = PK_32(ip_used, port_used)

    miniserver_port = str(int(port_used) + 100)

    # Calls the miniserver
    req = requests.post("http://"+ip_used+":"+miniserver_port+"/wait", data={"key": wetty_key, "username":username})
    
    if req.text == "INVALID key":
        return "Could not set wetty terminal as WAIT"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True) 
    cursor.execute("update port set waitkey = %s where currentuser = %s", (req.text,username))
    ipt_db.commit()
    cursor.close()
    ipt_db.close()
    return "Set wetty at "+user_ip_port_container+" as WAIT"



# Returns the WAIT key for a user
# Returns false if not
@app.route("/api/users/wetty_wait_key", methods=['POST'])
def wetty_wait_key():

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

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select ip, port, waitkey from port where currentuser = %s", (username,))
    ip = None
    port = None
    wkey = None
    for row in cursor:
        ip=row[0]
        port=row[1]
        wkey=row[2]
    cursor.close()
    ipt_db.close()

    # Checks all instances with at least one port open
    if ip is None or port is None:
        return "False"
    else:
        if wkey is not None:
            return wkey
        else:
            return "User is logged in, no waiting containers"


# Synchronizes the user container to its attached 
@app.route("/api/users/container_sync", methods=['POST'])
def container_sync_volume():

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

    ip,port=busy_port_with_curuser(username)

    # Finds if the user is logged in
    #if r_user_to_.exists(username) == 0:
    if ip is None or port is None:
        return "User is not available at any container"

    user_ip_port_container = ip+":"+port
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

    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']
    instances = all_instances()

    if not (reqip in instances):
        return "INVALID: instance not attached"

    pnn, err = Porter10(reqip, uf10)
    if err:
        return "INVALID: port not attached"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select currentuser from port where ip = %s and port = %s", (reqip,pnn))
    curuser=''
    for row in cursor:
        curuser=row[0]

    if curuser != "Empty":
        # Creates a random string of characters (24 length), sets it as a token, and returns it
        # Each token will last a maximum of 2 hours
        new_token = random_string(24)
        try:
            cursor.execute("insert into greykeys(username,token, timeout) values(%s, %s, NOW() + INTERVAL 7200 SECOND)",(curuser,new_token))
        except mysql_con.IntegrityError:
            cursor.execute("update greykeys set username=%s, timeout= NOW() + INTERVAL 7200 SECOND where token=%s",(curuser,new_token))

        ipt_db.commit()
        cursor.close()
        ipt_db.close()
        return new_token

    else:
        cursor.close()
        ipt_db.close()
        return "INVALID user"



# Creates a new key for the user 'commonuser', used to store the job information
# Simply returns the key
# Cannot be called from outside the instance
@app.route("/api/greyfish/new/commonuser_token/<uf10>", methods=['GET'])
def grey_commonuser_token(uf10):

    reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
    reqip = request.environ['REMOTE_ADDR']
    instances = all_instances()

    if not (reqip in instances):
        return "INVALID: instance not attached"

    pnn, err = Porter10(reqip, uf10)
    if err:
        return "INVALID: port not attached"

    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE) 
    cursor = ipt_db.cursor(buffered=True)
    cursor.execute("select currentuser from port where ip = %s and port = %s", (reqip,pnn))
    curuser=''
    for row in cursor:
        curuser=row[0]

    #curuser = r_occupied.hget(reqip, "current_user_"+pnn).decode("UTF-8")
    if curuser != "Empty":
        # Creates a random string of characters (24 length), sets it as a token, and returns it
        # Each token will last a maximum of 2 hours
        new_token = random_string(24)
        try:
            cursor.execute("insert into greykeys(username,token, timeout) values(%s, %s, NOW() + INTERVAL 7200 SECOND)",("commonuser",new_token))
        except mysql_con.IntegrityError:
            cursor.execute("update greykeys set username=%s, timeout= NOW() + INTERVAL 7200 SECOND where token=%s",("commonuser",new_token))

        ipt_db.commit()
        cursor.close()
        ipt_db.close()
        return new_token

    else:
        cursor.close()
        ipt_db.close()
        return "INVALID user"



# Creates a temporary key for a greyfish user
@app.route("/api/greyfish/users/<user_id>/create_greyfish_key", methods=['POST'])
def tmp_greyfish_key_for_user(user_id):

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
    ipt_db = mysql_con.connect(host = URL_BASE , port = 6603, user = MYSQL_USER, password = MYSQL_PASSWORD, database = MYSQL_DATABASE)
    cursor = ipt_db.cursor(buffered=True)
    try:
        cursor.execute("insert into greykeys(username,token, timeout) values(%s, %s, NOW() + INTERVAL 120 SECOND)",(user_id,new_token))
    except mysql_con.IntegrityError:
        cursor.execute("update greykeys set username=%s, timeout= NOW() + INTERVAL 120 SECOND where token=%s",(user_id,new_token))

    ipt_db.commit()
    cursor.close()
    ipt_db.close()
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

    reqip = request.environ['REMOTE_ADDR']
    if reqip in all_instances():
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
        reqhostname = IP_to_hostname(request.environ['REMOTE_ADDR'])
        reqip = request.environ['REMOTE_ADDR']

        # Valid IP and user is in the IP
        if (reqip in all_instances()) and (not (mints.get_ip_port(username, reqhostname)[1])):
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

    #if type_of_user[0] == "false": # uncomment to enable ldap

        # Deletes the job data if it exists
        #if os.path.exists(greyfish_commonuser_job_loc):  # uncomment to enable ldap
         #   os.remove(greyfish_commonuser_job_loc)   # uncomment to enable ldap

        #return "User is not authorized to submit jobs"   # uncomment to enable ldap



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
        wetty_key = PK_32(hostname_to_IP(ip_used), port_used)

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
    
