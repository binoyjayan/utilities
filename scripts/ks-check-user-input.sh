#!/bin/bash

TERMINAL=`tty`
# Change TIMEOUT to allow users for more time for users to respond
TIMEOUT=2
EXIT_CODE=0
stty -F $TERMINAL -icanon min 0

i=0
echo "Press 'aa' to abort installation" > $TERMINAL
while [ $i -lt $TIMEOUT ]; do
    read INPUT < $TERMINAL
    if [[ $INPUT = aa* || $INPUT = AA* ]]; then
        EXIT_CODE=1
        break
    fi
    ((i++))
    sleep 1
done

echo
stty -F $TERMINAL sane
exit $EXIT_CODE


