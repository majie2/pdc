#! /bin/bash
# author:	Josef Kelly
# date:		October 24, 2011
# license:	MIT
#
# description:
#   I'll write this later
#   The similarities between this and splitPDF.sh are striking. Basically the same.
#   However, splitPDF works and I am not about to mess it up. We'll merge after testing.
#
# arguments
# args 1: pdf file to split
# args 2: directory for split pages

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

if [ -e "${1}" ]; then
    #generate an info file for the pdf
	pdfinfo ${1} > ${1}.info.txt

	#get the number of pages in the pdf
	numberOfPages=`grep "Pages" ${1}.info.txt | cut -f2 -d:`
	echo -e "\nExtracting ${numberOfPages##* } pages in ${1##*/}"
	echo "${numberOfPages##* } pages" > ${1}.log.txt

	#remove info file
	#rm ${1}.info.txt

    # extract each page
    for (( i=1; i<=$numberOfPages; i++ ))
    do
        #convert pdf page to text file
        pdftotext -f $i -l $i ${1} .splittemp/page_$i.txt
        
        #find line number with KEY
        keyLineNumber=`grep -n " FB" .splittemp/page_$i.txt | cut -f1 -d:`
        
        #find line number with other KEY if first KEY doesn't exist
        if [ -z $keyLineNumber ]; then
	        keyLineNumber=`grep -n " CP" .splittemp/page_$i.txt | cut -f1 -d:`
        fi
        
        # pdfname format: NICKNAME.TYPE
        pdfName=`sed "${keyLineNumber}q;d" .splittemp/page_$i.txt | cut -f1 -d' '`

        draw_progressbar ${i} ${numberOfPages}
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$i -dLastPage=$i -sOutputFile=${2}/${pdfName// /_}.pdf ${1}
        echo "${pdfName}" >> ${1}.log.txt
    done
else
	echo "File does not exist: ${1}"
	exit 0
fi

#remove the temporary file
rm -r .splittemp

echo -e "\n\nFinished extracting pages from ${1##*/}"
echo "Log file: ${1}.log.txt"
