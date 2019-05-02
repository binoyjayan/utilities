#!/bin/bash
HELPFLAG=false
SETIPFLAG=false
BASESTR=`basename $0`
sshpass -V 2>&1 > /dev/null ; CODE="$?"

# IP addresses of hosts to configure traffic ips ffor
declare -a hostips=(
"143.182.95.50"
"143.182.94.102"
"143.182.95.51"
"143.182.94.108"
"143.182.94.105"
)

# Traffic IPs to set
declare -a trafficips=(
"192.168.0.201"
"192.168.0.202"
"192.168.0.204"
"192.168.0.220"
"192.168.0.203"
)

# Traffic interface to set ip for
declare -a interfaces=(
"eth3"
"eth3"
"eth2"
"eth2"
"eth2"
)

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

declare -a verifyhostips=(
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
declare -a verifyinterfaces=(
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

usage()
{
      echo ""
      echo "Usage: $BASESTR <option> [parameter]..."
      echo ""
      echo "Options"
      echo ""
      echo "-s              : Set IP address"
      echo "-p <password>   : use password"
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
	echo "List ip addresses..."
	echo ""
	CNT_OK=0
	CNT_ERR=0
	arraylength=${#hostnames[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		NAME=${hostnames[$i]}
		HOST=${verifyhostips[$i]}
		INTF=${verifyinterfaces[$i]}
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} ifconfig ${INTF} | grep 'inet addr'"
		# echo "$CMD"
		OUT=""
		OUT=`$CMD`
		echo -e "$NAME \t : $OUT"
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

# To run a command as follows:
# sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@143.182.95.50 "echo ${PASSWD} | sudo -S ifconfig eth0"
set_ip_address()
{
	PIPE="|"
	echo "Setting ip addresses..."
	echo ""
	CNT_OK=0
	CNT_ERR=0
	arraylength=${#hostips[@]}
	for (( i=0; i<${arraylength}; i++ ))
	do
		HOST=${hostips[$i]}
		TRAF=${trafficips[$i]}
		INTF=${interfaces[$i]}
		echo "Setting ip for host $HOST, IP:$TRAF, intf $INTF"
		CMD="sshpass -p ${PASSWD} ssh -oStrictHostKeyChecking=no user@${HOST} echo ${PASSWD} $PIPE sudo -p '' -S ifconfig ${INTF} ${TRAF} netmask 255.255.255.0"
		# echo "$CMD"
		`$CMD`
		EXT="$?"
		if [ "$EXT" == "0" ]; then
			CNT_OK=`expr $CNT_OK + 1`
		else
			CNT_ERR=`expr $CNT_ERR + 1`
		fi
		sleep 1
	done
	echo ""
	echo "#IP Addresses [ Total      ] : $arraylength"
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
while getopts "p:sh" opt; do
  found=1
  case $opt in
    p)
        PASSWD=$OPTARG
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

if [ "$PASSWD" == "" ]; then
	echo "Please specify password using -p; -h for usage"
	echo ""
	exit
fi

if [ "$HELPFLAG" == "true" ]; then
	usage
	exit
fi

if [ "$SETIPFLAG" == "true" ]; then
	set_ip_address
fi

get_ip_address



