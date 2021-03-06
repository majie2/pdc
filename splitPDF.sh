#! /bin/bash
# author:	Josef Kelly
# date:		April 13, 2011
# license:	MIT
#
# description:
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
# args 4: secondary key
# args 5: case sensitive or case insensitive for secondary key
#       : YES IT MATTERS LULZ (just pass 1 for -i switch on grep)
#       : qm uses 'dummy 1', 401k uses 'TRUST'q

# PLEASE AVOID HAVING SPACES IN THE DIRECTORY PATHS

bar_width=50

# parameters:
# $1 - actual size
# $2 - final size
draw_progressbar() {
    local part=$1
    local place=$((part*bar_width/$2))
    local i
 
    echo -ne "\r$((part*100/$2))% ["
 
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

# check if alternate destination exists, if not, make it
if [ ! -d ${2}/${4} ]; then
	mkdir ${2}/${4}
fi

if [ -e ${1} ]; then	
	#generate an info file for the pdf
	pdfinfo ${1} > ${1}.info.txt

	#get the number of pages in the pdf
	numberOfPages=`grep "Pages" ${1}.info.txt | cut -f2 -d:`
	echo -e "\nExtracting ${numberOfPages##* } pages in ${1##*/}"
	echo "${numberOfPages##* } pages" > ${1}.log.txt

	#remove info file
	#rm ${1}.info.txt

	#extract each page
	for (( i=1; i<=$numberOfPages; i++ ))
	do
	    isAlternate=""
	    alternate=""
		#convert pdf page to text file
		pdftotext -f $i -l $i ${1} .splittemp/page_$i.txt

		#find line number with KEY
		keyLineNumber=`grep -n "CLIENT ID:" .splittemp/page_$i.txt | cut -f1 -d:`

		#construct the line number for the client id
		let clientIDLineNumber=${keyLineNumber}+${3}

		#extract client id
		pdfName=`sed "${clientIDLineNumber}q;d" .splittemp/page_$i.txt | cut -f1 -d' '`
		
		#is this an alternate page?
		if [ "$5" ]; then
		    isAlternate=`grep -i "${4}" .splittemp/page_$i.txt`
		else
		    isAlternate=`grep "${4}" .splittemp/page_$i.txt`
		fi
		
		if [ "$isAlternate" ]; then
		    alternate="${4}"
		fi
		
        draw_progressbar ${i} ${numberOfPages}
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$i -dLastPage=$i -sOutputFile=${2}/$alternate/${pdfName// /_}.pdf ${1}
		echo "${pdfName} ${alternate}" >> ${1}.log.txt
	done
else
	echo "File does not exist: ${1}"
	exit 0
fi

#remove the temporary file
rm -r .splittemp

echo -e "\n\nFinished extracting pages from ${1##*/}"
echo "Log file: ${1}.log.txt"
