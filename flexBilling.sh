#! /bin/bash
# author:	Josef Kelly
# date:		March 9 2011
# license:	MIT
#
# description:
# This script generates the final billing pdfs for flex clients.
#
# args: directory of files

# statement file
STATEMENT="${1}/Statement.pdf"

# invoice file
INVOICE="${1}/Invoice.pdf"

# check if the directory exists
if [ -d ${1} ]; then
	echo "found ${1}..."
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

# check if the temp directory exists
if [ ! -d ${1}/temp ]; then
	mkdir ${1}/temp
fi

# build statement pdfs
if [ -e ${STATEMENT} ]; then
	if [ ! -d ${1}/statements ]; then
		mkdir ${1}/statements
	fi
	
	# get the number of pages in statement
	pdfinfo ${STATEMENT} > ${STATEMENT}.info.txt
	statementPages=`grep "Pages" ${STATEMENT}.info.txt | cut -f2 -d:`
	echo "discovered ${statementPages##* } pages in ${STATEMENT}..."

	#remove temporary info file
	rm ${STATEMENT}.info.txt

	# extract each page
	for (( i=1; i<=$statementPages; i++ ))
	do
		# get client & plan id
		pdftotext -f $i -l $i ${STATEMENT} ${1}/temp/page_$i.txt
		statementClientId=`grep -n " FB" ${1}/temp/page_$i.txt | cut -f1 -d:`
		if [ -z $statementClientId ]; then
			statementClientId=`grep -n " CP" ${1}/temp/page_$i.txt | cut -f1 -d:`
		fi
		# pdfname format: NICKNAME.TYPE
		statementPDF=`sed "${statementClientId}q;d" ${1}/temp/page_$i.txt | cut -f1 -d' '`

		echo "building ${statementPDF}.statement"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$i -dLastPage=$i -sOutputFile=${1}/statements/${statementPDF// /_}.pdf ${STATEMENT}

		# remove temporary txt file
		rm ${1}/temp/page_$i.txt
	done
else
	echo "could not find ${STATEMENT}, exiting..."
	exit 0
fi

# build invoice pdfs
if [ -e ${INVOICE} ]; then
	if [ ! -d ${1}/invoices ]; then
		mkdir ${1}/invoices
	fi
	
	# get the number of pages in statement
	pdfinfo ${INVOICE} > ${INVOICE}.info.txt
	invoicePages=`grep "Pages" ${INVOICE}.info.txt | cut -f2 -d:`
	echo "discovered ${invoicePages##* } pages in ${INVOICE}..."

	#remove temporary info file
	rm ${INVOICE}.info.txt

	# extract each page
	for (( j=1; j<=$invoicePages; j++ ))
	do
		# get client & plan id
		pdftotext -f $j -l $j ${INVOICE} ${1}/temp/page_$j.txt
		invoiceClientId=`grep -n " FB" ${1}/temp/page_$j.txt | cut -f1 -d:`
		if [ -z $invoiceClientId ]; then
			invoiceClientId=`grep -n " CP" ${1}/temp/page_$j.txt | cut -f1 -d:`
		fi
		# pdfname format: NICKNAME.TYPE
		invoicePDF=`sed "${invoiceClientId}q;d" ${1}/temp/page_$j.txt | cut -f1 -d' '`

		echo "building ${invoicePDF}.invoice"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=$j -dLastPage=$j -sOutputFile=${1}/invoices/${invoicePDF// /_}.pdf ${INVOICE}
		
		# remove temporary txt file
		rm ${1}/temp/page_$j.txt
	done
else
	echo "could not find ${INVOICE}, exiting..."
	exit 0
fi

# combine everything
if [ -d ${1}/invoices ]; then
	echo "building billing pdfs..."

	if [ ! -d ${1}/final ]; then
		mkdir ${1}/final
	fi
	
	if [ ! -d ${1}/file_copy ]; then
		mkdir ${1}/file_copy
	fi

	shopt -s nullglob
	for f in ${1}/invoices/*.pdf
	do
		fileName=`echo ${f##*/}`
		fileNameStripped=`echo ${fileName} | cut -f1-2 -d.`
		isTerm="${fileNameStripped}.TERM"

		if [ -e ${1}/Detail/$isTerm ]; then
			echo "${fileNameStripped} is terminated"
		else
			if [ -e ${1}/statements/$fileName ]; then
				outStatement=`echo ${1}/statements/$fileName`
			else
				outStatement=``
			fi

			if [ -e ${1}/Detail/$fileName ]; then
				outDetail=`echo ${1}/Detail/$fileName`
			else
				outDetail=``
			fi

			if [ -e ${1}/Coverpage/$fileName ]; then
				outCoverpage=`echo ${1}/Coverpage/$fileName`
			else
				outCoverpage=``
			fi

			if [ -e ${1}/Debitcard/$fileName ]; then
				outDebit=`echo ${1}/Debitcard/$fileName`
			else
				outDebit=``
			fi

			if [ -e ${1}/Limited/$fileName ]; then
				outLimited=`echo ${1}/Limited/$fileName`
			else
				outLimited=``
			fi
			
			if [ -e ${1}/Credit_memo/$fileName ]; then
				outCreditMemo=`echo ${1}/Credit_memo/$fileName`
			else
				outCreditMemo=``
			fi
			
			if [ -e ${1}/Misc/$fileName ]; then
				outMisc=`echo ${1}/Misc/$fileName`
			else
				outMisc=``
			fi

			echo "${fileName} final..."
			gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${1}/invoices/${fileName} ${outCoverpage} ${outDetail} ${outLimited} ${outDebit} ${outStatement}
			echo "${fileName} file copy..."
			gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${1}/invoices/${fileName} ${outCoverpage} ${outDetail} ${outLimited} ${outDebit} ${outCreditMemo} ${outMisc}
		fi
	done
fi

echo "cleaning up..."

rm -r ${1}/temp
rm -r ${1}/statements
rm -r ${1}/invoices

echo "done!"
echo "Your files are in the final folder"
