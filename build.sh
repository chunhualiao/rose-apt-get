#!/bin/bash
set -e 
#--------- check user permission
if [ "$EUID" -ne 0 ]
  then echo "Please run as root since we will use --prefix=/usr/rose for the installation, like sudo this-script"
  exit
#else
#  echo "You are running with root priviledge as expected..."
fi

ROOT=$(pwd)

#-------------------- install dependent software
#apt update
#apt install -y make gfortran gcc-7 g++-7 gfortran-7 libxml2-dev texlive git automake autoconf libtool flex bison openjdk-8-jdk debhelper devscripts ghostscript python lsb-core perl-doc libboost-{chrono,date-time,filesystem,iostreams,program-options,random,regex,serialization,signals,system,thread,wave}-dev

#-------------------- clone and configure ROSE
if [ ! -d "rose" ]; then
	git clone -b develop https://github.com/rose-compiler/rose
	sed "s/\$(pkgincludedir)/\$(DESTDIR)\$(pkgincludedir)/g" rose/Makefile.am >|temp.txt
	mv temp.txt rose/Makefile.am
        if [ "$?" != "0" ]; then exit 1; fi
fi

if [ ! -f "rose/configure" ]; then
	(cd rose && ./build)
fi

# support reentry of this script
if [ ! -d "rose-build" ]; then
       mkdir -p rose-build
fi

# note that --prefix is set to be /usr/rose
# so this script must use sudo priviledge to run!!
(cd rose-build && CC=gcc-7 CXX=g++-7 CXXFLAGS= ../rose/configure --prefix=/usr/rose --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu/ --enable-languages=c,c++ --without-java --enable-edg_version=5.0 --disable-boost-version-check --disable-tests-directory)
if [ "$?" != "0" ]; then exit 1; fi

#-------------------- build ROSE
# -j$(nproc) may cause memory consumption issue on a virtual machine with limited memory. We use 2 process to be safe
#(cd rose-build && make core -j$(nproc) && make DESTDIR=$ROOT/rose-install install-core -j$(nproc))
#(cd rose-build e -j4)

#(cd rose-build && make core -j4)
#if [ "$?" != "0" ]; then exit 1; fi

export DESTDIR=$ROOT/rose-install
# Build Core
(cd rose-build && make DESTDIR=$ROOT/rose-install install-core -j40)
(cd rose-install/usr/rose/ && find . -type f,l >|../../../MakeInstallFile/rose.find)
(cd rose-install/usr/rose/bin/ && ls >|../../../../MakeInstallFile/rose.bin)
echo "runRoseUtil" >>MakeInstallFile/rose.bin
# Build Tools
(cd rose-build && make DESTDIR=$ROOT/rose-install install-tools -j40)
(cd rose-install/usr/rose/ && find . -type f,l >|../../../MakeInstallFile/rose-tools.find)
(cd rose-install/usr/rose/bin/ && ls >|../../../../MakeInstallFile/rose-tools.bin)
echo "runRoseUtil" >>MakeInstallFile/rose-tools.bin
if [ "$?" != "0" ]; then exit 1; fi

# Make .install Files
(cd MakeInstallFile && python BuildInstall.py)
echo "usr/rose/bin/runRoseUtil /usr/rose/bin" >>MakeInstallFile/rose.install
sed -i '1s/^/#define __builtin_bswap16 __bswap_constant_16\n/' $ROOT/rose-install/usr/rose/include/edg/g++-7_HEADERS/hdrs7/bits/byteswap.h
 
ROSE_VERSION=$(cat rose/ROSE_VERSION)
ROSE_DEBIAN_BINARY_ROOT=rose-$ROSE_VERSION
ROSE_DEBIAN_BINARY_ROOT_TOOLS=rose-tools-$ROSE_VERSION

# support reentry of this script
if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT" ]; then
  mkdir $ROSE_DEBIAN_BINARY_ROOT
fi

cp -r rose-install/* $ROSE_DEBIAN_BINARY_ROOT
cp -r runRoseUtil $ROSE_DEBIAN_BINARY_ROOT/usr/rose/bin
if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT/usr/bin" ]; then
  mkdir -p $ROSE_DEBIAN_BINARY_ROOT/usr/bin
fi

TOOLS=$(cat MakeInstallFile/rose-tools.bin)

for util in $TOOLS; do
	(ln -fs ../rose/bin/runRoseUtil $ROSE_DEBIAN_BINARY_ROOT/usr/bin/$util)
	if [ "$?" != "0" ]; then exit 1; fi
done

mkdir -p $ROSE_DEBIAN_BINARY_ROOT/etc/ld.so.conf.d
cp 10-rose.conf $ROSE_DEBIAN_BINARY_ROOT/etc/ld.so.conf.d

#================== make the debian package in a work directory inside the binary release candidate dir.
ROSE_VERSION=$(cat rose/ROSE_VERSION)
ROSE_DEBIAN_BINARY_ROOT=rose-$ROSE_VERSION

if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT/debian" ]; then
  mkdir -p $ROSE_DEBIAN_BINARY_ROOT/debian/
fi

cp -r debian/* $ROSE_DEBIAN_BINARY_ROOT/debian/
echo sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog
sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog

echo sed -i -e "s/DATE/$(date -R)/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog
sed -i -e "s/DATE/$(date -R)/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog

cp MakeInstallFile/*.install $ROSE_DEBIAN_BINARY_ROOT/debian

# remove possible stale package
rm -rf rose_$(cat rose/ROSE_VERSION)-2.orig.tar.gz

tar cfz rose_$(cat rose/ROSE_VERSION)-2.orig.tar.gz $ROSE_DEBIAN_BINARY_ROOT

#--------sign your binary 
ROOT=`pwd`
echo "current path is $ROOT"

if [ ! -f "$ROOT/pubkey" ]; then
        keyVal=$(gpg --list-keys | sed -n 4p | tail -c 9)
        echo "${keyVal##*/}" > $ROOT/pubkey
fi

SIGN_KEY=$(cat $ROOT/pubkey)

echo $SIGN_KEY
if [ "x$SIGN_KEY" == "x" ]; then

#somehow pubkey may be emtpy!
# we regenerate it again
  rm -rf $ROOT/pubkey
  keyVal=$(gpg --list-keys | sed -n 4p | tail -c 9)
  echo "${keyVal##*/}" > $ROOT/pubkey

  if [ "x$SIGN_KEY" == "x" ]; then

    echo "Error, cannot find your public GPG key, aborting..."
    echo "Please create or import your key pairs to this machine"
    exit 1;
  fi
else
  echo the public key found is: $SIGN_KEY
fi

(cd $ROSE_DEBIAN_BINARY_ROOT/debian && debuild --no-tgz-check -S -sa -k$SIGN_KEY)

