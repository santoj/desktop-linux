#!/usr/bin/env bash

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../common.sh

VBOX_DIR=/opt/virtualbox
VBOX_EXT_PACK=Oracle_VM_VirtualBox_Extension_Pack.vbox-extpack

if [ -f $VBOX_DIR/$VBOX_EXT_PACK ]; then
  # requires user interaction and "root"
  VBoxManage extpack install $VBOX_DIR/$VBOX_EXT_PACK --accept-license "y"
else
  echo "Nothing to do"
fi

