"""
BASICS

Prints, in a new line, each:
User, VM, Port

for each of the users
"""

import os
import redis




URL_BASE = os.environ["URL_BASE"]
REDIS_AUTH = os.environ["REDIS_AUTH"]
r_user_to_ = redis.Redis(host=URL_BASE, port=6379, password=REDIS_AUTH, db=4)


for an_user in r_user_to_.keys():

    user_decoded = an_user.decode("UTF-8")

    try:
        [VM, Port] = r_user_to_.hget(user_decoded, "IP:port").decode("UTF-8").split(":")
        print(user_decoded+","+VM+","+Port)
    except:
        # Cases when the key has been deleted mid-program

        # Also avoids the available containers API
        pass

