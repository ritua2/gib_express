FROM python:3.7-alpine


COPY traffic.py /conductor/traffic.py
COPY startup.sh /scripts/startup.sh

# For cases where login in is needed
RUN apk add --no-cache bash git && pip3 install Flask gunicorn redis


WORKDIR /conductor
