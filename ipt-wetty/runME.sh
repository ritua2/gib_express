#!/bin/bash

export JAVA_HOME=/mnt/rosedocker/roseCompile/jdk1.8.0_131
export  JAVA_TOOL_OPTIONS="-Xms2G -Xmx2G"
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/jdk1.8.0_131/jre/lib/amd64/server
export PATH=/mnt/rosedocker/roseCompile/lib/bin:$PATH
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/lib/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/boost_install/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/rosedocker/roseCompile/roseCompileTree/lib:$LD_LIBRARY_PATH
