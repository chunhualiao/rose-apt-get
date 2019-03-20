#!/bin/bash

ROSE_VERSION=$(cat rose-develop/ROSE_VERSION)
ROSE_ROOT=rose-$ROSE_VERSION

if [ ! -d "$ROSE_ROOT/debian" ]; then
  mkdir -p $ROSE_ROOT/debian/
fi

cp -r debian/* $ROSE_ROOT/debian/
echo sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_ROOT/debian/changelog
sed -i -e "s/\$VERSION/$ROSE_VERSION/g" $ROSE_ROOT/debian/changelog


# remove possible stale package
rm -rf rose_$(cat rose-develop/ROSE_VERSION)-2.orig.tar.gz

tar cfz rose_$(cat rose-develop/ROSE_VERSION)-2.orig.tar.gz $ROSE_ROOT

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

(cd $ROSE_ROOT/debian && debuild --no-tgz-check -S -sa -k$SIGN_KEY)

