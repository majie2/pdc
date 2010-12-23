#! /bin/bash
# args 1: directory of files to sort (pdfs, must have date in filename and client name in pdf)
# args 2: mapping file, maps client name in pdf to folder name
#	: each line must be formatted like "CLIENT NAME:FOLDER NAME"
# args 3: directory name file will be placed inside client folder, will be made if it doesn't exist

# OH, AND BY THE WAY, only moves pdfs... unless you change the *.pdf

#directory of containing client folders
#since this is likely run from a virtual machine, mount your fileshare to some folder and specify here
clientDirectory="/home/josef/Documents/clients"

#directory of files to sort
if [ ! -d "${1}" ]; then
	echo "Could not find ${1}"
	exit 0
fi

#mapping file
if [ ! -e "${2}" ]; then
	echo "Could not find ${2}"
	exit 0
fi

echo "Loading mapping file..."

declare -a keys

while read line
do
	key=`echo $line | sed -e 's/ /_/g'`
	keys=( ${keys[@]-} $(echo "$key") )
done < $2

echo "Discovering pdfs..."

shopt -s nullglob
find "${1}"/*.pdf -print0 | while read -d $'\0' f
do
	#convert pdf to text file
	pdftotext -f 1 -l 1 "$f" "${1}"/temp.txt

	clientMap=""
	key=""
	location=""

	for i in ${keys[@]}
	do
		key=`echo $i | sed -e 's/_/ /g' | cut -f1 -d:`
		location=`grep "$key" "${1}"/temp.txt`

		if [ -n "$location" ]; then
			echo "${f##*/} -> $key"
			clientMap=`echo "$i" | sed -e 's/_/ /g'`
			break
		fi
	done

	#make sure clientName is not empty
	if [ -n "$clientMap" ]; then
		#find directory name from mapping file
		directoryName=`echo $clientMap | cut -f2 -d:`

		#make sure directory exists in client folder
		if [ -e ${clientDirectory}/"${directoryName}"/"${3}"/ ]; then
			echo "Copying ${f##*/} to ${directoryName}"
			cp "$f" "${finalDirectory}"${f##*/}
		fi
	fi
done

echo "Cleaning up... done"
rm "${1}"/temp.txt

echo "Finished moving pdfs"
