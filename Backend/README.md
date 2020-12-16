Instructions for running gateway-backend.sh
1. configure:
FolderToCheck : the folder which new files are sent to from server
ControlFilesFolder: the folder contains all control files which are used to keep track of new added, running, and finished jobs
UnzipFilesFolder: the folder in which new added jobs are unzipped to
ShowAllJobIdsCommand: command/script to retrieve all names of jobs that are running in the system

2. slurm_skeleton:
Skeleton of submitting job scripts. Requires to be modified for different system


Note:
For compile job:
- Needs to have pattern *compile.zip
- Needs to contain compile.sh file which has all the compiles instructions

For running job:
- Needs to have pattern *run.zip
- Needs to contain run.sh which has all the compiles instructions but nothing else (e.g, does not contain #! /bin/bash)
- Needs to be under UNIX file format (i.e, WINDOWS file format may cause problem -- for examples, end wit \n\r instead of \r)

For server:
The output of jobs will be stored in /greyfish/sandbox/DIR_commonuser/output

