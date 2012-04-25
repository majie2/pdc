#! /bin/bash
#simple script to split an account balance pdf report into individual pdfs by account

WORKING="/mnt/FLEXFILE/Admin/QuarterlyReports/2012"
OUTPUT="${WORKING}/output"

if [ -e "${1}" ]
then
    #generate an info file for the pdf
	pdfinfo "${1}" > "${1}.info.txt"

	#get the number of pages in the pdf
	numberOfPages=$(grep "Pages" "${1}.info.txt" | cut -f2 -d:)
	
	#remove info file
	rm "${1}.info.txt"
	
	current=""
	seed=true

	#extract each page
	for (( i=1; i<=$numberOfPages; i++ ))
	do	    
	    #convert to text
	    pdftotext -f $i -l $i "${1}" page_$i.txt
	    
	    temp=$(sed "3q;d" page_$i.txt)
	    company=$(echo ${temp:26})
	    
	    #convert slashes to underscores
	    company=${company//\//_}
	    
	    if [ "$company" != "$current" ] && [ $i -ne 1 ]
	    then
	        let last_page=$i-1
	        seed=true
	        
	        echo "Processing: $current"
	        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=${first_page} -dLastPage=${last_page} -sOutputFile="${OUTPUT}/${current// /_}.pdf" "${1}"
	    fi
	    
	    if [ $seed == true ]
	    then
            first_page=$i
            current=$company
            seed=false    
	    fi
	    
	    rm page_$i.txt
    done
    
    company=""
    
    if [ "$company" != "$current" ]
    then
        let last_page=$i-1
        
        echo "Processing: $current"
        gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER -dQUIET -dFirstPage=${first_page} -dLastPage=${last_page} -sOutputFile=${OUTPUT}/${current// /_}.pdf "${1}"
    fi
    
    read -p "Complete. Press ENTER to exit."
fi
