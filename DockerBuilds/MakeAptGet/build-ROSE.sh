#!/bin/bash
set -e

if [ $# >= 3 ]; then
	PPA=$3
else
	PPA=rose-development
fi

if [ $# >= 2 ]; then
	BRANCH=$2
else
	BRANCH=develop
fi

if [ $# >= 1 ]; then
	APT_VERSION=$1
else
	APT_VERSION=0
fi

echo "Version:$APT_VERSION - Branch:$BRANCH - PPA:$PPA"
cd
git clone https://github.com/chunhualiao/rose-apt-get.git
cd rose-apt-get
./build.sh $APT_VERSION $BRANCH
ROSE_VERSION=$(cat rose/ROSE_VERSION)
dput ppa:rosecompiler/$PPA rose_${ROSE_VERSION}-0_source.changes
