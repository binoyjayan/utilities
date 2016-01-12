#!/bin/bash
# Switch between linaro and codeaurora accounts
BASESTR=`basename $0`

GCONFIG="`readlink -m ~/.gitconfig`"

export EL="binoy.jayan@linaro.org"
export EC="bjayan@codeaurora.org"

export SL="The Qualcomm Innovation Center, Inc. is a member of the Code Aurora Forum,\\\na Linux Foundation Collaborative Project"
export SC="The QUALCOMM INDIA, on behalf of Qualcomm Innovation Center, Inc. is a member\\\nof Code Aurora Forum, hosted by The Linux Foundation"


if [ "$#" -lt 1 ]
then
        echo ""
        echo "Usage : $BASESTR -l    <<-- Switch to linaro email settings in $GCONFIG"
        echo "Usage : $BASESTR -c    <<-- Switch to codeaurora email settings in $GCONFIG"
        echo ""
 
fi

if [ "$1" == "-c" ]
then
	echo "Changing to codeaurora settings..."
	sed -i "s/^#[ \t]*email = $EC/\temail = $EC/g" $GCONFIG
	sed -i "s/^[ \t]*email = $EL/#\temail = $EL/g" $GCONFIG

	sed -i "s/^#[ \t]*signature = $SC/\tsignature = $SC/g" $GCONFIG
	sed -i "s/^[ \t]*signature = $SL/#\tsignature = $SL/g" $GCONFIG
else
	echo "Changing to linaro settings..."
	sed -i "s/^#[ \t]*email = $EL/\temail = $EL/g" $GCONFIG
	sed -i "s/^[ \t]*email = $EC/#\temail = $EC/g" $GCONFIG

	sed -i "s/^#[ \t]*signature = $SL/\tsignature = $SL/g" $GCONFIG
	sed -i "s/^[ \t]*signature = $SC/#\tsignature = $SC/g" $GCONFIG

fi



