#!/bin/bash

gpg --gen-key

gpg --list-public-keys --with-fingerprint --with-colons | sed -n '3p' | cut -d: -f10
