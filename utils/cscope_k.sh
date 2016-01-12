#!/bin/bash
#
# Script to build a cscope database in the current directory. The script 
# needs to be run without any arguments. It also avoids inclusion of 
# unneccessary files like platform code, architecture dependent code 
# (except arm/arm64),Documentation, etc so as to make the navigation easy.
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

echo "Find files except arch, Doc,..."
find    $dir                                          \
        -path "$dir/arch*"               -prune -o    \
        -path "$dir/tmp*"                -prune -o    \
        -path "$dir/Documentation*"      -prune -o    \
        -path "$dir/scripts*"            -prune -o    \
        -path "$dir/tools*"              -prune -o    \
        -path "$dir/include/config*"     -prune -o    \
        -path "$dir/usr/include*"        -prune -o    \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print                       \
        >> cscope.files

echo "Find arch-arm files excluding platforms..."
find    $dir/arch/arm                                 \
        -path "$dir/arch/arm/mach-*"     -prune -o    \
        -path "$dir/arch/arm/plat-*"     -prune -o    \
        -path "$dir/arch/arm/kvm"        -prune -o    \
        -path "$dir/arch/arm/xen"        -prune -o    \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print -o                    \
        -name "*defconfig" -print                     \
        >> cscope.files

# arm32
if [ -d  "$dir/arch/arm/mach-msm" ]
then
echo "Find mach-msm files..."
find    $dir/arch/arm/mach-msm/                       \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print                       \
        >> cscope.files
else
echo "No mach-msm directory found! Skipping..."
fi

if [ -d  "$dir/arch/arm/mach-qcom" ]
then
echo "Find mach-qcom files..."
find    $dir/arch/arm/mach-qcom/                      \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print                       \
        >> cscope.files
else
echo "No mach-qcom directory found! Skipping..."
fi

#arm64
if [ -d  "$dir/arch/arm64/mach-msm" ]
then
echo "Find arm64/mach-msm files..."
find    $dir/arch/arm64/mach-msm/                     \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print                       \
        >> cscope.files
else
echo "No arm64/mach-msm directory found! Skipping..."
fi

if [ -d  "$dir/arch/arm64/mach-qcom" ]
then
echo "Find mach-qcom files..."
find    $dir/arch/arm64/mach-qcom/                    \
        -type f                                       \
        -not -name '*.mod.c'                          \
        -name "*.[chsS]" -print -o                    \
        -name "Kconfig"  -print                       \
        >> cscope.files
else
echo "No arm64/mach-qcom directory found! Skipping..."
fi

echo "Building cscope and ctags database..."
time cscope -q -k -b -i cscope.files
time ctags -L cscope.files

exit 0

