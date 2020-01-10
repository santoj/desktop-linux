#!/usr/bin/env bash

WHOAMI=$(/usr/bin/whoami)
ORIGINAL_USER=$(logname)

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR=/home/$ORIGINAL_USER/.config/desktop-linux
TEMP_DIR=$CONFIG_DIR/cache

ADDING_COLOR=$'\e[1;31m'
EXISTS_COLOR=$'\e[1;32m'
END_COLOR=$'\e[0m'

APT_OR_DPKG_INSTALLED=$TEMP_DIR/apt.installed
FLATPAK_INSTALLED=$TEMP_DIR/flatpak.installed
SNAP_INSTALLED=$TEMP_DIR/snap.installed
APT_PACKAGES=$CONFIG_DIR/apt-packages.txt
DPKG_PACKAGES=$CONFIG_DIR/dpkg-packages.txt
FLATPAK_PACKAGES=$CONFIG_DIR/flatpak-packages.txt
SNAP_PACKAGES=$CONFIG_DIR/snap-packages.txt


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

function is_snap_installed {
  grep -q "^$1\s*" $SNAP_INSTALLED
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

function snap_install_if_missing {
  SNAP_NAME=$1
  if is_snap_installed $SNAP_NAME; then
    echo_found "$SNAP_NAME"
  else
    echo_adding "$SNAP_NAME"
    snap install $SNAP_NAME || exit_on_error "Failed to install SNAP package $SNAP_NAME"
  fi
}

function install_packages {
  # PARAMS: <file with a list of packages> <function that will install the packages>
  FILE_WITH_PACKAGES=$1
  FUNCTION_TO_INSTALL_PACKAGES=$2
  if [ -s $FILE_WITH_PACKAGES ]; then
    while read -r package url; do
      # ignore comments and blank lines
      [[ "$package" =~ ^#.*$ || "$package" =~ ^\s*$ ]] && continue
      # execute setup-<package> file if present to configure prerequisites (e.g., APT Sources, Keys, etc.)
      SETUP_FILE="$CONFIG_DIR/setup-$package"
      if [[ -s $SETUP_FILE ]]; then
        echo "Processing $SETUP_FILE..."
        source $SETUP_FILE || exit_on_error "Failed to process $SETUP_FILE"
      fi
      # install the given package
      ($FUNCTION_TO_INSTALL_PACKAGES $package)
    done < $FILE_WITH_PACKAGES
  fi
}


###
### MAIN
###
if [ "$WHOAMI" != "root" ]; then
  printf 'Please use "sudo" to execute this script.\n'
  exit 3
fi


mkdir -p $CONFIG_DIR
mkdir -p $TEMP_DIR
[ -r $APT_PACKAGES ]     || touch $APT_PACKAGES
[ -r $DPKG_PACKAGES ]    || touch $DPKG_PACKAGES
[ -r $FLATPAK_PACKAGES ] || touch $FLATPAK_PACKAGES
[ -r $SNAP_PACKAGES ]    || touch $SNAP_PACKAGES
chown -R $ORIGINAL_USER:$ORIGINAL_USER $CONFIG_DIR
chown -R $ORIGINAL_USER:$ORIGINAL_USER $TEMP_DIR


NUM_LINES=$(wc -l $APT_PACKAGES $DPKG_PACKAGES $FLATPAK_PACKAGES $SNAP_PACKAGES | grep total | awk '{ print $1 }')
if [[ $NUM_LINES -lt 1 ]]; then
  printf "WARNING: No packages found in the packages files:\n\t$APT_PACKAGES\n\t$DPKG_PACKAGES\n\t$FLATPAK_PACKAGES\n\t$SNAP_PACKAGES\n\n"
  printf "Please see the sample packages in\n\t$DIR\nand add desired packages to your files.\n\n"
  exit 2
fi


###
### Update Package Index and remember what we have already installed
###
apt-get update  || (echo "APT is required installed. Please install and then rerun this script." && exit 1)
flatpak update  || (echo "Flatpak is not installed. Any flatpak packages will be ignored." && MISSING_FLATPAK=true)
gdebi --version || (echo "GDebi is not installed. Any deb packages will be ignored." && MISSING_GDEBI=true)
if [[ $(grep "^ID=" /etc/os-release | grep "ubuntu") ]]; then
  snap refresh  || (echo "Snap is not installed. Any snap packages will be ignored." && MISSING_SNAP=true)
else
  MISSING_SNAP=true
fi

# Alternate option of "dpkg --get-selections" was avoided since we are using apt for most things
apt list 2>/dev/null | grep installed              > $APT_OR_DPKG_INSTALLED
[ ! $MISSING_FLATPAK ] && flatpak list 2>/dev/null > $FLATPAK_INSTALLED
[ ! $MISSING_SNAP ]    && snap list    2>/dev/null > $SNAP_INSTALLED


###
### Install Packages - to keep code DRY, we pass a function to a function
###
install_packages                           $APT_PACKAGES     apt_install_if_missing
[ ! $MISSING_GDEBI ]   && install_packages $DPKG_PACKAGES    dpkg_install_if_missing
[ ! $MISSING_FLATPAK ] && install_packages $FLATPAK_PACKAGES flatpak_install_if_missing
[ ! $MISSING_SNAP ]    && install_packages $SNAP_PACKAGES    snap_install_if_missing

# get rid of any unnecessary packages
apt autoremove
#flatpak remove --unused


###
### Firmware Updates
###
fwupdmgr get-updates


echo "Installations complete...exiting"

