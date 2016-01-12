#!/bin/bash

BASESTR=`basename $0`

if [ "$#" -lt 2 ]
then
        echo ""
        echo "Usage : $BASESTR <username> <passwd>"
        echo ""
        echo "Example:"
        echo ""
        echo "$BASESTR ap/c_bjayan mypasswd"
        echo ""
        exit 1
fi

USRNAME="$1"
PASSWD="$2"

echo "Mounting shares..."

mnt_smb.sh //snowcone/builds788 /prj/qct/asw/crmbuilds/snowcone/builds788 $USRNAME $PASSWD
if [ "$?" != "0" ]
then
	echo ""
	echo "Failed to mount shares..."
	echo ""
	exit 2
fi

mnt_smb.sh //snowcone/builds669 /prj/qct/asw/crmbuilds/snowcone/builds669 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds699 /prj/qct/asw/crmbuilds/snowcone/builds699 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds774 /prj/qct/asw/crmbuilds/snowcone/builds774 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds775 /prj/qct/asw/crmbuilds/snowcone/builds775 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds752 /prj/qct/asw/crmbuilds/snowcone/builds752 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds687 /prj/qct/asw/crmbuilds/snowcone/builds687 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds731 /prj/qct/asw/crmbuilds/snowcone/builds731 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds792 /prj/qct/asw/crmbuilds/snowcone/builds792 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds694 /prj/qct/asw/crmbuilds/snowcone/builds694 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds745 /prj/qct/asw/crmbuilds/snowcone/builds745 $USRNAME $PASSWD
mnt_smb.sh //snowcone/builds781 /prj/qct/asw/crmbuilds/snowcone/builds781 $USRNAME $PASSWD


mnt_smb.sh //bigelow/zipbuild256 /prj/qct/asw/crmbuilds/bigelow/zipbuild256 $USRNAME $PASSWD
mnt_smb.sh //bigelow/zipbuild252 /prj/qct/asw/crmbuilds/bigelow/zipbuild252 $USRNAME $PASSWD
mnt_smb.sh //bigelow/zipbuild257 /prj/qct/asw/crmbuilds/bigelow/zipbuild257 $USRNAME $PASSWD

echo "done"



