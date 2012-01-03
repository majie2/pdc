#! /bin/bash
# author:	Josef Kelly
# date:		January 1, 2012
# license:	MIT
#
# description:
# Fixes the 70-persistant-net-rules file automagically to configure the internet correctly
# This is typically needed when running a vm on different machines
# 
# args 1: network interface (optional, will assume eth0 if not specified)
#
# RUN SUDO
#
# WARNING: This could really mess up your interfaces if you don't know what you're doing
#        : because it REMOVES COMPLETELY the rules file. You are warned.

THIS_PATH="`dirname \"$0\"`"
OLDRULES="/etc/udev/rules.d/70-persistent-net.rules"

if [ -z "$1" ]; then
	INTERFACE="eth0"
else
	INTERFACE="$1"
fi

if [ -e $OLDRULES ]; then
	echo "finding module by interface: ${INTERFACE}..."
	
	#this will only find the first instance of INTERFACE, so hopefully, it is the right one
	#although, if there are two instances, they should be the same module *crosses fingers*
	interfaceLineNumber=`grep -n ${INTERFACE} ${OLDRULES} | cut -f1 -d:`
	
	#module line is above the interface line lulz
	let moduleLineNumber=$interfaceLineNumber-1
	
	#MODULE!!! probably e1000 per usual
	module=`sed -n "${moduleLineNumber}p" $OLDRULES | cut -f2 -d'(' | cut -f1 -d')'`
	
	echo "removing old net rules..."
	sudo rm ${OLDRULES}
	sudo touch ${OLDRULES}
	
	echo "restarting udev..."
	sudo service udev restart
	
	echo "modprobe..."
	sudo modprobe -r $module
	sudo modprobe $module
	
	echo "finished"
else
	echo "could not find either rules file, exiting..."
fi
