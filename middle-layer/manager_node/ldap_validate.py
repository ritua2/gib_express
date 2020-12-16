"""
BASICS

LDAP functionalities
"""


from ldap3 import Server, Connection, ALL



# Checks if a user password is valid using LDAP
def ldap_check(username, pw, ldap_host="ldap.tacc.utexas.edu", before_structure="uid=", after_structure=",ou=People,"):


    host_ldapped = ",".join([ "dc="+x for x in ldap_host.split(".") ])

    s = Server(ldap_host, port=389, get_info=ALL)
    c = Connection(s, user=before_structure+username+after_structure+ host_ldapped, password=pw)

    if not c.bind():
        return False
    return True
