#! /bin/bash

map=$(echo ${1})

file1="Allocation Report 123112 QTD.pdf"
file2="Loan Detail Report 123112 QTD.pdf"
file1enc="Allocation Report 123112 QTD.encrypted.pdf"
file2enc="Loan Detail Report 123112 QTD.encrypted.pdf"

pd="/mnt/g"

while read line
do
	client=$(echo $line | cut -f1 -d,)
	key=$(echo $line | cut -f2 -d, | tr -d '\r')
	echo "--------------------------------------------------"
	echo "PASSWORD: ${key}"
	
	if [ -e "${pd}/${client}/Allocation Reports/2012/${file1}" ]
	then
		echo "FILE FOUND: ${pd}/${client}/Allocation Reports/2012/${file1}"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile="${pd}/${client}/Allocation Reports/2012/${file1enc}" -dEncryptionR=3 -dKeyLength=128 -sUserPassword=$(echo $key) -sOwnerPassword=outf13ld "${pd}/${client}/Allocation Reports/2012/${file1}"
		#echo "${pd}/${client}/Allocation Reports/2012/${file1enc}"
	else
		echo "NOT FOUND: ${pd}/${client}/Allocation Reports/2012/${file1}" >> not_found.txt
	fi
	
	if [ -e "${pd}/${client}/Loan Detail Reports/2012/${file2}" ]
	then
		echo "FILE FOUND: ${pd}/${client}/Loan Detail Reports/2012/${file2}"
		gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -sOutputFile="${pd}/${client}/Loan Detail Reports/2012/${file2enc}" -dEncryptionR=3 -dKeyLength=128 -sUserPassword=$(echo $key) -sOwnerPassword=outf13ld "${pd}/${client}/Loan Detail Reports/2012/${file2}"
		#echo "${pd}/${client}/Loan Detail Reports/2012/${file2enc}"
	else
		echo "NOT FOUND: ${pd}/${client}/Loan Detail Reports/2012/${file2}" >> not_found.txt
	fi
done < ${map}
