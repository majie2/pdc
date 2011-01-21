#! /bin/bash
# args: directory of files

# statement file
STATEMENT="${1}/statements.pdf"

# invoice file
INVOICE="${1}/invoices.pdf"

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

# build invoices to clients
if [ -d ${1}/invoices ]; then
	echo "building invoices..."

	if [ ! -d ${1}/final ]; then
		mkdir ${1}/final
	fi

	shopt -s nullglob
	for f in ${1}/invoices/*.pdf
	do
		fileName=`echo ${f##*/}`

		if [ -e ${1}/statements/$fileName ]; then
			outStatement=`echo ${1}/statements/$fileName`
		else
			outStatement=``
		fi

		if [ -e ${1}/excel/$fileName ]; then
			outExcelInvoice=`echo ${1}/excel/$fileName`
		else
			outExcelInvoice=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			outAttachment=`echo ${1}/attachment/$fileName`
		else
			outAttachment=``
		fi

		echo "${fileName} final..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${outStatement} ${outExcelInvoice} ${1}/invoices/${fileName} ${outAttachment}
	done
fi

# build file copy invoice
if [ -d ${1}/invoices ]; then
	echo "building file copy invoices..."

	if [ ! -d ${1}/file_copy ]; then
		mkdir ${1}/file_copy
	fi

	shopt -s nullglob
	for f in ${1}/invoices/*.pdf
	do
		fileName=`echo ${f##*/}`

		if [ -e ${1}/excel/$fileName ]; then
			fcExcelInvoice=`echo ${1}/excel/$fileName`
		else
			fcExcelInvoice=``
		fi

		if [ -e ${1}/credit_memo/$fileName ]; then
			fcCreditMemo=`echo ${1}/credit_memo/$fileName`
		else
			fcCreditMemo=``
		fi

		if [ -e ${1}/trust_invoice/$fileName ]; then
			fcTrustInvoice=`echo ${1}/trust_invoice/$fileName`
		else
			fcTrustInvoice=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			fcAttachment=`echo ${1}/attachment/$fileName`
		else
			fcAttachment=``
		fi

		if [ -e ${1}/distribution_checklist/$fileName ]; then
			fcDistributionChecklist=`echo ${1}/distribution_checklist/$fileName`
		else
			fcDistributionChecklist=``
		fi

		if [ -e ${1}/email/$fileName ]; then
			fcEmail=`echo ${1}/email/$fileName`
		else
			fcEmail=``
		fi

		if [ -e ${1}/note/$fileName ]; then
			fcNote=`echo ${1}/note/$fileName`
		else
			fcNote=``
		fi

		echo "${fileName} file copy..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${fcExcelInvoice} ${1}/invoices/${fileName} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcDistributionChecklist} ${fcEmail} ${fcNote}
	done
fi

echo "cleaning up..."

rm -r ${1}/temp
rm -r ${1}/statements
rm -r ${1}/invoices

echo "done!"
echo "Invoices to clients in final folder & file copy invoices in the file_copy folder"
