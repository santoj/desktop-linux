#!/usr/bin/env bash

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../common.sh

if [ $# -eq 1 ]; then
  KNOWN_PORTS_FILE=$1
else
  KNOWN_PORTS_FILE=$CONFIG_DIR/known-ports.txt
fi

validate_port_service() {
  local PORT=$1
  local SERVICE=$2

  if (grep -q "^\s*$PORT" $KNOWN_PORTS_FILE); then
    echo "$PORT:$SERVICE ${GREEN_COLOR}OK${END_COLOR}"
  else
    echo "$PORT:$SERVICE ${RED_COLOR}WARNING${END_COLOR}"
  fi
}

exit_unless_root

if [ -r $KNOWN_PORTS_FILE ]; then
  printf "Checking open ports against expected ones found at\n\t$KNOWN_PORTS_FILE...\n\n"
else
  printf "No known ports file found!\n\nPlease copy the sample file at\n\n\t$DIR/samples/known-ports.txt\n"
  printf "to\n\t$KNOWN_PORTS_FILE\n\nand modify it as necessary.\n\n"
  exit 1
fi

# Output format: <port>:<service>
lsof -i -P | grep LISTEN | awk '{ print $1 " " $9 }' |\
  while IFS=\: read SERVICE PORT; do
    validate_port_service "$PORT" "$SERVICE"
  done |\
    cut -f1,3 -d' ' | uniq | sort -n

printf "\nCheck complete.\n\nPlease review any unexpected open ports and stop\n"
printf "the service or update the list of expected ones.\n\n"

