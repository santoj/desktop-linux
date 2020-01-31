#!/usr/bin/env bash
# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/common.sh

exit_unless_root

printf "*** Running all scripts ***\n"

printf "\n${BLUE_COLOR}1: install/install-software.sh${END_COLOR}\n"
($DIR/install/install-software.sh)

printf "\n${BLUE_COLOR}2: configure/setup-ssh-rsa.sh${END_COLOR}\n"
(runuser -l "$ORIGINAL_USER" -c "$DIR/configure/setup-ssh-rsa.sh")

printf "\n${BLUE_COLOR}3: configure/check-ports.sh${END_COLOR}\n"
($DIR/configure/check-ports.sh)

printf "\n${BLUE_COLOR}4: configure/setup-vim-pathogen.sh${END_COLOR}\n"
(runuser -l "$ORIGINAL_USER" -c "$DIR/configure/setup-vim-pathogen.sh")

printf "\n*** Finished running all scripts ***\n"

