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

APT_OR_DPKG_INSTALLED=$TEMP_DIR/apt.installed
FLATPAK_INSTALLED=$TEMP_DIR/flatpak.installed
APT_PACKAGES=$DIR/apt-packages.txt
DPKG_PACKAGES=$DIR/dpkg-packages.txt
FLATPAK_PACKAGES=$DIR/flatpak-packages.txt

function echo_found {
  echo "Found  ${EXISTS_COLOR}$1${END_COLOR}"
}

function echo_adding {
  echo "Adding ${ADDING_COLOR}$1${END_COLOR}"
}

function is_apt_installed {
  grep -q "$1/" $APT_OR_DPKG_INSTALLED
}

function is_flatpak_installed {
  grep -q "$1/" $FLATPAK_INSTALLED
}

function apt_install_if_missing {
  APT_NAME=$1
  if is_apt_installed $APT_NAME; then
    echo_found "$APT_NAME"
  else
    echo_adding "$APT_NAME"
    apt-get -y install $APT_NAME
  fi
}

function dpkg_install_if_missing {
  DEB_NAME=$1
  DEB_FILE=$TEMP_DIR/$DEB_NAME.deb
  DEB_URL=$2
  if is_apt_installed $DEB_NAME; then
    echo_found "$DEB_NAME"
  else
    echo_adding "$DEB_NAME"
    # download deb file if missing
    [[ ! -s $DEB_FILE ]] && wget -q $DEB_URL -O $DEB_FILE || echo "DEB file already exists: $DEB_FILE"
    # use gdebi rather than dpkg since it handles dependecies better
    gdebi -qn $DEB_FILE
  fi
}

function flatpak_install_if_missing {
  #E.g., flatpak install https://flathub.org/repo/appstream/org.vim.Vim.flatpakref
  FLATPAK_NAME=$1
  if is_flatpak_installed $FLATPAK_NAME; then
    echo_found "$FLATPAK_NAME"
  else
    echo_adding "$FLATPAK_NAME"
    flatpak install $FLATPAK_NAME
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
for f in $DIR/_setup-*; do
  # in case there aren't any setup- files, we don't want to error out
  [[ ! -s $f ]] && continue
  echo "Processing $f file..";
  source $f
done


###
### Update Package Index and remember what we have already installed
###
apt-get update
flatpak update

# Alternate option of "dpkg --get-selections" was avoided since we are using apt for most things
apt list 2>/dev/null | grep installed > $APT_OR_DPKG_INSTALLED
flatpak list 2>/dev/null > $FLATPAK_INSTALLED


###
### Install Packages
###
function install_packages {
  # PARAMS: <file with a list of packages> <function that will install the packages>
  FILE_WITH_PACKAGES=$1
  FUNCTION_TO_INSTALL_PACKAGES=$2
  if [ -s $FILE_WITH_PACKAGES ]; then
    while read -r line; do
      # ignore comments and blank lines
      [[ "$line" =~ ^#.*$ || "$line" =~ ^\s*$ ]] && continue
      ($FUNCTION_TO_INSTALL_PACKAGES $line)
    done < $FILE_WITH_PACKAGES
  fi
}

install_packages $APT_PACKAGES     apt_install_if_missing
install_packages $DPKG_PACKAGES    dpkg_install_if_missing
install_packages $FLATPAK_PACKAGES flatpak_install_if_missing

# get rid of any unnecessary packages
apt autoremove
#flatpak remove --unused

###
### Firmware Updates
###
fwupdmgr get-updates


exit 0

