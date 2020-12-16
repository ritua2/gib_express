"""
BASICS

Redirects a user, doing all the necessary actions
Checks that a user is valid after login into wetty
"""


from flask import Flask, redirect, request, send_file
import os
import random
import redis




URL_BASE = os.environ["URL_BASE"]
REDIS_AUTH = os.environ["REDIS_AUTH"]
orchestra_key = os.environ["orchestra_key"]
PROJECT = os.environ["PROJECT"]
GREYFISH_URL = os.environ["GREYFISH_URL"]
GREYFISH_REDIS_KEY = os.environ["GREYFISH_REDIS_KEY"]




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
@app.route("/api/redirect/users/<user_id>/<target_ip>", methods=['GET'])
def redirect_to_wetty(user_id, target_ip):

    r_redirect_cache = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=1)

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

    return redirect("http://"+user_instance, code=302)



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
    reqip = request.environ['REMOTE_ADDR']

    if not valid_adm_passwd(key):
        return "INVALID key"

    instances = redkeys(r_occupied)
    port_number = int(iport)

    # Instance is already occupied
    if reqip in instances:
        occports = ports_occupied(reqip)
        if not (iport in occports):
            r_occupied.hincrby(reqip, "Ports", 2**((port_number-7000)%10))
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
                        "address":reqip,
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
    reqip = request.environ['REMOTE_ADDR']

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
    reqip = request.environ['REMOTE_ADDR']

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
# Needs to be executed from within the machine itself
@app.route("/api/instance/freeme/<uf10>", methods=['GET'])
def freeme(uf10):

    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)

    reqip = request.environ['REMOTE_ADDR']
    instances = redkeys(r_occupied)

    if not (reqip in redkeys(r_occupied)):
        return "INVALID: instance not attached"

    pnn, err = Porter10(reqip, uf10)

    if err:
        return "INVALID: port not attached"

    # Frees the instance
    r_occupied.hset(reqip, "Available_"+pnn, "Yes")
    r_occupied.hset(reqip, "current_user_"+pnn, "Empty")
    # Sets the instance as globaly available
    r_occupied.hset(reqip, "Available", "Yes")
    change_container_availability(1)
    return "Correctly freed instance"



# Returns the current user
# Sets up the Redis table with the instance as occupied
@app.route("/api/instance/whoami/<uf10>", methods=['GET'])
def whoami(uf10):


    r_occupied = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=0)
    r_redirect_cache = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=1)

    reqip = request.environ['REMOTE_ADDR']
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
    
    change_container_availability(-1)
    return expected_user.decode("UTF-8")



@app.route("/api/instance/whatsmyip", methods=['GET'])
def whatsmyip():
    return request.environ['REMOTE_ADDR']




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

    reqip = request.environ['REMOTE_ADDR']
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

    reqip = request.environ['REMOTE_ADDR']
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



if __name__ == '__main__':
    app.run()
