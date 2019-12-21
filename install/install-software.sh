#!/usr/bin/env bash

#abort on errors
set -eo pipefail

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR=$DIR/.cache

WHOAMI=$(/usr/bin/whoami)

ADDING_COLOR=$'\e[1;31m'
EXISTS_COLOR=$'\e[1;32m'
END_COLOR=$'\e[0m'

APT_INSTALLED=$TEMP_DIR/apt.installed
STANDARD_APT_PACKAGES=$DIR/standard-apt-packages.txt
NONSTANDARD_DPKG_PACKAGES=$DIR/nonstandard-dpkg-packages.txt

function echo_found {
  echo "Found  ${EXISTS_COLOR}$1${END_COLOR}"
}

function echo_adding {
  echo "Adding ${ADDING_COLOR}$1${END_COLOR}"
}

function is_installed {
  grep -q "$1/" $APT_INSTALLED
}

function apt_install_if_missing {
  if is_installed $1; then
    echo_found "$1"
  else
    echo_adding "$1"
    apt-get -y install $1
  fi
}

function dpkg_install_if_missing {
  DEB_NAME=$1
  DEB_FILE=$TEMP_DIR/$DEB_NAME.deb
  DEB_URL=$2
  if is_installed $DEB_NAME; then
    echo_found "$DEB_NAME"
  else
    echo_adding "$DEB_NAME"
    # download deb file if missing
    [[ ! -s $DEB_FILE ]] && wget -q $DEB_URL -O $DEB_FILE || echo "DEB file already exists: $DEB_FILE"
    # use gdebi rather than dpkg since it handles dependecies better
    gdebi -qn $DEB_FILE
  fi
}

if [ "$WHOAMI" != "root" ]; then
  printf 'Please use "sudo" to execute this script.\n'
  exit 100
fi

mkdir -p $TEMP_DIR


###
### Configure APT Sources and Keys
###
for f in $DIR/_setup-*; do # this assumes at least 1 file exists
  echo "Processing $f file..";
  source $f
done


###
### Update Package Index and remember what we have already installed
###
apt-get update

# Alternate option of "dpkg --get-selections" was avoided since we are using apt for most things
apt list 2>/dev/null | grep installed > $APT_INSTALLED


###
### Install Standard APT Packages
###
while read -r line; do
  # ignore comments and blank lines
  [[ "$line" =~ ^#.*$ || "$line" =~ ^\s*$ ]] && continue

  apt_install_if_missing $line
done < $STANDARD_APT_PACKAGES


###
### Install Non-Standard Packages
###
while read -r line; do
  # ignore comments and blank lines
  [[ "$line" =~ ^#.*$ || "$line" =~ ^\s*$ ]] && continue

  dpkg_install_if_missing $line
done < $NONSTANDARD_DPKG_PACKAGES



###
### Firmware Updates
###
fwupdmgr get-updates


exit 0

