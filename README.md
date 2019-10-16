# ROSE Compiler debian package creator

## Overview

This repo stores all info. related to how to create a Personal Package Archive (PPA) for the ROSE compiler framework. Personal Package Archives (PPAs) are software repositories designed for Ubuntu users to easily distribute and install software. PPAs are often used to distribute pre-release software so that it can be tested.

## Directory layout

The subdirectory debian contains control, postinst, postrm ,etc to indicate dependencies and things to do after installation or uninstallation

build.sh is the script to obtain rose source files and build binaries out of them

runRoseUtil: a wrapper execution script for all ROSE tools. 

genkey.sh: simple script to generator gpg key pairs. 

## Registering an account with https://launchpad.net

If you don't yet have an account there, you have to create one first there. We assume your account is user1 for the purpose of this documentation. 

## Generating GPG key

Run genkey.sh, choose key type and length (you can use default values for them), specify you full name and email address, and set the password (it could be empty). Generating key takes a while. After this copy printed fingerprint of the key and send it to Launchpad on this [page](https://launchpad.net/~/+editpgpkeys) and wait for verification email. This email will contain encrypted GPG message. Copy it into a file and decrypt with *gpg --decrypt <file>=*. In the bottom of the list there will be a verification link, just open it with your browser.

Generation and sending key may be done only once. After that you can simply move your key between machines with *gpg --export-secret-keys* and *gpg --import*.

Find the key of your public key (the 8-character string after pub 2048R/ below), then send it to ubuntu server

```
gpg --fingerprint
/home/user1/.gnupg/pubring.kbx
-----------------------------
pub   rsa4096 2019-04-28
      Key fingerprint = XXXX xxxx xxxx xxxx xxxx  xxxx xxxx xxxx yyyy YYYY
uid                  Your name  <user1@email.com>
sub   rsa4096 2019-04-28


gpg --send-keys --keyserver keyserver.ubuntu.com yyyyYYYY 
```

## Building

To build a package simply run build.sh script. It installs all the dependencies, fetches the source code, builds it, and packs into a package.

In the end, there should be several new files generated under the current directory, such as

* rose-0.9.10.236
* rose_0.9.10.236-0.dsc
* rose_0.9.10.236-0_source.build
* rose_0.9.10.236-0_source.changes
* rose_0.9.10.236-0.tar.gz
* rose_0.9.10.236-2.orig.tar.gz


## Publishing

You have to create a new PPA under your account with https://launchpad.net first. Assuming your account name is user1, go to https://launchpad.net/~user1 and click on "Create a new PPA" . We suggest to name your PPA as rose, then the PPA path to your binariy package is ppa:user1/rose 
 

```
dput <ppa path> <file with .changes extension>

# example command line
dput ppa:user1/rose rose_0.9.10.236-0_source.changes

```
## Using the PPA

Assuming the user account is user1 again, within Ubuntu, type the following to install ROSE. 

```
sudo apt-get install -y software-properties-common
sudo add-apt-repository ppa:user1/rose
sudo apt-get update
sudo apt-get install rose 
sudo apt-get install rose rose-tools  
```

We have an experimental package built and uploaded. You can try it out using the following command lines (tested on Ubuntu 18.04 bionic):

```
sudo apt-get install software-properties-common
sudo add-apt-repository ppa:rosecompiler/rose-development
sudo apt-get install rose
sudo apt-get install rose-tools # Optional: Installs ROSE tools in addition to ROSE Coree
```

The installed ROSE binaries, headers and libraries are located under /usr/rose with symbolic links under /usr/bin 

```
/usr/rose$ ls
bin include lib  
```
