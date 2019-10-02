#!/bin/bash
set -e
cd
apt-get install -y rose
rose-cc -o rose_hello-world-c rose_hello-world.c
rose-c++ -o rose_hello-world-c++ rose_hello-world.cpp
./rose_hello-world-c
./rose_hello-world-c++

