#!/bin/bash


# Starts or ends the Reef communication APIs


if [ $# -eq 0 ]; then
   printf "No arguments provided, use -h flag for help\n"
   exit 1
fi


if [ $1 == "-h" ]; then
   printf "Automatic API daemon set-up\n"
   printf "Use flag -up to set-up the APIs\n"
   printf "Use flag -down to cancel the APIs\n"
   printf "\n All APIs will be started with 4 workers, modify this file if more workers are required\n"
   exit 0
fi


if [ $1 == "-up" ]; then 
  gunicorn -w $greyfish_threads -b 0.0.0.0:2000 grey_regular:app &
  gunicorn -w $greyfish_threads -b 0.0.0.0:2001 gget_all:app &
  gunicorn -w $greyfish_threads -b 0.0.0.0:2002 push_all:app &
  gunicorn -w $greyfish_threads -b 0.0.0.0:2003 new_user:app &
  gunicorn -w $greyfish_threads -b 0.0.0.0:2004 admin:app &
  printf "Greyfish APIs are now active\n"
  exit 0
fi


if [ $1 == "-down" ]; then 
   
   pkill gunicorn
   printf "Greyfish APIs have been disconnected\n"
   exit 0
fi
