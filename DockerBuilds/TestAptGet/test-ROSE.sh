#!/bin/bash
set -e
if [ "$1" == "stable" ]; then
	sed -i 's/development/stable/g' /etc/apt/sources.list
fi
cd
apt-get update
apt-get install -y rose-tools
rose-cc -o rose_hello-world-c rose_hello-world.c
./rose_hello-world-c
rose-c++ -o rose_hello-world-c++ rose_hello-world.cpp
./rose_hello-world-c++
git clone https://github.com/LLNL/backstroke.git
cd backstroke
make install
make check
