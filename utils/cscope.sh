#!/bin/bash
#
# Script to build a cscope database in the current directory. The script 
# needs to be run without any arguments. It also avoids inclusion of 
# unneccessary file like build files, git, cscope and tags data.
# After building the database, cscope can be launched with the 
# following command:
#
# cscope -d
#
# The option '-d' avoids rebuilding the database.
# For help press '?' in the cscope window
#
# Enjoy cscopping!

dir="."

echo "Finding dependent tools..."
cscope --version 2> /dev/null ; CS="$?"
ctags --version 2> /dev/null ; CT="$?" 

if [ "$CT" != "0" -o "$CS" != 0 ]
then
        echo ""
        echo "One or more packages needed to run this script is not installed. Install the packages as follows:"
        echo ""
        echo "sudo apt-get install exuberant-ctags"
        echo "sudo apt-get install cscope"
        echo ""
        exit 1
fi
echo "done."

echo "Finding relevant source files..."

rm -f cscope.files
touch cscope.files

# find . -path "./build/*" -prune -o -path "./.git*" -prune -o
#        -name "*cscope*" -prune -o -name tags -prune -o -type f -print

echo "Find files..."
find    $dir                            \
        -path "$dir/build/*" -prune -o  \
        -path "$dir/.git*"   -prune -o  \
        -name "*cscope*"     -prune -o  \
        -name "tags"         -prune -o  \
        -type f -print >> cscope.files

echo "Building cscope and ctags database..."
time cscope -q -b -i cscope.files
time ctags -L cscope.files

exit 0

