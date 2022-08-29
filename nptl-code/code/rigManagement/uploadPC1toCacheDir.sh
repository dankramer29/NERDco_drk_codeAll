#!/usr/bin/bash

DATE=$(date +t7.%Y.%m.%d)

#echo $DATE

echo "Enter date to use for upload [$DATE]: "
read DATE2

if [ -z "${DATE2}" ]
then
	DATE2=$DATE
fi

echo "Using $DATE2"
echo ""

TOUPLOAD=`find /cygdrive/e -maxdepth 1 -type d -name Session`

#echo $TOUPLOAD

if [[ -z "$TOUPLOAD" ]]
then
	echo "Couldn't find /cygdrive/e/Session directory..."
fi

echo "Found directory $TOUPLOAD"
echo "   Upload this directory ? [y/n]"
read -s -n1 YESNO

if [ $YESNO == 'y' ]
then
	REMOTE_DIR="nptl@nptl2.stanford.edu:/net/cache/chethan/sessionTest/$DATE2"
	
	echo $REMOTE_DIR
	
	echo "Starting transfer, press any key to continue"
	read -n 1
	COMMAND='rsync -avP --chmod=ugo=rwX  '
	COMMAND="$COMMAND $TOUPLOAD $REMOTE_DIR"
	echo $COMMAND
	$COMMAND
fi