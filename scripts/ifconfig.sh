#!/bin/bash
HELPFLAG=false
SETIPFLAG=false
GETIPFLAG=false
GETHOSTNAMEFLAG=false
PINGFLAG=false
REBOOTFLAG=false
PIPE="|"
BASESTR=`basename $0`
sshpass -V 2>&1 > /dev/null ; CODE="$?"

# Hosts for verification
declare -a hostnames=(
"PO_LAN1"
"PO_LAN2"
"PO_LAN4"
"PO_LAN5"
"PO_NRGMI2"
"PO_NRGMI3"
"PO_NSI1"
"PO_NSI2"
"PO_NSI3"
"PO_NSI4"
"PO_NSI5"
"PO_WIFI1"
"PO_WIFI2"
"PO_WIFI1.2"
"PO_WIFI2.2"
)

declare -a hostips=(
"143.182.95.50"
"143.182.94.102"
"143.182.95.51"
"143.182.94.108"
"143.182.94.105"
"143.182.94.108"
"143.182.95.74"
"143.182.95.52"
"143.182.95.72"
"143.182.95.72"
"143.182.95.52"
"143.182.94.164"
"143.182.94.165"
"143.182.94.164"
"143.182.94.165"
)

declare -a interfaces=(
"eth3"
"eth3"
"eth2"
"eth2"
"eth2"
"eth2"
"eth4"
"eth2"
"eth2"
"eth2"
"eth2"
"eth5"
"eth5"
"eth5"
"eth5"
)

declare -a trafficips=(
"192.168.0.201"
"192.168.0.202"
"192.168.0.204"
"192.168.0.220"
"192.168.0.203"
"192.168.0.220"
"172.20.47.214"
"172.20.47.213"
"172.20.47.223"
"172.20.47.223"
"172.20.47.213"
"192.168.0.88"
"192.168.0.11"
"192.168.0.88"
"192.168.0.11"
)

declare -a isduplicate=(
"no"
"no"
"no"
"no"
"no"
"yes"
"no"
"no"
"no"
"yes"
"no"
"no"
"no"
"yes"
"yes"
)

# flag to indicate if a CPE is LAN
declare -a islancpe=(
"yes"
"yes"
"yes"
"yes"
"yes"
"yes"
"no"
"no"
"no"
"no"
"no"
"no"
"no"
"no"
"no"
)

# flag to indicate if a CPE is NSI
declare -a isnsicpe=(
"no"
"no"
"no"
"no"
"no"
"no"
"yes"
"yes"
"yes"
"yes"
"yes"
"no"
"no"
"no"
"no"
)

usage()
{
      echo "Usage: $BASESTR <option> [parameter]..."
      echo ""
      echo "Options"
      echo ""
      echo "-s              : Set IP address"
      echo "-p <password>   : use password"
      echo "-i              : Display IP addresses of all CPEs"
      echo "-o              : Display hostnames of all CPEs"
      echo "-g              : Ping all hosts via traffic interface"
      echo "-r              : Reboot all hosts"
      echo "-h              : Display usage"
      echo ""
      echo "EXamples:"
      echo ""
      echo "$BASESTR"
      echo "$BASESTR -p mypass -s"
      echo "$BASESTR -p mypass"
      echo ""

}

# To run a command as follows:
# sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@143.182.95.50 "ifconfig eth3 | grep 'inet addr'"`
get_ip_address()
{
	echo "Listing ip addresses..."
	echo ""
	CNT_OK=0
	CNT_ERR=0
	arraylength=${#hostnames[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${hostips[$i]}
		INTF=${interfaces[$i]}
		# Get hostname
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} ifconfig ${INTF} | grep 'inet addr'"
		# echo "$CMD"
		OUT=""
		OUT=`$CMD`
                echo -e "$NAME: [$HOST] \t\t : $OUT"
		if [ "$OUT" == "" ]; then
			CNT_ERR=`expr $CNT_ERR + 1`
		else
			CNT_OK=`expr $CNT_OK + 1`
		fi
	done
	echo ""
	echo "#IP Addresses [ Total                ] : $arraylength"
	echo "#IP Addresses [ Retrieved            ] : $CNT_OK"
	echo "#IP Addresses [ Failed to retrieve   ] : $CNT_ERR"
	echo ""

}

get_host_names()
{
	echo "Listing hostnames..."
	echo ""
	CNT_OK=0
	CNT_ERR=0
	arraylength=${#hostnames[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${hostips[$i]}
		INTF=${interfaces[$i]}
		# Get hostname
		HNAME=""
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} hostname"
		HNAME=`$CMD`
                echo -e "$NAME: $HNAME [$HOST]"
	done
}


# To reboot all hosts
reboot_all()
{
	echo "Rebooting CPEs..."
	echo ""
	CHOST=`ip route get 1 | awk '{print $NF;exit}'`
	arraylength=${#hostnames[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${hostips[$i]}
		DUP=${isduplicate[$i]}
		if [[ "$DUP" == "yes" ]]; then
			# echo "Skipping dupicate ${NAME} [ ${HOST} ]..."
			continue
		fi
		if [[ "$HOST" == "$CHOST" ]]; then
			# echo "Skipping current host ${NAME} [ ${HOST} ]..."
			continue
		fi
		echo "Rebooting ${NAME} [ ${HOST} ]..."
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} echo ${PASSWD} $PIPE sudo -p '' -S reboot"
		# echo "$CMD"
		OUT=`$CMD`
	done
}

