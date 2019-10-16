#!/bin/bash
set -e

cd
git clone https://github.com/chunhualiao/rose-apt-get.git
cd rose-apt-get
./build.sh
ROSE_VERSION=$(cat rose/ROSE_VERSION)
dput ppa:rosecompiler/rose-development rose_${ROSE_VERSION}-0_source.changes
if [[ $ROSE_VERSION == *.0 ]] ; then 
    dput ppa:rosecompiler/rose rose_${ROSE_VERSION}-0_source.changes
fi
