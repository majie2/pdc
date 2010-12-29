#! /bin/bash
# no args
# fixes the 70 rules file automagically to get internet config correctly
# needs to be run as sudo (duh!)

RULES="/etc/udev/rules.d/70-persistent-net.rules"

if [ -z "$1" ]; then
	INTERFACE="eth0"
else
	INTERFACE="$1"
fi

#does blank 70-persistant-net-rules exist?
if [ -e blank/70-persistent-net.rules ] && [ -e $RULES ]; then
	echo "finding module by interface"
	#this will only find the first instance of INTERFACE, so hopefully, it is the right one
	#although, if there are two instances, they should be the same module *crosses fingers*
	interfaceLineNumber=`grep -n ${INTERFACE} ${RULES} | cut -f1 -d:`
	let moduleLineNumber=$interfaceLineNumber-1
	module=`sed -n "${moduleLineNumber}p" $RULES | cut -f2 -d'(' | cut -f1 -d')'`
	echo "copying net rules..."
	cp blank/70-persistant-net.rules /etc/udev/rules.d/
	echo "restarting udev..."
	service udev restart
	echo "modprobe..."
	modprobe -r $module
	modprobe $module
	echo "finished"
fi
