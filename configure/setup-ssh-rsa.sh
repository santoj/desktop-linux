#!/usr/bin/env bash

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../common.sh

SSH_DIR=~/.ssh
RSA_PRIVATE_KEY=$SSH_DIR/id_rsa
#USER_USER_SSH_CONFIG=$SSH_DIR/config
SSHD_CONFIG=/etc/ssh/sshd_config

#
# Setup /home/<user>/.ssh
#

# create ~/.ssh directory
if [[ -d "$SSH_DIR" && $(stat -c %a "$SSH_DIR") = 700 ]]; then
  echo "$SSH_DIR exists with correct permissions."
else
  echo "${GREEN_COLOR}Creating $SSH_DIR with correct permissions...${END_COLOR}"
  mkdir -p $SSH_DIR
  chmod 700 $SSH_DIR
fi

# we assume RSA format will be used
if [ -s "$RSA_PRIVATE_KEY" ]; then
  echo "Private ssh key already exists. Skipping key creation."
else
  echo "${GREEN_COLOR}Creating private ssh key...${END_COLOR}"
  ssh-keygen -t rsa -f $SSH_DIR/id_rsa -N ""
fi

if (grep -E -q "^\s*Port\s+22" $SSHD_CONFIG); then
  echo "${RED_COLOR}Please use a non-standard port (not port 22) for the ssh daemon.${END_COLOR}"
else
  echo "Confirmed non-standard ssh daemon port."
fi

#
# Review /etc/ssh/sshd_config settings
#

function echo_publickey_only() {
  printf "${RED_COLOR}Please restrict ssh access to public key authentication.\n"
  printf "Please update $SSHD_CONFIG with these settings:\n"
  printf "\tPubkeyAuthentication yes\n"
  printf "\tPasswordAuthentication no\n"
  printf "\tChallengeResponseAuthentication no\n\n${END_COLOR}"
}

# ignore comments and empty lines
SSHD_CONFIG_CLEANED=/tmp/sshd_config.cleaned
grep -E -v '^\s*#\s*' /etc/ssh/sshd_config | grep -E -v '^\s*$' | sort > $SSHD_CONFIG_CLEANED

# validate that these specific auth settings are explicity set
# not being set could be a problem given their default value when not present
PKAUTH_YES=false
PSWDAUTH_NO=false
CRAUTH_NO=false

grep -E -q "^\s*PubkeyAuthentication\s+yes" $SSHD_CONFIG_CLEANED
[ $? -eq 0 ] && PKAUTH_YES=true
grep -E -q "^\s*PasswordAuthentication\s+no" $SSHD_CONFIG_CLEANED
[ $? -eq 0 ] && PSWDAUTH_NO=true
grep -E -q "^\s*ChallengeResponseAuthentication\s+no" $SSHD_CONFIG_CLEANED
[ $? -eq 0 ] && CRAUTH_NO=true

if ! ($PKAUTH_YES && $PSWDAUTH_NO && $CRAUTH_NO); then
  echo_publickey_only
fi

# if permit empty passwords is in the config file, it better be set to no
# it's okay if it's not in the config file since it defaults to no
EMPTY_PSWD=$(grep -E "^\s*PermitEmptyPasswords\s*" $SSHD_CONFIG_CLEANED)
[ -n "$EMPTY_PSWD" ] && !(echo $EMPTY_PSWD | grep -E -q "^\s*PermitEmptyPasswords\s+no") &&\
  echo "${RED_COLOR}PermitEmptyPasswords should be disabled${END_COLOR}" && exit 1

echo "Confirmed configuration file settings."
echo "Exiting successfully."

