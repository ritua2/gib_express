#!/bin/bash
# Executes when the user logs out



if [ "$USER" != "root" ]; then

    if [ "$USER" != "Empty" ]; then

    	# If the user has left a waiting server
    	if [ ! -f "/etc/wait.key" ]; then

            # Free instance
            curl -s http://$MANAGER_NODE:5000/api/instance/freeme/$UUID_f10

            # Creates a temporary directory and moves all the stuff in the current one there
            tar -zcf summary.tar.gz  /home/gib
            curl -F file=@summary.tar.gz  http://$GS:2002/grey/push_all/$GK2/$USER

            # Deletes all user files that can be deleted
            rm -rf /home/gib/*
        fi
    fi
fi
