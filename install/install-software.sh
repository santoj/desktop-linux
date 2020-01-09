#!/usr/bin/env bash

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR=~/.config/desktop-linux
TEMP_DIR=$CONFIG_DIR/cache

WHOAMI=$(/usr/bin/whoami)
ORIGINAL_USER=$(logname)

ADDING_COLOR=$'\e[1;31m'
EXISTS_COLOR=$'\e[1;32m'
END_COLOR=$'\e[0m'

APT_OR_DPKG_INSTALLED=$TEMP_DIR/apt.installed
FLATPAK_INSTALLED=$TEMP_DIR/flatpak.installed
APT_PACKAGES=$CONFIG_DIR/apt-packages.txt
DPKG_PACKAGES=$CONFIG_DIR/dpkg-packages.txt
FLATPAK_PACKAGES=$CONFIG_DIR/flatpak-packages.txt

function exit_on_error {
  echo "$1"
  exit 1
}

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
    apt-get -y install $APT_NAME || exit_on_error "Failed to install APT package $APT_NAME"
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
    gdebi -qn $DEB_FILE || exit_on_error "Failed to install deb file $DEB_FILE"
  fi
}

function flatpak_install_if_missing {
  #E.g., flatpak install https://flathub.org/repo/appstream/org.vim.Vim.flatpakref
  FLATPAK_NAME=$1
  if is_flatpak_installed $FLATPAK_NAME; then
    echo_found "$FLATPAK_NAME"
  else
    echo_adding "$FLATPAK_NAME"
    flatpak install $FLATPAK_NAME || exit_on_error "Failed to install flatpak $FLATPAK_NAME"
  fi
}

###
### MAIN
###
if [ "$WHOAMI" != "root" ]; then
  printf 'Please use "sudo" to execute this script.\n'
  exit 100
fi

mkdir -p $CONFIG_DIR
mkdir -p $TEMP_DIR
chown -R $ORIGINAL_USER:$ORIGINAL_USER $CONFIG_DIR
chown -R $ORIGINAL_USER:$ORIGINAL_USER $TEMP_DIR

[ -r $APT_PACKAGES ] || touch $APT_PACKAGES
[ -r $DPKG_PACKAGES ] || touch $DPKG_PACKAGES
[ -r $FLATPAK_PACKAGES ] || touch $FLATPAK_PACKAGES

NUM_LINES=$(wc -l $APT_PACKAGES $DPKG_PACKAGES $FLATPAK_PACKAGES | grep total | awk '{ print $1 }')
if [[ $NUM_LINES -lt 1 ]]; then
  printf "WARNING: No packages found in the packages files:\n\t$APT_PACKAGES\n\t$DPKG_PACKAGES\n\t$FLATPAK_PACKAGES\n\n"
  printf "Please see the sample packages in\n\t$DIR\nand add desired packages to your files.\n\n"
  exit 2
fi

# TODO - ensure _setup-xxx files only run if/when the corresponding package is being installed

###
### Configure APT Sources and Keys
###
for f in $DIR/_setup-*; do
  # in case there aren't any setup- files, we don't want to error out
  [[ ! -s $f ]] && continue
  echo "Processing $f file...";
  source $f || exit_on_error "Failed to process $f"
done


###
### Update Package Index and remember what we have already installed
###
apt-get update || exit_on_error "Is APT installed?"
flatpak update || exit_on_error "Is Flatpak installed?"
gdebi --version || exit_on_error "Is gdebi installed?"


# Alternate option of "dpkg --get-selections" was avoided since we are using apt for most things
apt list 2>/dev/null | grep installed > $APT_OR_DPKG_INSTALLED
flatpak list 2>/dev/null > $FLATPAK_INSTALLED

# TODO: let users configure packages and leave what we have as examples only...ensure the project works by default on multiple platforms

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

