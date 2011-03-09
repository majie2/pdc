#! /bin/bash
# author:	Josef Kelly
# date:		February 11 2011
# license:	MIT
#
# description:
# Extracts invoice numbers and billing amounts for specified brokers
#
# args 1: the broker text file

BILLINGDIR="/mnt/billing"

# invoice file
INVOICE="${BILLINGDIR}/invoices.pdf"

if [ ! -e ${1} ]; then
	exit 0
fi

# build invoice pdfs
if [ -e ${INVOICE} ]; then
	if [ ! -d ${BILLINGDIR}/temp ]; then
		mkdir ${BILLINGDIR}/temp
	fi
	
	# get the number of pages in statement
	pdfinfo ${INVOICE} > ${INVOICE}.info.txt
	invoicePages=`grep "Pages" ${INVOICE}.info.txt | cut -f2 -d:`

	#remove temporary info file
	rm ${INVOICE}.info.txt

	# extract each page
	for (( j=1; j<=$invoicePages; j++ ))
	do
		pdftotext -f $j -l $j ${INVOICE} ${BILLINGDIR}/temp/page_$j.txt
	done

	while read line
	do
		path=`grep -lrw "$(echo -n $line | tr -d '\r')" ${BILLINGDIR}/temp/`

		#echo $path

		invoiceKey=`grep -n "Invoice Number:" $path | cut -f1 -d:`
		let invoiceLineNumber=invoiceKey+1
		invoice=`sed -n ${invoiceLineNumber}p $path`

		amountKey=`grep -n "TOTAL INVOICE AMOUNT:" $path | cut -f1 -d:`

		let lineTwo=amountKey+2
		let lineFour=amountKey+4
		let lineSix=amountKey+6

		lineContents=`sed -n ${lineTwo}p $path`

		if [ "$lineContents" = "0.00" ]; then
			amount=`sed -n ${lineTwo}p $path`
		fi

		if [ "$lineContents" = "$" ]; then
			amount=`sed -n ${lineFour}p $path`
		fi

		if [ ! "$lineContents" = "0.00" ] && [ ! "$lineContents" = "$" ]; then
			lineContents=`sed -n ${lineFour}p $path`
			
			if [ $lineContents = "$" ]; then
				amount=`sed -n ${lineSix}p $path`
			else
				amount=`sed -n ${lineFour}p $path`
			fi
		fi

		echo "$(echo -n $line | tr -d '\r'),${invoice},${amount}"
	done < ${1}

	rm -r ${BILLINGDIR}/temp
fi
