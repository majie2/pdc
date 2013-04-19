#! /bin/bash
# author:	Jamie Morrow
# date:		April 15 2013
# license:	MIT
#
# description: 
# sorts and moves wystar certified trust reports

clear

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

#directory of containing client folders
clientDirectory="/mnt/pd"
#clientDirectory="/mnt/g"

#mapping file
map="${clientDirectory}/Admin/trustreportmapping.txt"
#map="G:401Files/admin/trustreportmapping.txt"

REPORTS="${clientDirectory}/Admin/Wells Fargo - Trust Accounting"
#/mnt/pd=G:\401Files

read -p "Year (i.e. 2012): "
targetYear=$(echo $REPLY)

#test if reports directory exists
if [ ! -d "${REPORTS}" ]; then
	echo "Directory does not exist: ${REPORTS}"
fi

#mapping file
if [ ! -e $map ]; then
	echo "Could not find ${map}"
	exit 0
fi

./${THIS_PATH}/../testmap.sh $clientDirectory $map

echo "Discovering pdfs..."

shopt -s nullglob
find "${REPORTS}"/*.pdf -print0 | while read -d $'\0' f
do
	key=$(echo $f | cut -f2 -d'_')
	targetDirectory=$(grep $key $map | cut -f2 -d':' | tr -d '\n' | tr -d '\r')
	targetPlan=$(grep $key $map | cut -f3 -d':' | tr -d '\n' | tr -d '\r')
	
	if [ -z "${targetDirectory}" ]; then
		echo "###Map not found ${f}"
	else
		if [ -z "${targetPlan}" ]; then
			targetPath="${clientDirectory}/${targetDirectory}/Valuations/${targetYear}"
		else
			targetPath="${clientDirectory}/${targetDirectory}/${targetPlan}/Valuations/${targetYear}"
		fi
		
		if [ -d "${targetPath}" ]; then
			if [ -e "${targetPath}/Wells Fargo Certified Trust Report.pdf" ]; then
				echo "###File exists in ${targetPath}"
			else
				echo "moving ${f##*/} to ${targetPath}/Wells Fargo Certified Trust Report.pdf"
				mv "${f}" "${targetPath}/Wells Fargo Certified Trust Report.pdf"
			fi
		fi
	fi
done
