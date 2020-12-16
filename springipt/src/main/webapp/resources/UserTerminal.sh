#! /bin/bash
username=$1

answer=$(curl -X POST -H "Content-Type: application/json" -d '{"key":"s7basti7bach4seasonsopera", "sender":"carlos"}' http://129.114.17.116:5000/api/assign/users/${username} 2> /dev/null )s
ip=$(echo "$answer" | cut -d':' -f1)

echo "http://129.114.17.116:5000/api/redirect/users/${username}/${ip}"