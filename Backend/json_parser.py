#!/usr/bin/python3.6

"""
BASICS

Returns the value for a provided json key in a file
Args:

json_parser.py FILE.json KEY -> VALUE
"""


import json
import sys


if len(sys.argv) == 4:
    # Assuming that a file exists, returns the length of a key containing a list
    if sys.argv[3] == "len":
        with open(sys.argv[1], 'r') as jfil:
            J = json.load(jfil)
            print(len(J[sys.argv[2]]))

    # Assuming that a file exists, prints each element of the list in a new line
    if sys.argv[3] == "each":
        with open(sys.argv[1], 'r') as jfil:
            J = json.load(jfil)
            for elem in J[sys.argv[2]]:
                print(elem)
    sys.exit()

if len(sys.argv) == 5:
    # Prints a certain key in a list
    # List length is assumed to exist
    if sys.argv[3] == "elem":
        with open(sys.argv[1], 'r') as jfil:
            J = json.load(jfil)
        print(J[sys.argv[2]][int(sys.argv[4])])

    sys.exit()



# Default behaviour
try:
    with open(sys.argv[1], 'r') as jfil:
        J = json.load(jfil)
        print(J[sys.argv[2]])
        sys.exit()

except Exception as e:
    print("File or key do not exist")
