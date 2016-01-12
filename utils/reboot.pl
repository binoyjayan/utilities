#!/usr/bin/perl

#use POSIX qw/strftime/;
#use warnings;
#use strict;

$cnt=1;

while($cnt <= 1000)
{
	$t = localtime;
	print ("$t  : Iteration " , $cnt, "\n");
	system("adb wait-for-device root");
	system("adb wait-for-device remount");
	sleep(5);
	system("adb wait-for-device reboot");
	$cnt++;
}

print ("Reboot successful for " , $cnt, " tries\n");

