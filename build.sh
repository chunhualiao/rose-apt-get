#!/bin/bash

#--------- check user permission
if [ "$EUID" -ne 0 ]
  then echo "Please run as root since we will use --prefix=/usr/rose for the installation, like sudo this-script"
  exit
#else
#  echo "You are running with root priviledge as expected..."
fi

ROOT=$(pwd)

#-------------------- install dependent software
sudo apt update
sudo apt install -y make gcc g++ gfortran gcc-5 g++-5 gfortran-5 libxml2-dev texlive git automake autoconf libtool flex bison openjdk-8-jdk debhelper devscripts ghostscript libboost-{chrono,date-time,filesystem,iostreams,program-options,random,regex,serialization,signals,system,thread,wave}-dev

#-------------------- clone and configure ROSE
if [ ! -d "rose-develop" ]; then
	git clone https://github.com/rose-compiler/rose-develop
	(cd rose-develop && git am < ../0001-fix-rosePublicConfig.h-DESTDIR.patch)
fi

if [ ! -f "rose-develop/configure" ]; then
	(cd rose-develop && ./build)
fi

# support reentry of this script
if [ ! -d "rose-build" ]; then
       mkdir -p rose-build
fi

# note that --prefix is set to be /usr/rose
# so this script must use sudo priviledge to run!!
(cd rose-build && CC=gcc-5 CXX=g++-5 CXXFLAGS= ../rose-develop/configure --prefix=/usr/rose --with-C_OPTIMIZE=-O0 --with-CXX_OPTIMIZE=-O0 --with-C_DEBUG='-g' --with-CXX_DEBUG='-g' --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu/ --with-gfortran=/usr/bin/gfortran-5 --enable-languages=c,c++,fortran --enable-projects-directory --enable-edg_version=4.9)
if [ "$?" != "0" ]; then exit 1; fi

#-------------------- build ROSE
# -j$(nproc) may cause memory consumption issue on a virtual machine with limited memory. We use 1 process to be safe
#(cd rose-build && make core -j$(nproc) && make DESTDIR=$ROOT/rose-install install-core -j$(nproc))
(cd rose-build && make core && make DESTDIR=$ROOT/rose-install install-core)
if [ "$?" != "0" ]; then exit 1; fi

ROSE_VERSION=$(cat rose-develop/ROSE_VERSION)
ROSE_DEBIAN_BINARY_ROOT=rose-$ROSE_VERSION

# support reentry of this script
if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT" ]; then
#  rm -rf $ROSE_DEBIAN_BINARY_ROOT
  mkdir $ROSE_DEBIAN_BINARY_ROOT
fi

cp -r rose-install/* $ROSE_DEBIAN_BINARY_ROOT
cp -r runRoseUtil $ROSE_DEBIAN_BINARY_ROOT/usr/rose/bin
if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT/usr/bin" ]; then
  mkdir -p $ROSE_DEBIAN_BINARY_ROOT/usr/bin
fi

UTILS="astCopyReplTest defuseAnalysis outline virtualCFG astRewriteExample1  dotGenerator livenessAnalysis pdfGenerator xgenTranslator autoPar dotGeneratorWholeASTGraph loopProcessor preprocessingInfoDumper buildCallGraph identityTranslator mangledNameDumper qualifiedNameDumper codeInstrumentor interproceduralCFG measureTool rajaChecker defaultTranslator KeepGoingTranslator moveDeclarationToInnermostScope rose-config"

for util in $UTILS; do
	ln -fs ../rose/bin/runRoseUtil $ROSE_DEBIAN_BINARY_ROOT/usr/bin/$util
done

mkdir -p $ROSE_DEBIAN_BINARY_ROOT/etc/ld.so.conf.d
cp 10-rose.conf $ROSE_DEBIAN_BINARY_ROOT/etc/ld.so.conf.d


#================== make the debian package in a work directory inside the binary release candidate dir.
ROSE_VERSION=$(cat rose-develop/ROSE_VERSION)
ROSE_DEBIAN_BINARY_ROOT=rose-$ROSE_VERSION

if [ ! -d "$ROSE_DEBIAN_BINARY_ROOT/debian" ]; then
  mkdir -p $ROSE_DEBIAN_BINARY_ROOT/debian/
fi

cp -r debian/* $ROSE_DEBIAN_BINARY_ROOT/debian/
echo sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog
sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_DEBIAN_BINARY_ROOT/debian/changelog


# remove possible stale package
rm -rf rose_$(cat rose-develop/ROSE_VERSION)-2.orig.tar.gz

tar cfz rose_$(cat rose-develop/ROSE_VERSION)-2.orig.tar.gz $ROSE_DEBIAN_BINARY_ROOT

#--------sign your binary 
ROOT=`pwd`
echo "current path is $ROOT"

if [ ! -f "$ROOT/pubkey" ]; then
        keyVal=$(gpg --list-keys | awk '/sub/{if (length($2) > 0) print $2}')
        echo "${keyVal##*/}" > $ROOT/pubkey
fi

SIGN_KEY=$(cat $ROOT/pubkey)

echo $SIGN_KEY
if [ "x$SIGN_KEY" == "x" ]; then

#somehow pubkey may be emtpy!
# we regenerate it again
  rm -rf $ROOT/pubkey
  keyVal=$(gpg --list-keys | awk '/sub/{if (length($2) > 0) print $2}')
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


