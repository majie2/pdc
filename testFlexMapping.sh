#! /bin/bash
# args 1: directory of clients
# args 2: mapping file

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
	key=`echo $line`
	keys=( ${keys[@]-} $(echo "$key") )
done < $2

for i in ${keys[@]}
do
	clientDirectory=`echo $i | cut -f2 -d:`
	planDirectory=`echo $i | cut -f3 -d:`

	if [ ! -e "${1}"/"${clientDirectory}"/"${planDirectory}"/Billing/ ]; then
		echo "FAIL: ${clientDirectory}/${planDirectory}/Billing/"
	fi
done

echo "finished"
