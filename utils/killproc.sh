#!/bin/bash

declare -a procarr

BASESTR=`basename $0`
usage()
{
	echo ""
	echo "Usage : $BASESTR -u <user1> [ -u user2 ... ] [ -h ]"
	echo ""
	echo "Examples:"
	echo ""
	echo " $BASESTR -h           Displays help message"
	echo " $BASESTR -u user      Kill processes owned by user"
	echo " $BASESTR -u u1 -u u2  Kill processes owned by u1 and u2"
	echo ""
}

kill_user_procs()
{
    cnt=0
    tot=0
    user="$1"
    ps -ef | tail -n+2 | while read line
    do
        tot=`expr $tot + 1`
        if [ ${user:0:1} != "^" ]; then
            user="^$user"
        fi

        str=`echo $line | grep "$user"`
        if [ "$str" == "" ]; then
            continue
        fi
        uname=`echo $str | cut -f1 -d" "`
        pid=`echo $str | cut -f2 -d" "`
        pname=`echo $str | cut -f8 -d" "`
        cnt=`expr $cnt + 1`
        printf 'Killing %-8s [ Owner:%-12s - %4s/%-5s] %s\n' $pid $uname $cnt $tot $pname
        # kill -9 $pid
    done
}

procarr[0]="u0_"
ui=1
killall_user_procs()
{
    BEGINSEC=`date +"%s"`
    for u in "${procarr[@]}"; do
         echo "Killing processes owned by $u"
         kill_user_procs $u
    done
    ENDSEC=`date +"%s"`
    DURATION=`expr $ENDSEC - $BEGINSEC`
    echo ""
    echo "Time taken: $DURATION seconds" 
}

while [ "$1" ]
do
    if [ "$1" = "-u" ]; then
        op="$2"
        id $op  > /dev/null 2> /dev/null
        if [[ "$op" != "" && "$?" == "0" ]] ; then
            procarr[$ui]=$op
            ui=`expr $ui + 1`
        else
            echo "Invalid user $op !"
            exit 1
        fi
        shift 2
    elif [ "$1" == "-h" ]; then
        op="$2"
        if [[ "$op" != "" && "${op:0:1}" != "-" ]]; then
            echo "The option -h does not take any argument!"
            exit 1
        fi
        shift 1
        usage
	exit
    else
        echo "Program $0 does not recognize option $1"
        exit 1
    fi
done

killall_user_procs

