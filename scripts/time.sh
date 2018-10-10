#!/bin/bash

BEGSEC=`date +"%s"`

$@

ENDSEC=`date +"%s"`
S=`expr $ENDSEC - $BEGSEC`

H=`expr $S / 3600`
S=`expr $S % 3600`

M=`expr $S / 60`
S=`expr $S % 60`

echo ""
echo -n "Elapsed time: "
if [ "$H" != "0" ]; then
	echo -n "$H hr(s) "
fi
if [ "$M" != "0" ]; then
	echo -n "$M min(s) "
fi
echo "$S sec(s)"
echo ""

