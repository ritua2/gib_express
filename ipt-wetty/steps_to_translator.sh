#!/bin/bash

cd /mnt/rosedocker/

cd /home/ipt/
ls
cd opt/
ls
cd rose-inst/
ls
find . -name "librose"
ls bin/
cd lib/
ls
pwd
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD
cho $LD_LIBRARY_PATH 
echo $LD_LIBRARY_PATH 
gcc
whereis gcc
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/gcc
cd ../
ls
cd include/
ls
cd rose/
ls
cd ../
pwd
echo $PATH
export PATH=$PATH:/home/ipt/opt/rose-inst/bin
export PATH=$PATH:/home/ipt/opt/rose-inst/include
cd ../../
cd ../
vi it.cc
g++ it.cc 
g++ it.cc -I/home/ipt/opt/rose-inst/include
g++ it.cc -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose
whereis boost
cd /usr/include/boost/
ls
find / -name "boostlib"
whereis liboost
whereis libboost
whereis libboost-dev
which boost
cd /usr/
ls
cd lib/
ls
cd ../share/
ls
cd boost-build/
ls
cd src/
ls
cd ../../boostbook/
ls
cd /usr/lib/x86_64-linux-gnu
ls
ls | grep "thread"
cd /home/ipt/
ls
g++ it.cc -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu 
cd /usr/
ls
cd include/
ls
cd boost/
ls
pwd
cd /home/ipt/
g++ it.cc -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost
cd /usr/include/boost/system/
ls
cd /home/ipt/
g++ it.cc -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -I/usr
g++ it.cc -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -lboost_system
g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -lboost_system
cd /mnt/rosedocker/
grep -Ril "frontend" .
find . -name "frontend.h"
vi rose/src/rose.h
cd /home/ipt/
g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -lboost_system -lrose
g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -lboost_system -lrose -lboost_chrono
cd /mnt/rosedocker/
ls
mkdir roseCompile
cd roseCompile
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
tar -xvf jdk-8u131-linux-x64.tar.gz
export JAVA_HOME=/mnt/rosedocker/roseCompile/jdk1.8.0_131
export  JAVA_TOOL_OPTIONS="-Xms2G -Xmx2G"
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server
ls
cd /home/ipt/
g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu -I/usr/include/boost -lboost_system -lrose -lboost_chrono
ls
./a.out 
./a.out -c input.c
find . -name "librose.so.0"
export OLD_LDP=$LD_LIBRARY_PATH
echo $PWD
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/ipt/opt/rose-inst/lib
./a.out -c input.c
vi input.xc
vi input.c
./a.out -c input.c
vi rose_input.c 
vi input.
vi input.c
vi rose_input.c 
find / -name "librose.a"
history
history | cut -c 8-




# Things to run
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server:/home/ipt/opt/rose-inst/lib
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/ipt/opt/rose-inst/bin:/home/ipt/opt/rose-inst/include
