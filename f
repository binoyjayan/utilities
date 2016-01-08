#!/bin/bash

FD=`sudo fastboot devices`
if [ -z "$FD" ]
then
        echo "No fast boot devices detected"
        exit
fi

if [ -n "$1" ]
then
	./getimg $1
	./flash $1
fi



