#!/bin/bash






function rsync_user_to_vm {

    IFS=',' read -ra username_vm_port <<< "$1"

    username=${username_vm_port[0]}
    vm=${username_vm_port[1]}

    # Manager Node -> Wetty
    rsync -rvz -e 'ssh -o StrictHostKeyChecking=no -p 4646 -i /conductor/rsync_wetty.key' /greyfish/sandbox/DIR_"$username"/ rsync_user@"$vm":/home/rsync_user/data/DIR_"$username"
    
    # Wetty -> Manager Node
    rsync -rvz -e 'ssh -o StrictHostKeyChecking=no -p 4646 -i /conductor/rsync_wetty.key' rsync_user@"$vm":/home/rsync_user/data/DIR_"$username"/ /greyfish/sandbox/DIR_"$username"

}


while read line
do
	rsync_user_to_vm "$line"
done
