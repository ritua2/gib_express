"""
BASICS

Interactions with MySQL
"""


import datetime
import mysql.connector as mysql_con
import os




# Returns the time format YYYY-MM-DD hh:mm:ss (UTC)
def timnow():
    return datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S.%f")



# Adds a job to MySQL
# ID (str): Preferably an UUID
# username (str)
# job_type (str)
# compile_commands, run_commands (arr) (str): Contains a list of commands
# job_type (str)
# location (str)
# modules (str): Space separated
# output_files (str): Space separated
# directory_location (str): Zipped directory name without .zip, always located at DIR_commonuser/jobs_left

def add_job(ID, username, compile_commands, run_commands, job_type, location, modules, output_files, directory_location, sc_system, sc_queue, n_cores, n_nodes):
    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    insert_new_job = (
        "INSERT INTO jobs (id, username, compile_commands, run_commands, type, date_submitted, submission_method, status, modules, output_files, directory_location, sc_system, sc_queue, n_cores, n_nodes) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)")


    [compile_commands_str, run_commands_str] = [None, None]
    if compile_commands != None:
        compile_commands_str = ";".join(compile_commands)
    
    if run_commands != None:
        run_commands_str = ";".join(run_commands)

    cursor.execute(insert_new_job, (ID, username, compile_commands_str, run_commands_str, job_type, timnow(), location, "Received by server", modules, output_files, directory_location, sc_system, sc_queue, n_cores, n_nodes) )
    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()



# Returns a list of job IDs and directory locations that have a certain status
# Default is available for processing
# max_jobs_wanted (int)

# Returns (arr) [id (str), directory location (str)]
def jobs_with_status(max_jobs_wanted, sc_system, status="Received by server"):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    query = ("SELECT id, directory_location FROM jobs WHERE status=%s AND sc_system=%s LIMIT %s")
    cursor.execute(query, (status, sc_system, max_jobs_wanted))

    B = [[job_id, dir_loc] for (job_id, dir_loc) in cursor]

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()

    return B



# Returns the status of a job, assumes said job exists
def status_of_job(job_ID):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    # Ensures that the job ID exists
    query = ("SELECT COUNT(*) FROM jobs WHERE id=%s")
    cursor.execute(query, (job_ID, ))

    counter = next(cursor)

    if counter[0] == 0:
        return ["Job ID "+job_ID+" does not exist", 1]


    query = ("SELECT status FROM jobs WHERE id=%s")
    cursor.execute(query, (job_ID, ))

    S = next(cursor)

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()

    return [S[0], 0]



# Given a list of job IDs, returns a list of their directory locations
# job_ids (arr) (str)
def directory_locations_from_job_ids(job_ids):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    A = []

    for jid in job_ids:
        query = "SELECT directory_location FROM jobs WHERE id=%s LIMIT 1"
        cursor.execute(query, (jid,))
        for a in cursor:
            A.append(a[0])

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()

    return A



# Updates the status of a job
def update_job_status(job_ID, new_status, error=None):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    cursor.execute("UPDATE jobs SET status = %s, error = %s WHERE id = %s", (new_status, error, job_ID))

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()



# Updates the execution time of a job
def update_job_execution_time(job_ID, sc_execution_time, notes_sc=None):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    cursor.execute("UPDATE jobs SET sc_execution_time = %s, notes_sc = %s WHERE id = %s", (float(sc_execution_time), notes_sc, job_ID))

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()



# Updates the execution time of a job
def update_results_received(job_ID):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    cursor.execute("UPDATE jobs SET date_server_received = %s WHERE id = %s", (timnow(), job_ID))

    springIPT_db.commit()
    cursor.close()
    springIPT_db.close()



# Gets the IP:Port information given the username and IP
def get_ip_port(username, IP):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    query = ("SELECT user, ip FROM assignment WHERE user=%s AND ip LIKE %s")
    cursor.execute(query, (username, IP+":%"))

    for (obtained_user, obtained_ip_port) in cursor:

        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return [[obtained_user, obtained_ip_port], False]
    else:
        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return ["User not present", True]




# Returns the VM:port associated with a username
def user_to_ip_port(username):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    query = ("SELECT user, ip FROM assignment WHERE user=%s")
    cursor.execute(query, (username, ))

    for (obtained_user, obtained_ip_port) in cursor:

        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return [[obtained_user, obtained_ip_port], False]
    else:
        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return ["User not present", True]



# Finds if a current user is IPT or TACC
def current_user_status(username):

    springIPT_db = mysql_con.connect(host = os.environ['URL_BASE'], port = 6603, user = os.environ["MYSQL_USER"],
                    password = os.environ["MYSQL_PASSWORD"], database = os.environ["MYSQL_DATABASE"])
    cursor = springIPT_db.cursor(buffered=True)

    corrected_username = username.replace(" ", "_")

    query = ("SELECT user_type FROM current_users WHERE username=%s")
    cursor.execute(query, (corrected_username, ))

    for (type_of_user,) in cursor:

        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return [[type_of_user], False]
    else:
        springIPT_db.commit()
        cursor.close()
        springIPT_db.close()

        return ["User not present", True]
