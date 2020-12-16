#!/bin/bash




# Only useful for users, not maintenance
if [ "$USER" = "gib" ]; then

    # Disallow ctrl-C during startup
    trap '' SIGINT SIGTSTP

    # Add startup script from the orchestration server

    curl -O -s http://$MANAGER_NODE:5000/api/scripts/startup

    unset HISTFILE # No history
    source startup

    rm startup

    # Allows ctrl-C again
    trap - SIGINT SIGTSTP

fi
