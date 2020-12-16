FROM python:3.7-alpine


COPY traffic.py                 /conductor/traffic.py
COPY startup.sh                 /scripts/startup.sh
COPY connected_users.py         /conductor/connected_users.py 
COPY synchronizer.sh            /conductor/synchronizer.sh
COPY mysql_interactions.py      /conductor/mysql_interactions.py
COPY email_common.py            /conductor/email_common.py
COPY web_data_to_json_file.py   /conductor/web_data_to_json_file.py
COPY ldap_validate.py           /conductor/ldap_validate.py




RUN apk add --no-cache bash git openssh-client rsync && pip3 install Flask gunicorn ldap3 mysql-connector-python redis requests &&\
    chmod +x /conductor/synchronizer.sh


WORKDIR /conductor
