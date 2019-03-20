#!/bin/bash

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

mkdir -p rose-build
(cd rose-build && CC=gcc-5 CXX=g++-5 CXXFLAGS= ../rose-develop/configure --prefix=/usr/rose --with-C_OPTIMIZE=-O0 --with-CXX_OPTIMIZE=-O0 --with-C_DEBUG='-g' --with-CXX_DEBUG='-g' --with-boost=/usr --with-boost-libdir=/usr/lib/x86_64-linux-gnu/ --with-gfortran=/usr/bin/gfortran-5 --enable-languages=c,c++,fortran --enable-projects-directory --enable-edg_version=4.12)
if [ "$?" != "0" ]; then exit 1; fi

#-------------------- build ROSE
# -j$(nproc) may cause memory consumption issue on a virtual machine with limited memory. We use 1 process to be safe
#(cd rose-build && make core -j$(nproc) && make DESTDIR=$ROOT/rose-install install-core -j$(nproc))
(cd rose-build && make core && make DESTDIR=$ROOT/rose-install install-core)
if [ "$?" != "0" ]; then exit 1; fi

ROSE_VERSION=$(cat rose-develop/ROSE_VERSION)
ROSE_ROOT=rose-$ROSE_VERSION
rm -rf $ROSE_ROOT
mkdir $ROSE_ROOT
cp -r rose-install/* $ROSE_ROOT
cp -r runRoseUtil $ROSE_ROOT/usr/rose/bin
mkdir -p $ROSE_ROOT/usr/bin

UTILS="astCopyReplTest defuseAnalysis outline virtualCFG astRewriteExample1  dotGenerator livenessAnalysis pdfGenerator xgenTranslator autoPar dotGeneratorWholeASTGraph loopProcessor preprocessingInfoDumper buildCallGraph identityTranslator mangledNameDumper qualifiedNameDumper codeInstrumentor interproceduralCFG measureTool rajaChecker defaultTranslator KeepGoingTranslator moveDeclarationToInnermostScope rose-config"

for util in $UTILS; do
	ln -fs ../rose/bin/runRoseUtil $ROSE_ROOT/usr/bin/$util
done

mkdir -p $ROSE_ROOT/etc/ld.so.conf.d
cp 10-rose.conf $ROSE_ROOT/etc/ld.so.conf.d

mkdir -p $ROSE_ROOT/debian/
cp -r debian/* $ROSE_ROOT/debian/
echo sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_ROOT/debian/changelog
sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_ROOT/debian/changelog
tar cfz rose_$(cat rose-develop/ROSE_VERSION)-2.orig.tar.gz $ROSE_ROOT


#--------sign your binary 
if [ ! -f "$ROOT/pubkey" ]; then
	keyVal=$(gpg --list-keys | awk '/sub/{if (length($2) > 0) print $2}')
	echo "${keyVal##*/}" > $ROOT/pubkey
fi

SIGN_KEY=$(cat $ROOT/pubkey)

if [ "x$SIGN_KEY" == "x" ]; then
  echo "Error, cannot find your public GPG key, aborting..."
  echo "Please create or import your key pairs to this machine"
  exit 1;
fi

(cd $ROSE_ROOT/debian && debuild --no-tgz-check -S -sa -k$SIGN_KEY)
