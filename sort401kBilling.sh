#! /bin/bash
# args 1: mapping file, maps client name in pdf to folder name
#	: each line must be formatted like "CLIENT.PLANTYPE:CLIENTFOLDER:PLANFOLDER"
# args 2: name for final pdf
# args 3: current year

#directory containing client folders
clientsDirectory="/mnt/clients"
#directory of final pdfs to sort
finalDirectory="/mnt/billing_401k/file_copy"

#mapping file
if [ ! -e "${1}" ]; then
	echo "could not find ${1}, exiting..."
	exit 0
fi

echo "loading mapping file..."

declare -a keys

while read line
do
	key=`echo $line | sed -e 's/ /_/g'`
	keys=( ${keys[@]-} $(echo "$key") )
done < $1

echo "discovering files..."

shopt -s nullglob
find "${finalDirectory}"/*.pdf -print0 | while read -d $'\0' f
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

		#make sure billing directory exists
		if [ -d ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing ]; then
			#make sure year directory exists, if not, create it
			if [ ! -d ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/${3} ]; then
				echo "Creating directory ${3} for ${f##*/}"
				mkdir ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/${3}
			fi

			#only move the file if it doesn't exist in destination directory
			if [ ! -e ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/${3}/${2}.pdf ]; then
				echo "Moving ${f##*/} to ${clientDirectory}/${planDirectory}/Billing/${3}"
				mv "$f" ${clientsDirectory}/"${clientDirectory}"/"${planDirectory}"/Billing/${3}/${2}.pdf
			else
				echo "${clientDirectory}/${planDirectory}/Billing/${3}/${2}.pdf already exists!!!"
			fi
		else
			echo "Could not find directory for ${f##*/}"
		fi
	else
		echo "Could not find map for ${f##*/}"
	fi
done

echo "finished moving files"
