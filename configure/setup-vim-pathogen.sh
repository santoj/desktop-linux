#!/usr/bin/env bash

#abort on errors
set -eo pipefail

# DIR = the directory of this script, not the current working directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/../common.sh

CONFIG_FILE="$CONFIG_DIR/vim-pathogen-git.txt"
if [ ! -r $CONFIG_FILE ]; then
  echo "Missing $CONFIG_FILE. You can copy and modify the sample file found at $DIR/samples/vim-pathogen-git.txt"
  exit 1
fi

VIM=~/.vim
AUTOLOAD=$VIM/autoload
BUNDLE=$VIM/bundle
mkdir -p $VIM
mkdir -p $AUTOLOAD
mkdir -p $BUNDLE

cd $VIM
[ -d vim-pathogen ] || git clone https://github.com/tpope/vim-pathogen.git
[ -f $AUTOLOAD/pathogen.vim ] || ln -s $VIM/vim-pathogen/autoload/pathogen.vim $AUTOLOAD/pathogen.vim

cd $BUNDLE
while read -r git_url
do
  # ignore comments and blank lines
  [[ "$git_url" =~ ^#.*$ || "$git_url" =~ ^\s*$ ]] && continue
  
  DIR_NAME=$(echo "$git_url" | sed 's/.*\///' | sed 's/\.git//')
  [ -d $DIR_NAME ] && echo "$DIR_NAME already exists" || git clone "$git_url"
done < "$CONFIG_FILE"

