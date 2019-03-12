#!/bin/bash

SIGN_KEY=B4D212C8

sudo apt update
sudo apt install -y gcc g++ gfortran gcc-4.9 g++-4.9 gfortran-4.9 libxml2-dev texlive git automake autoconf libtool flex bison openjdk-8-jdk debhelper devscripts ghostscript

if [ ! -d "boost_1_61_0" ]; then
	wget -O boost-1.61.0.tar.bz2 http://sourceforge.net/projects/boost/files/boost/1.61.0/boost_1_61_0.tar.bz2/download \
        	&& tar xf boost-1.61.0.tar.bz2 \
        	&& rm -f boost-1.61.0.tar.bz2
fi

ROOT=$(pwd)

if [ ! -d "boost-install" ]; then
	(cd boost_1_61_0 && ./bootstrap.sh --prefix=/usr/rose --with-libraries=chrono,date_time,filesystem,iostreams,program_options,random,regex,serialization,signals,system,thread,wave && ./b2 --prefix=$ROOT/boost-install -sNO_BZIP2=1 toolset=gcc-4.9 install)
fi

if [ ! -d "rose-develop" ]; then
	git clone https://github.com/rose-compiler/rose-develop
	(cd rose-develop && git am < ../0001-fix-openjdk.patch)
fi

if [ ! -f "rose-develop/configure" ]; then
	(cd rose-develop && ./build)
fi

mkdir -p rose-build
(cd rose-build && CC=gcc-4.9 CXX=g++-4.9 ../rose-develop/configure --prefix=$ROOT/rose-install --with-C_OPTIMIZE=-O0 --with-CXX_OPTIMIZE=-O0 --with-C_DEBUG='-g' --with-CXX_DEBUG='-g' --with-boost=$ROOT/boost-install --with-gfortran=/usr/bin/gfortran-4.9 --enable-languages=c,c++,fortran --enable-projects-directory --enable-edg_version=4.12)

(cd rose-build && make core -j$(nproc) && make install-core -j$(nproc))

ROSE_VERSION=$(cat rose-develop/ROSE_VERSION)
ROSE_ROOT=rose-$ROSE_VERSION
rm -rf $ROSE_ROOT
mkdir -p $ROSE_ROOT/usr/rose
cp -r rose-install/* $ROSE_ROOT/usr/rose
cp -r boost-install/lib/* $ROSE_ROOT/usr/rose/lib
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
tar cfz rose_$(cat rose-develop/ROSE_VERSION).orig.tar.gz $ROSE_ROOT
(cd $ROSE_ROOT/debian && debuild -S -sa -k$SIGN_KEY)
