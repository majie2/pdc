#! /bin/bash
# args 1: pdf file to split
# args 2: directory for split pages
# args 3: amount of lines to add after key

# PLEASE AVOID HAVING SPACES IN THE DIRECTORY PATHS.

# check if the temp directory exists, if not, make it
if [ ! -d .splittemp ]; then
	mkdir .splittemp
fi

# check if destination exists, if not, make it
if [ ! -d ${2} ]; then
	mkdir ${2}
fi

if [ -e ${1} ]; then	
	#generate an info file for the pdf
	pdfinfo ${1} > ${1}.info.txt

	#get the number of pages in the pdf
	numberOfPages=`grep "Pages" ${1}.info.txt | cut -f2 -d:`
	echo "discovered ${numberOfPages##* } pages in ${1}..."

	#remove info file
	rm ${1}.info.txt

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

		echo "building ${pdfName}"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$i -dLastPage=$i -sOutputFile=${2}/${pdfName// /_}.pdf ${1}
	done
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

rm -r .splittemp
