#! /bin/bash
# args: directory of pdf files to generate the priliminary mapping text file
# use: output is the client name from schwab
# use: append "> file.txt" to command to generate a text file

#directory of files to sort
if [ ! -d ${1} ]; then
	exit 0
fi

mapping=( "map" )

shopt -s nullglob
for f in ${1}/*.pdf
do
	pdftotext -f 1 -l 1 ${f} ${1}/temp.txt
	clientName=`sed -n '6p' ${1}/temp.txt`
	if [ -n "$clientName" ]; then
		CHECK=0
		varTest=`echo $clientName | sed -e 's/ /_/g'`

		for i in ${mapping[@]}
		do
			if [ $i == "$varTest" ]; then
				CHECK=1
			fi
		done

		if [ $CHECK == 0 ]; then
			mapping=( ${mapping[@]-} $(echo "$varTest") )
		fi
	fi
done

for j in ${mapping[@]}
do
	echo "${j}:" | sed -e 's/_/ /g'
done
