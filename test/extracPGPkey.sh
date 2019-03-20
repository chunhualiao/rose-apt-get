#!/bin/bash
ROOT=`pwd`
if [ ! -f "$ROOT/pubkey" ]; then
        keyVal=$(gpg --list-keys | awk '/sub/{if (length($2) > 0) print $2}')
        echo "${keyVal##*/}" > $ROOT/pubkey
fi

SIGN_KEY=$(cat $ROOT/pubkey)

if [ "x$SIGN_KEY" == "x" ]; then
  echo "Error, cannot find your public GPG key, aborting..."
  echo "Please create or import your key pairs to this machine"
  exit 1;
else
  echo the public key found is: $SIGN_KEY
fi

