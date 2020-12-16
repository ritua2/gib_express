FROM ubuntu:18.04



WORKDIR /mnt/rosedocker


RUN apt-get update && apt-get install -y git wget build-essential libtool flex bison python3-dev\
    unzip perl-doc doxygen texlive libboost-all-dev gdb gcc g++ gfortran autoconf automake\
    libxml2-dev libdwarf-dev graphviz openjdk-8-jdk-headless openjdk-8-jre-headless ghostscript &&\
    useradd -ms /bin/bash ipt &&\
    git clone https://github.com/rose-compiler/rose &&\
    cd rose/ && ./build && cd ../ && mkdir buildrose/ && cd buildrose/ &&\
    ../rose/configure --prefix=/home/ipt/opt/rose-inst --enable-edg_version=4.12 --with-boost-libdir=/usr/lib/x86_64-linux-gnu --with-boost=/usr &&\
    make core -j4 && make install-core -j4

