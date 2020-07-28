#!/bin/bash

if [ "$1" == "" ]; then
    echo "Directory expected"
    exit
fi

DIR="$1"
/usr/bin/ctags -e -R $DIR
ctags-exuberant -R $DIR
