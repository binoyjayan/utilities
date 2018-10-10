#!/bin/bash
BASESTR=`basename $0`

dpkg-query -s cifs-utils &> /dev/null

if [ "$?" != "0" ]
then
	echo ""
	echo "The package needed to run this script 'cifs-utils' is not installed. Install the package as follows:"
	echo "sudo apt-get install cifs-utils"
	echo ""
	exit 1
fi

if [ "$#" -lt 4 ]
then
        echo ""
        echo "Usage : $BASESTR <network_share> <mount_point> <username> <passwd>"
        echo ""
        echo "network_share is of the format - //servername/shared_directory"
        echo ""
        echo "Examples:"
        echo ""
        echo " $BASESTR //snowcone/builds788 /prj/qct/asw/crmbuilds/snowcone/builds788 ap/c_bjayan mypasswd"
        echo " $BASESTR //snowcone/builds669 /prj/qct/asw/crmbuilds/snowcone/builds669 ap/c_bjayan mypasswd"
        echo ""
        exit 2
fi

SHARE="$1"
MOUNT="$2"
USRNAME="$3"
PASSWD="$4"
PASSWD1="*****"

echo -n "Creating mount directory..."
sudo mkdir -p $MOUNT
echo "done."

echo "Mounting network share..."
echo "sudo mount -t cifs $SHARE $MOUNT --verbose -o username=$USRNAME,password=$PASSWD1,iocharset=utf8,file_mode=0777,dir_mode=0777"

sudo mount -t cifs $SHARE $MOUNT --verbose -o username=$USRNAME,password=$PASSWD,iocharset=utf8,file_mode=0777,dir_mode=0777
if [ "$?" == "0" ]
then
	echo "done"
else
	echo "Error in mounting..."
	exit 1
fi

exit 0

