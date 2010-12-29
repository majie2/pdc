#! /bin/bash
# args 1: directory of files to sort (pdfs, CLIENT.PLANTYPE.pdf)
# args 2: mapping file, maps client name in pdf to folder name
#	: each line must be formatted like "CLIENT.PLANTYPE:CLIENTFOLDER:PLANFOLDER"
# args 3: name for final pdf

#directory of containing client folders
#since this is likely run from a virtual machine, mount your fileshare to some folder and specify here
clientsDirectory="/home/josef/Documents/clients"

#directory of files to sort
if [ ! -d "${1}" ]; then
	echo "could not find ${1}, exiting"
	exit 0
fi

#mapping file
if [ ! -e "${2}" ]; then
	echo "could not find ${2}, exiting..."
	exit 0
fi

echo "loading mapping file..."

declare -a keys

while read line
do
	key=`echo $line | sed -e 's/ /_/g'`
	keys=( ${keys[@]-} $(echo "$key") )
done < $2

echo "discovering files..."

shopt -s nullglob
find "${1}"/*.pdf -print0 | while read -d $'\0' f
do
	clientName=`echo ${f##*/} | cut -f1-2 -d.`
	clientMap=""
	key=""

	for i in ${keys[@]}
	do
		key=`echo $i | sed -e 's/_/ /g' | cut -f1 -d:`

		if [ $key = $clientName ]; then
			clientMap=`echo "$i" | sed -e 's/_/ /g'`
			break
		fi
	done

	#make sure clientName is not empty
	if [ -n "$clientMap" ]; then
		#find directory name from mapping file
		clientDirectory=`echo $clientMap | cut -f2 -d:`
		planDirectory=`echo $clientMap | cut -f3 -d:`

		#make sure directory exists in client folder
		if [ -e ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/ ]; then
			echo "Copying ${f##*/} to ${clientDirectory}/${planDirectory}/Billing"
			cp "$f" ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/${3}.pdf
		fi
	fi
done

echo "finished moving files"
