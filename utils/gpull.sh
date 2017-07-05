#!/bin/bash
BASESTR=`basename $0`
if [ "$#" -lt 2 ]
then
        echo ""
        echo "Usage :"
        echo ""
        echo "$BASESTR cp <gerrit IDs> [ gerrit IDs ... ]"
        echo "$BASESTR co <gerrit ID> [branchname]"
        echo ""
        echo " cp - Cherry-pick the mentioned gerrit commits"
        echo " co - Checkout    the mentioned gerrit commit"
        echo ""
        echo "Examples:"
        echo ""
        echo "$BASESTR cp 46/1790946/1                             [ cherry-pick single commit ]"
        echo "$BASESTR cp 46/1790946/1 47/1790947/9 55/1790955/7   [ cherry-pick multiple commits ]"
        echo "$BASESTR co 46/1790946/1                             [ checkout commit as headless branch ]"
        echo "$BASESTR co 46/1790946/1 mybranch                    [ checkout commit as a branch ]"
        echo ""
        echo "Where, the gerrit IDs refers to the numeric part in:"
        echo ""
	echo "refs/changes/46/1790946/1  [as mentioned in the cherry-pick command ]"
        echo ""
        exit
fi

# git fetch ssh://review-android.quicinc.com:29418/kernel/msm-3.18 refs/changes/46/1790946/1
URL="ssh://review-android.quicinc.com:29418"
PROJ="kernel/msm-3.18"
REF="refs/changes"

ARGS="$#"
CMD="$1"
shift

if [ ! -d ".git" ]; then
        echo "No git repository found in the current directory"
        exit
fi

if [ "$CMD" == "cp" ]; then
	for var in "$@"
	do
		git fetch $URL/$PROJ $REF/$var
		if [ "$?" != "0" ]; then
			echo "Failed to fetch $var to cherry-pick"
			exit
		fi

		echo "cherry-picking $var"
		git cherry-pick FETCH_HEAD
		if [ "$?" != "0" ]; then
			echo "Failed to cherry-pick $var"
			exit
		fi
	done
elif [ "$CMD" == "co" ]; then
	if [ "$ARGS" == "2" ]; then
		git fetch $URL/$PROJ $REF/$1
		if [ "$?" != "0" ]; then
			echo "Failed to fetch $var to checkout"
			exit
		fi
		git checkout FETCH_HEAD
		if [ "$?" != "0" ]; then
			echo "Failed to checkout $var"
			exit
		fi
	elif [ "$ARGS" == "3" ]; then
		git fetch $URL/$PROJ $REF/$1
		if [ "$?" != "0" ]; then
			echo "Failed to fetch $var"
			exit
		fi
		git checkout FETCH_HEAD -b $2
		if [ "$?" != "0" ]; then
			echo "Failed to checkout $var as $2"
			exit
		fi
	else
		echo "Only one gerrit ID should be mentioned for checkout"
		exit
	fi
else
	echo "Invalid command '$CMD'"
fi

