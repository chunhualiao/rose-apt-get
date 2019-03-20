#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root, like sudo this-script"
  exit
else
  echo "You are running with root priviledge..."
fi
