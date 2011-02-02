#! /bin/bash
# args: directory of files

# statement file
STATEMENT="${1}/Statement.pdf"

# invoice file
INVOICE="${1}/Invoice.pdf"

# invoice file
CREDITMEMO="${1}/Credit.pdf"

# invoice file
TRUST="${1}/Trust.pdf"

# check if the directory exists
if [ -d ${1} ]; then
	echo "found ${1}..."
else
	echo "could not find ${1}, exiting..."
	exit 0
fi

THIS_PATH="`dirname \"$0\"`"

# build statements
${THIS_PATH}/splitPDF.sh ${STATEMENT} ${1}/statements 2
${THIS_PATH}/splitPDF.sh ${INVOICE} ${1}/invoices 2
${THIS_PATH}/splitPDF.sh ${CREDITMEMO} ${1}/credit_memos 2
${THIS_PATH}/splitPDF.sh ${TRUST} ${1}/trusts 2

# build invoices to clients
if [ -d ${1}/invoices ]; then
	echo "building client invoices..."

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
			outExcelInvoice=`echo ${1}/Excel/$fileName`
		else
			outExcelInvoice=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			outAttachment=`echo ${1}/Attachment/$fileName`
		else
			outAttachment=``
		fi

		echo "${fileName} final..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${outStatement} ${outExcelInvoice} ${1}/invoices/${fileName} ${outAttachment}
	done
fi

# build invoices to clients
if [ -d ${1}/Excel ]; then
	echo "building client invoices from excel..."

	if [ ! -d ${1}/final ]; then
		mkdir ${1}/final
	fi

	shopt -s nullglob
	for f in ${1}/Excel/*.pdf
	do
		fileName=`echo ${f##*/}`

		if [ -e ${1}/statements/$fileName ]; then
			outStatement=`echo ${1}/statements/$fileName`
		else
			outStatement=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			outAttachment=`echo ${1}/Attachment/$fileName`
		else
			outAttachment=``
		fi

		echo "${fileName} final..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/final/${fileName} ${outStatement} ${1}/Excel/${fileName} ${outAttachment}
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

		if [ -e ${1}/Excel/$fileName ]; then
			fcExcelInvoice=`echo ${1}/Excel/$fileName`
		else
			fcExcelInvoice=``
		fi

		if [ -e ${1}/credit_memos/$fileName ]; then
			fcCreditMemo=`echo ${1}/credit_memos/$fileName`
		else
			fcCreditMemo=``
		fi

		if [ -e ${1}/trusts/$fileName ]; then
			fcTrustInvoice=`echo ${1}/trusts/$fileName`
		else
			fcTrustInvoice=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			fcAttachment=`echo ${1}/attachment/$fileName`
		else
			fcAttachment=``
		fi

		if [ -e ${1}/Dist/$fileName ]; then
			fcDistributionChecklist=`echo ${1}/Dist/$fileName`
		else
			fcDistributionChecklist=``
		fi

		if [ -e ${1}/Misc/$fileName ]; then
			fcEmail=`echo ${1}/Misc/$fileName`
		else
			fcEmail=``
		fi

		echo "${fileName} file copy..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${fcExcelInvoice} ${1}/invoices/${fileName} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcDistributionChecklist} ${fcEmail}
	done
fi

# build file copy invoice
if [ -d ${1}/Dummy ]; then
	echo "building file copy invoices from excel..."

	if [ ! -d ${1}/file_copy ]; then
		mkdir ${1}/file_copy
	fi

	shopt -s nullglob
	for f in ${1}/Dummy/*.pdf
	do
		fileName=`echo ${f##*/}`

		if [ -e ${1}/Excel/$fileName ]; then
			fcExcel=`echo ${1}/Excel/$fileName`
		else
			fcExcel=``
		fi

		if [ -e ${1}/credit_memos/$fileName ]; then
			fcCreditMemo=`echo ${1}/credit_memos/$fileName`
		else
			fcCreditMemo=``
		fi

		if [ -e ${1}/trusts/$fileName ]; then
			fcTrustInvoice=`echo ${1}/trusts/$fileName`
		else
			fcTrustInvoice=``
		fi

		if [ -e ${1}/attachment/$fileName ]; then
			fcAttachment=`echo ${1}/attachment/$fileName`
		else
			fcAttachment=``
		fi

		if [ -e ${1}/Dist/$fileName ]; then
			fcDistributionChecklist=`echo ${1}/Dist/$fileName`
		else
			fcDistributionChecklist=``
		fi

		if [ -e ${1}/Misc/$fileName ]; then
			fcEmail=`echo ${1}/Misc/$fileName`
		else
			fcEmail=``
		fi

		echo "${fileName} file copy..."
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile=${1}/file_copy/${fileName} ${fcExcel} ${1}/Dummy/${fileName} ${fcCreditMemo} ${fcTrustInvoice} ${fcAttachment} ${fcDistributionChecklist} ${fcEmail}
	done
fi

echo "cleaning up..."

#rm -r ${1}/statements
#rm -r ${1}/invoices

echo "done!"
echo "Invoices to clients in final folder & file copy invoices in the file_copy folder"
