#! /bin/bash
# author:	Josef Kelly
# date:		Saint Patricks Day
# license:	MIT
#
# description:
#
# THIS MAY OR MAY NOT STAY. DEPENDS ON OTHER STUFFS. REALLY, ONE LINE ADDITION???
#
# Splits a specified pdf into individual pages. Each page will be a separate pdf file.
# Each page is named using the following convention: the page is converted into a text file. The script searches for a unique key in that text file.
# Then the script extracts the line from the text file a specified number of lines after the unique key
# Only the first token delimited by spaces will be used, i.e. if the line extracted is 'namethis something cool', the pdf will be named 'namethis.pdf'
#
# arguments
# args 1: pdf file to split
# args 2: directory for split pages
# args 3: amount of lines to add after unique key

# PLEASE AVOID HAVING SPACES IN THE DIRECTORY PATHS.
# PLEASE AVOID HAVING SPACES IN THE DIRECTORY PATHS.
# PLEASE AVOID HAVING SPACES IN THE DIRECTORY PATHS.

bar_width=30
tick=0.2

function paint_progressbar() {
    local part=$1
    local place=$((part*bar_width/$2))
    local i
    
    echo -en "\r$((part*100/total))% ["
    
    for i in $(seq 1 $bar_width); do
        [ "$i" -le "$place" ] && echo -n "#" || echo -n " ";
    done
    echo -n "]"
}

# check if the temp directory exists, if not, make it
if [ ! -d .splittemp ]; then
	mkdir .splittemp
fi

# check if destination exists, if not, make it
if [ ! -d ${2} ]; then
	mkdir ${2}
fi

# check if trust destination exists, if not, make it
if [ ! -d ${2}/TRUST ]; then
	mkdir ${2}/TRUST
fi

if [ -e ${1} ]; then	
	#generate an info file for the pdf
	pdfinfo ${1} > ${1}.info.txt

	#get the number of pages in the pdf
	numberOfPages=`grep "Pages" ${1}.info.txt | cut -f2 -d:`
	total=${numberOfPages##* }
	echo "Discovered ${numberOfPages##* } pages in ${1}"

	#remove info file
	rm ${1}.info.txt
	
	echo "Extracting pages..."

	#extract each page
	for (( i=1; i<=$numberOfPages; i++ ))
	do
		#convert pdf page to text file
		pdftotext -f $i -l $i ${1} .splittemp/page_$i.txt

		#find line number with KEY
		keyLineNumber=`grep -n "CLIENT ID:" .splittemp/page_$i.txt | cut -f1 -d:`

		#construct the line number for the client id
		let clientIDLineNumber=${keyLineNumber}+${3}

		#extract client id
		pdfName=`sed "${clientIDLineNumber}q;d" .splittemp/page_$i.txt | cut -f1 -d' '`
		
		#is this a trust page?
		istrust=`sed "${clientIDLineNumber}q;d" .splittemp/page_$i.txt | grep "TRUST" | cut -f2 -d' '`

		echo "${pdfName} ${istrust}"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$i -dLastPage=$i -sOutputFile=${2}/$istrust/${pdfName// /_}.pdf ${1}
	done
else
	echo "File does not exist: ${1}"
	exit 0
fi

#remove the temporary file
rm -r .splittemp
