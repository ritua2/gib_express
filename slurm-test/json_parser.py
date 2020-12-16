#!/usr/bin/python3.6

"""
BASICS

Returns the value for a provided json key in a file
Args:

json_parser.py FILE.json KEY -> VALUE
"""


import json
import sys



if len(sys.argv) != 3:
    print("Incorrect Number of Arguments")
    sys.exit()



try:
    with open(sys.argv[1], 'r') as jfil:
        J = json.load(jfil)
        print(J[sys.argv[2]])

except:
    print("File or key do not exist")
