#!/bin/bash

# Source this file right after entering the container
cd /mnt/rosedocker

mkdir roseCompile
cd roseCompile
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
tar -xvf jdk-8u131-linux-x64.tar.gz
export JAVA_HOME=/mnt/rosedocker/roseCompile/jdk1.8.0_131
export  JAVA_TOOL_OPTIONS="-Xms2G -Xmx2G"

cd /home/ipt

export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server:/home/ipt/opt/rose-inst/lib
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/ipt/opt/rose-inst/bin:/home/ipt/opt/rose-inst/include


# To compile the translator in a file called simple_translator.cc
# g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include \
#     -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu \
#     -I/usr/include/boost -lboost_system -lrose -lboost_chrono



g++ it.cc -L/home/ipt/opt/rose-inst/lib  -I/home/ipt/opt/rose-inst/include \
    -I/home/ipt/opt/rose-inst/include/rose -L//usr/lib/x86_64-linux-gnu \
    -I/usr/include/boost -lboost_system -lrose -lboost_chrono

