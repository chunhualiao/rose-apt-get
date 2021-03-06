#!/bin/bash
set -e 
#--------- check user permission
if [ "$EUID" -ne 0 ]
  then echo "Please run as root since we will use --prefix=/usr/rose for the installation, like sudo this-script"
  exit
fi

# Grab command line argument to change apt-get version tag or rose branch
if [ $# == 0 ]; then
	APT_ROSE_VERSION=0
	BRANCH=develop
else
	APT_ROSE_VERSION=$1
	BRANCH=$2
fi

# Get OS version and set the version of gcc
SUPPORTED_LANGUAGES=c,c++,binaries
CODENAME=$(cat /etc/os-release | grep VERSION_CODENAME | sed 's/VERSION_CODENAME=//g')

if [ $CODENAME == xenial ] ; then  #Ubuntu 16.04
  GCC_VERSION=5
elif [ $CODENAME == bionic ] ; then #Ubuntu 18.04
  GCC_VERSION=7
elif [ $CODENAME == disco ] ; then #Ubuntu 19.04
  GCC_VERSION=8
elif [ $CODENAME == eoan ] ; then #Ubuntu 19.10
  GCC_VERSION=9
else
  echo "Unsupported version of OS"
  exit 1
fi

ROOT=$(pwd)

#---------------------------------------------------------------------------------- clone and configure ROSE
if [ ! -d "rose" ]; then
	git clone -b $BRANCH https://github.com/rose-compiler/rose
	sed -i "s/\$(pkgincludedir)/\$(DESTDIR)\$(pkgincludedir)/g" rose/Makefile.am
	echo $(cat rose/ROSE_VERSION).$APT_ROSE_VERSION >|rose/ROSE_VERSION
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
(cd rose-build && CC=gcc-$GCC_VERSION CXX=g++-$GCC_VERSION CXXFLAGS= ../rose/configure --prefix=/usr/rose --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu/ --enable-languages=$SUPPORTED_LANGUAGES --without-java --disable-boost-version-check --disable-tests-directory)
if [ "$?" != "0" ]; then exit 1; fi

#------------------------------------------------------------------------------------------------ build ROSE

# Moving of libtool is tempory solution to prevent install
export DESTDIR=$ROOT/rose-install
# Build Core
(cd rose-build && make DESTDIR=$ROOT/rose-install install-core -j40)
mv rose-install/usr/rose/bin/libtool ./
(cd rose-install/usr/rose/ && find . -type f >|../../../MakeInstallFile/rose.find)
(cd rose-install/usr/rose/ && find . -type l >>../../../MakeInstallFile/rose.find)
(cd rose-install/usr/rose/bin/ && ls >|../../../../MakeInstallFile/rose.bin)
mv ./libtool rose-install/usr/rose/bin/
echo "runRoseUtil" >>MakeInstallFile/rose.bin
# Build Tools
(cd rose-build && make DESTDIR=$ROOT/rose-install install-tools -j40)
mv rose-install/usr/rose/bin/libtool ./
(cd rose-install/usr/rose/ && find . -type f >|../../../MakeInstallFile/rose-tools.find)
(cd rose-install/usr/rose/ && find . -type l >>../../../MakeInstallFile/rose-tools.find)
(cd rose-install/usr/rose/bin/ && ls >|../../../../MakeInstallFile/rose-tools.bin)
mv ./libtool rose-install/usr/rose/bin/
echo "runRoseUtil" >>MakeInstallFile/rose-tools.bin
if [ "$?" != "0" ]; then exit 1; fi

(cd rose-build && make check-core)

# Make .install Files
(cd MakeInstallFile && python BuildInstall.py)
echo "usr/rose/bin/runRoseUtil /usr/rose/bin" >>MakeInstallFile/rose.install
echo "etc" >>MakeInstallFile/rose.install
 
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

echo sed -i -e "s/CODENAME/$CODENAME/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog
sed -i -e "s/CODENAME/$CODENAME/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog

echo sed -i -e "s/GCCVERSION/$GCC_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/control
sed -i -e "s/GCCVERSION/$GCC_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/control

cp MakeInstallFile/*.install $ROSE_DEBIAN_BINARY_ROOT/debian

# remove possible stale package
rm -rf rose_$(cat rose/ROSE_VERSION)-2.orig.tar.gz

tar cfz rose_$(cat rose/ROSE_VERSION)-2.orig.tar.gz $ROSE_DEBIAN_BINARY_ROOT

#--------sign your binary 

SIGN_KEY=$(gpg --list-public-keys --with-fingerprint --with-colons | sed -n '3p' | cut -d: -f10)

if [ "x$SIGN_KEY" == "x" ]; then
  #somehow pubkey may be emtpy!
  echo "Cannot find public key"
else
  echo "Public Key: $SIGN_KEY"
fi

(cd $ROSE_DEBIAN_BINARY_ROOT/debian && debuild --no-tgz-check -S -sa -k$SIGN_KEY)

