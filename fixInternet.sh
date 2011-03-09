#! /bin/bash
# author:	Josef Kelly
# date:		March 11 2011
# license:	MIT
#
# description:
# Fixes the 70-persistant-net-rules file automagically to configure the internet correctly
# This is typically needed when running a vm on different machines
# 
# args 1: network interface (optional, will assume eth0 if not specified)
#
# RUN SUDO

PREFIX="fixInternet:"
THIS_PATH="`dirname \"$0\"`"
OLDRULES="/etc/udev/rules.d/70-persistent-net.rules"
NEWRULES="${THIS_PATH}/blank/70-persistent-net.rules"

if [ -z "$1" ]; then
	INTERFACE="eth0"
else
	INTERFACE="$1"
fi

#does blank 70-persistant-net-rules exist?
if [ -e $NEWRULES ] && [ -e $OLDRULES ]; then
	echo -n -e "\r${PREFIX} finding module by interface ${INTERFACE}..."
	#this will only find the first instance of INTERFACE, so hopefully, it is the right one
	#although, if there are two instances, they should be the same module *crosses fingers*
	interfaceLineNumber=`grep -n ${INTERFACE} ${OLDRULES} | cut -f1 -d:`
	let moduleLineNumber=$interfaceLineNumber-1
	module=`sed -n "${moduleLineNumber}p" $OLDRULES | cut -f2 -d'(' | cut -f1 -d')'`
	echo -n -e "\r${PREFIX} copying net rules..."
	sudo cp $NEWRULES /etc/udev/rules.d/
	echo -n -e "\r${PREFIX} restarting udev..."
	sudo service udev restart
	echo -n -e "\r${PREFIX} modprobe..."
	sudo modprobe -r $module
	sudo modprobe $module
	echo -n -e "\r${PREFIX} finished"
else
	echo "\r${PREFIX} could not find either rules file, exiting..."
fi
