#! /bin/bash
# arg 1 : directory with pdfs

OUTFILE="${1}/paychex.csv"

if [ -e "$OUTFILE" ]
then
    rm $OUTFILE
fi

if [ ! -d "${1}" ]
then
    echo "Directory does not exist: $1"
    exit 0
fi

for f in ${1}/*.pdf
do
    pdftotext "$f"
done

for f in ${1}/*.txt
do
    LINE_NUMBER=1
    FILE=$(echo ${f##*/} | cut -f1 -d'-')
    
    while read line
    do
        is_ssn=$(echo $line | cut -f2 -d' ')
        
        if [ "${#is_ssn}" -eq 11 ] && [ "${is_ssn:3:1}" == "-" ] && [ "${is_ssn:6:1}" == "-" ]
        then
            let name_location=${LINE_NUMBER}-1
            let location_2=${LINE_NUMBER}+2
            let location_4=${LINE_NUMBER}+4
            let location_6=${LINE_NUMBER}+6
            let location_8=${LINE_NUMBER}+8
            let location_10=${LINE_NUMBER}+10
            let location_12=${LINE_NUMBER}+12
            
            name=$(sed -n "${name_location}p" "$f" | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            first_name=$(echo $name | cut -f2 -d,)
            last_name=$(echo $name | cut -f1 -d,)
            gross=$(sed -n "${location_2}p" "$f")
            has_ee=$(sed -n "${location_10}p" "$f")
            ssn=$(echo $is_ssn | tr -d '-')
            shop=$(echo $line | cut -f1 -d' ')
            
            if [[ "$has_ee" =~ [a-zA-Z] ]]
            then
                ee_percent=""
                ee_amount=""
                er_percent=$(sed -n "${location_4}p" "$f")
                er_amount=$(sed -n "${location_6}p" "$f")
                balance=$(sed -n "${location_8}p" "$f")
            else
                ee_percent=$(sed -n "${location_4}p" "$f")
                ee_amount=$(sed -n "${location_6}p" "$f")
                er_percent=$(sed -n "${location_8}p" "$f")
                er_amount=$(sed -n "${location_10}p" "$f")
                balance=$(sed -n "${location_12}p" "$f")
            fi
            
            echo "${FILE},${ssn},${shop:0:3},\"${last_name}\",\"${first_name}\",${gross},4K,${ee_amount},PS,,loan 1,loan 2,,dob,doh,dot,address,city,state,zip" >> ${OUTFILE}
        fi
        
        let LINE_NUMBER=${LINE_NUMBER}+1
    done < "$f"
done

read -p "Complete. Press ENTER to exit."
