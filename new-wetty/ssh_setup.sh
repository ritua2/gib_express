#!/bin/bash


# Script fails if any commands fail, causing the container to be shut down
set -e

if [ -z "$conductor" ]; then
    exit
fi

if [ -z "$orchestra_key" ]; then
    exit
fi



curl http://$conductor:5000/api/manager_node/public_key > /home/rsync_user/.ssh/authorized_keys

rc-status
touch /run/openrc/softlevel

# Because ssh is a detached service
/etc/init.d/sshd start

# Changes user password to be the same as the orchestra key, so that only the main manager node has access to it
printf "$orchestra_key""\n""$orchestra_key""\n" | passwd rsync_user

chown rsync_user -R data/
chgrp rsync_user -R data/

tail -F anything
