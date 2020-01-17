#!/usr/bin/env bash
# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/common.sh

printf "*** Running all scripts ***\n"

printf "\n${BLUE_COLOR}1: install/install-software.sh${END_COLOR}\n"
($DIR/install/install-software.sh)

printf "\n${BLUE_COLOR}2: configure/setup-ssh-rsa.sh${END_COLOR}\n"
($DIR/configure/setup-ssh-rsa.sh)

printf "\n${BLUE_COLOR}3: configure/check-ports.sh${END_COLOR}\n"
($DIR/configure/check-ports.sh)

printf "\n*** Finished running all scripts ***\n"

