#! /bin/bash
# author:	Josef Kelly
# date:		March 9 2011
# license:	MIT
#
# description:
# sorts schwab statements
#
# args 1: directory of files to sort (pdfs, must have date in filename and client name in pdf)

# location where this script is being executed
THIS_PATH="`dirname \"$0\"`"

#directory of containing client folders
clientDirectory="/mnt/pd"

#mapping file
map="/mnt/config/map.txt"

#log file
log="~/schwab.log"

#directory of files to sort
if [ ! -d "${1}" ]; then
	echo "Could not find ${1}"
	exit 0
fi

#mapping file
if [ ! -e $map ]; then
	echo "Could not find $map"
	exit 0
fi

./${THIS_PATH}/testmap.sh $clientDirectory $map

if [ ! -e $log ]; then
    touch $log
fi

echo "Loading mapping file..."
declare -a keys

while read line
do
	key=`echo $line | sed -e 's/ /_/g'`
	keys=( ${keys[@]-} $(echo "$key") )
done < ${map}

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
			clientMap=`echo "$i" | sed -e 's/_/ /g'`
			break
		fi
	done

	#make sure clientName is not empty
	if [ -n "$clientMap" ]; then
		#find directory name from mapping file
		directoryName=`echo $clientMap | cut -f2 -d:`

		#make sure the schwab statements directory exists in client folder
		if [ -e ${clientDirectory}/"${directoryName}"/Schwab\ Statements/ ]; then
			#echo "Found ${clientName} -> ${directoryName}"
			month=`echo ${f} | cut -f2 -d_ | cut -c1-2`
			year=`echo ${f} | cut -f2 -d_ | cut -c3-6`

			#the best way to parse the month I guess... lol
			case $month in
				01 )
					letterDir="A"
					monthDir="January";;
				02 )
					letterDir="B"
					monthDir="February";;
				03 )
					letterDir="C"
					monthDir="March";;
				04 )
					letterDir="D"
					monthDir="April";;
				05 )
					letterDir="E"
					monthDir="May";;
				06 )
					letterDir="F"
					monthDir="June";;
				07 )
					letterDir="G"
					monthDir="July";;
				08 )
					letterDir="H"
					monthDir="August";;
				09 )
					letterDir="I"
					monthDir="September";;
				10 )
					letterDir="J"
					monthDir="October";;
				11 )
					letterDir="K"
					monthDir="November";;
				12 )
					letterDir="L"
					monthDir="December";;
			esac

			#directory for the year in client folder schwab statements
			yearDirectory=${clientDirectory}/${directoryName}/Schwab\ Statements/$year/
			#directory for the month in client folder schwab statements
			finalDirectory=${clientDirectory}/${directoryName}/Schwab\ Statements/$year/$letterDir\ -\ $monthDir/

			if [ ! -d "${yearDirectory}" ]; then
				mkdir "${yearDirectory}"
			fi

			if [ ! -d "${finalDirectory}" ]; then
				mkdir "${finalDirectory}"
			fi

			echo "Copying ${f##*/} to ${directoryName}"

			if [ ! -e "${finalDirectory}"${f##*/} ]; then
				mv "$f" "${finalDirectory}"${f##*/}
			else
				"${f##*/} already exists in target location" >> $log
			fi
		fi
	else
		echo "${f##*/} has no map" >> $log
	fi
done

echo "Cleaning up... done"
rm "${1}"/temp.txt
echo "Finished moving Schwab Statements"
echo "Check schwab.log to view errors"
