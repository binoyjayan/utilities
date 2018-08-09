#!/bin/bash

CUR=`readlink -m .`
CUR=`basename $CUR`
EXE=`readlink -m $0`
TST=`dirname $EXE`
LOG="/tmp/s3cmd.log"
TMP="/tmp/s3cmd_out"

echo ""
echo "Current dir : $CUR"
echo "Test dir    : $TST"
echo "Temp dir    : $TMP"
echo ""

if [ "$CUR" != "build" ]; then
  echo "Execute the script from the build directory"
  exit 1
fi

echo "s3cmd tests" > $LOG
mkdir -p $TMP

echo "Running tests..."
echo ""

s3cmd info s3://BUCKET1 2> /dev/null
if [ "$?" != "0" ]; then
  echo "Error getting bucket info for BUCKET1"
  echo "Ensure that the s3 server is running"
  echo ""
  exit 1
fi

s3cmd -d mb s3://BUCKET1 2>> $LOG
s3cmd -d rb s3://BUCKET1 2>> $LOG
s3cmd -d la 2>> $LOG

rm -f msg.txt
s3cmd -d get s3://BUCKET1/msg.txt 2>> $LOG && cat msg.txt

cp $TST/msg.txt $TMP
rm -f msg.txt
s3cmd -d put $TMP/msg.txt s3://BUCKET1 2>> $LOG && cat msg.txt


dd if=/dev/zero of=$TMP/big.bin bs=1M count=16
s3cmd -d put $TMP/big.bin s3://BUCKET1 2>> $LOG
ls -l big.bin

s3cmd -d rm  s3://BUCKET1/msg.txt 2>> $LOG
s3cmd -d del s3://BUCKET1/msg.txt 2>> $LOG

s3cmd -d cp s3://BUCKET1/msg.txt s3://BUCKET2/msg2.txt 2>> $LOG
s3cmd -d mv s3://BUCKET1/msg.txt s3://BUCKET2/msg2.txt 2>> $LOG

s3cmd -d du s3://BUCKET1 2>> $LOG
s3cmd -d setacl s3://BUCKET1/msg.txt 2>> $LOG
s3cmd -d setpolicy $TST/policyfile s3://BUCKET1 2>> $LOG
s3cmd -d delpolicy s3://BUCKET1 2>> $LOG
s3cmd -d accesslog s3://BUCKET1 2>> $LOG

s3cmd -d setcors $TST/cors_rules.txt s3://BUCKET1 2>> $LOG
s3cmd -d info s3://BUCKET1 2>> $LOG
s3cmd -d delcors s3://BUCKET1 2>> $LOG
s3cmd -d payer s3://BUCKET1 2>> $LOG
s3cmd -d expire s3://BUCKET1 2>> $LOG
s3cmd -d setlifecycle $TST/lifecycle s3://BUCKET1 2>> $LOG
s3cmd -d sign "STRING-TO-SIGN" 2>> $LOG
s3cmd -d signurl s3://BUCKET1/msg1.txt +10 2>> $LOG
s3cmd -d listmp s3://BUCKET/msg1.txt 1234 2>> $LOG
s3cmd -d multipart s3://BUCKET1 2>> $LOG


echo ""
echo "Debug output written to $LOG"
echo ""



