#!/bin/bash
BASESTR=`basename $0`

usage()
{
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
}


if [ "$#" -lt 2 ]
then
	usage
fi

URL="ssh://review-android.quicinc.com:29418/kernel/msm-3.18"
REF="refs/changes"
CMD="cp"
URLFLAG="f"
BRANCH="newbranch"
BRANCHFLAG="f"

while getopts "u:b:h" opt; do
  found=1
  case $opt in
    u)
        URL=$OPTARG
	URLFLAG="t"
        ;;
    b)
        BRANCH=$OPTARG
	BRANCHFLAG="t"
        ;;
    h)
	usage
        ;;
    \?)
        echo ""
        echo "Invalid/insufficient arguments mentioned!"
        usage
        ;;
  esac
done

if [ "$URLFLAG" == 't' ]; then
	shift 2
fi

if [ "$BRANCHFLAG" == 't' ]; then
	shift 2
fi

# Process remaining parameters '<cmd>' '<commit(s)>'
ARGS="$#"
CMD="$1"
shift

convert_id()
{
	RESULT=`echo $1 | awk '{split($0,a,"/"); print substr( a[1], length(a[1]) - 1, length(a[1]) ) "/" a[1] "/" a[2] }'`
}

cp_commits()
{
	for var in "$1"
	do
		convert_id $var
		echo git fetch $URL $REF/$RESULT
		git fetch $URL $REF/$RESULT
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
}

co_commit()
{
	convert_id $COMMIT
	echo git fetch $URL $REF/$RESULT
	git fetch $URL $REF/$RESULT
	if [ "$?" != "0" ]; then
		echo "Failed to fetch $var to checkout"
		exit
	fi

	if [ "$ARGS" == "2" ]; then
		git checkout FETCH_HEAD
		if [ "$?" != "0" ]; then
			echo "Failed to checkout $var"
			exit
		fi
	elif [ "$ARGS" == "3" ]; then
		git checkout FETCH_HEAD -b $BRANCH
		if [ "$?" != "0" ]; then
			echo "Failed to checkout $var as $BRANCH"
			exit
		fi
	else
		echo "Only one gerrit ID should be mentioned for checkout"
		exit
	fi
}

if [ ! -d ".git" ]; then
        echo "No git repository found in the current directory"
        exit
fi

if [ "$CMD" == "cp" ]; then
	cp_commits $@
elif [ "$CMD" == "co" ]; then
	COMMIT=$1
	BRANCH=$2
	co_commit
else
	echo "Invalid command '$CMD'"
fi

