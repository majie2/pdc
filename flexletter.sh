#! /bin/bash
#   devdevdev
#   args 1: letter merge file
#   args 2: destination dir

if [ ! -d ${2} ]; then
    mkdir ${2}
fi

if [ ! -d ${2}/tmp ]; then
    mkdir ${2}/tmp
fi

if [ -e ${1} ]; then	
	#generate an info file for the pdf
	pdfinfo ${1} > ${1}.info.txt

	#get the number of pages in the pdf
	numberOfPages=`grep "Pages" ${1}.info.txt | cut -f2 -d:`

	#remove info file
	rm ${1}.info.txt
	
	echo "Extracting pages from merge file..."

	#extract each page
	for (( i=1; i<=$numberOfPages; i++ )); do
	    pdftotext -f $i -l $i ${1} ${2}/tmp/page_$i.txt
	done
fi

for f in ${2}/balance/*.pdf; do
    filename=`echo ${f##*/} | cut -f1 -d. | sed -e 's/_/ /g'`
    echo ${f##*/}
    grep "$filename" ${2}/tmp/*.pdf | cut -f1 -d:
done
