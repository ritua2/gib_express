##########################
# BASICS
# 
# An alpine server with python3 installed, useful only as a cloud storage server
# Not designed for front-end interfaces
#########################

FROM python:3.6-alpine


# Copies the necessary files
COPY listener.py /listener/listener.py


# Installs the necessary packages
# Bash for convenience
RUN apk update && apk add bash curl && mkdir -p $output_data_path /listener/tmp/ && pip3 install gunicorn Flask requests &&\
	chmod +x /listener/listener.py

WORKDIR /listener
