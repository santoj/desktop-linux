#!/usr/bin/env bash

WHOAMI=$(/usr/bin/whoami)
ORIGINAL_USER=$(logname)

CONFIG_DIR=/home/$ORIGINAL_USER/.config/desktop-linux

RED_COLOR=$'\e[1;31m'
GREEN_COLOR=$'\e[1;32m'
BLUE_COLOR=$'\e[0;34m'
END_COLOR=$'\e[0m'

exit_unless_root() {
  if [ "$WHOAMI" != "root" ]; then
    printf 'Please use "sudo" to execute this script.\n'
    exit 1
  fi
}

