#! /bin/bash
# args 1: the location of the top folder containing invoices.pdf
# args 2: the broker text file

# invoice file
INVOICE="${1}/invoices.pdf"

if [ ! -e ${2} ]; then
	exit 0
fi

# build invoice pdfs
if [ -e ${INVOICE} ]; then
	if [ ! -d ${1}/temp ]; then
		mkdir ${1}/temp
	fi
	
	# get the number of pages in statement
	pdfinfo ${INVOICE} > ${INVOICE}.info.txt
	invoicePages=`grep "Pages" ${INVOICE}.info.txt | cut -f2 -d:`

	#remove temporary info file
	rm ${INVOICE}.info.txt

	# extract each page
	#for (( j=1; j<=$invoicePages; j++ ))
	#do
	#	pdftotext -f $j -l $j ${INVOICE} ${1}/temp/page_$j.txt
	#done

	while read line
	do
		path=`grep -lrw "$(echo -n $line | tr -d '\r')" ${1}/temp/`

		invoiceKey=`grep -n "Invoice Number:" $path | cut -f1 -d:`
		let invoiceLineNumber=invoiceKey+1
		invoice=`sed -n ${invoiceLineNumber}p $path`

		amountKey=`grep -n "TOTAL INVOICE AMOUNT:" $path | cut -f1 -d:`
		let lineNumber=amountKey+2
		lineContents=`sed -n ${lineNumber}p $path`

		if [ $lineContents = "$" ]; then
			let amountLineNumber=amountKey+4
			amount=`sed -n ${amountLineNumber}p $path`
		else
			amount="0.00"
		fi

		echo "${invoice},${amount}"
	done < ${2}

	#rm -r ${1}/temp
fi
