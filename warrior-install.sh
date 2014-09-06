#!/bin/bash

if ! dpkg-query -Wf'${Status}' curl 2>/dev/null | grep -q '^i'
then
  echo "Installing curl"
  sudo apt-get update
  sudo apt-get install -y curl
fi

exit 0
