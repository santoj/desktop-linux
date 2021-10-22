#!/usr/bin/env bash

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../common.sh

#FROM: https://www.samba.org/samba/docs/server_security.html

#limit the number of concurrent connections
#   max smbd processes' smb.conf option


#only allow SMB connections from 'localhost' (your own computer) and from the two private networks 192.168.2 and 192.168.3. All other connections will be refused connections as soon as the client sends its first packet
#   hosts allow = 127.0.0.1 192.168.2.0/24 192.168.3.0/24
#   hosts deny  = 0.0.0.0/0


#place a more specific deny on the IPC$ share that is used in the recently discovered security hole. This allows you to offer access to other shares while denying access to IPC$ from potentially untrustworthy hosts.
#this would tell Samba that IPC$ connections are not allowed from anywhere but the two listed places (localhost and a local subnet). Connections to other shares would still be allowed. As the IPC$ share is the only share that is always accessible anonymously this provides some level of protection against attackers that do not know a username/password for your host.
# [ipc$]
#   hosts allow = 192.168.115.0/24 127.0.0.1
#   hosts deny = 0.0.0.0/0