# To ping all CPEs from every other CPE
ping_ip_address()
{
	echo "Perform Ping test..."
	CNT_OK=0
	CNT_ERR=0
	hostarrlen=${#hostips[@]}
	trafarrlen=${#trafficips[@]}
	for (( i=0; i<${hostarrlen}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${hostips[$i]}
		NSI=${isnsicpe[$i]}
		DUP=${isduplicate[$i]}
		# do not ping from nsi
		if [[ "$NSI" == "yes" || "$DUP" == "yes" ]]; then
			# echo "Skip NSI CPE [${HOST}] ..."
			continue
		fi
		echo ""
		echo "Pinging CPEs from host $NAME [${HOST}] ..."
		for (( j=0; j<${trafarrlen}; j++ ))
		do
			TRAF=${trafficips[$j]}
			NSI=${isnsicpe[$j]}
			DUP=${isduplicate[$j]}
			# do not ping nsi
			if [[ "$NSI" == "no" && "$DUP" == "no" ]]; then
				CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} ping -c 5 ${TRAF} | grep 'packet loss'"
				# echo "$CMD"
				OUT=""
				OUT=`$CMD`
				echo -e "$TRAF \t : $OUT"
				if [[ "$OUT" =~ "0% packet loss" ]]; then
					CNT_OK=`expr $CNT_OK + 1`
				else
					CNT_ERR=`expr $CNT_ERR + 1`
				fi
			fi
		done
	done
	echo ""
	echo "#ping succeeded : $CNT_OK"
	echo "#ping failed    : $CNT_ERR"
	echo ""

}

# To run a command as follows:
# sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@143.182.95.50 "echo ${PASSWD} | sudo -S ifconfig eth0"
set_ip_address()
{
	echo "Setting ip addresses..."
	echo ""
	CNT_OK=0
	CNT_ERR=0
	CNT_TOT=0
	arraylength=${#hostnames[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${hostips[$i]}
		TRAF=${trafficips[$i]}
		INTF=${interfaces[$i]}
		LAN=${islancpe[$i]}
		DUP=${isduplicate[$i]}
		if [[ "$LAN" == "no" ]]; then
			# echo "Skip Non-LAN CPE $NAME [${HOST}] ..."
			continue
		fi
		if [[ "$DUP" == "yes" ]]; then
			# echo "Skipping dupicate ${NAME} [ ${HOST} ]..."
			continue
		fi
		echo "Setting ip for $NAME [ $HOST, IP:$TRAF, intf $INTF ]"
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} echo ${PASSWD} $PIPE sudo -p '' -S ifconfig ${INTF} ${TRAF} netmask 255.255.255.0"
		# echo "$CMD"
		`$CMD`
		EXT="$?"
		if [ "$EXT" == "0" ]; then
			CNT_OK=`expr $CNT_OK + 1`
		else
			CNT_ERR=`expr $CNT_ERR + 1`
		fi
		CNT_TOT=`expr $CNT_TOT + 1`
		sleep 1
	done
	echo ""
	echo "#IP Addresses [ Total      ] : $CNT_TOT"
	echo "#IP Addresses [ Set        ] : $CNT_OK"
	echo "#IP Addresses [ Failed set ] : $CNT_ERR"
	echo ""
}


if [ "$CODE" != "0" ]
then
        echo ""
        echo "sshpass is not installed; Install it using"
        echo ""
        echo "sudo apt-get install sshpass"
        echo ""
        exit 1
fi


# Main script execution
echo ""
found=0
while getopts "p:iogrsh" opt; do
  found=1
  case $opt in
    p)
        PASSWD=$OPTARG
        ;;
    i)
        GETIPFLAG=true
        ;;
    o)
        GETHOSTNAMEFLAG=true
        ;;
    g)
        PINGFLAG=true
        ;;
    r)
        REBOOTFLAG=true
        ;;
    s)
        SETIPFLAG=true
        ;;
    h)
	HELPFLAG=true
        ;;
    \?)
        echo ""
        echo "Invalid/insufficient arguments mentioned!"
        usage
        ;;
  esac
done

if [ "$HELPFLAG" == "true" ]; then
	usage
	exit
fi

if [ "$PASSWD" == "" ]; then
	echo "Please specify password using -p; -h for usage"
	echo ""
	exit
fi

if [ "$SETIPFLAG" == "true" ]; then
	set_ip_address
fi

if [ "$GETIPFLAG" == "true" ]; then
	get_ip_address
fi

if [ "$GETHOSTNAMEFLAG" == "true" ]; then
	get_host_names
fi

if [ "$PINGFLAG" == "true" ]; then
	ping_ip_address
fi

if [ "$REBOOTFLAG" == "true" ]; then
	reboot_all
fi

