#!/bin/bash

THIS="$0"
TTY=`tty`
echo "TERMINAL:$TTY"

# Run this script without a tty
if [ "$1" == '-notty' ];then
	echo "Running without a terminal.."
	true | (setsid $THIS) 2>&1 | cat
	# Another way
	# (setsid $THIS) </dev/null |& cat
fi

