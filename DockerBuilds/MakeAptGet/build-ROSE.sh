#!/bin/bash
set -e

cd
git clone -b pinnow2 https://github.com/chunhualiao/rose-apt-get.git
cd rose-apt-get
./build.sh

#dput ppa:rosecompiler/rose-development rose_${ROSE_VERSION}-0_source.changes
#dput ppa:rosecompiler/rose-development rose-tools_${ROSE_VERSION}-0_source.changes
