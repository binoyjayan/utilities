#!/bin/bash

pid="$1" # first arguvment is the PID
cwd="$2" # second argument is the target working directory

# now let's command the GNU debugger
gdb -q <<EOF
  attach $pid
  call (int) chdir("$cwd")
  detach
  quit
EOF
