#! /bin/bash
# arg 1 : directory with pdfs
# loans must be in directory called loans, must be saved manually as plain text files

OUTFILE="${1}/paychex.csv"
LOANS="${1}/loans.txt"
PS_CONFIG="${1}/ps.config.txt"

# system variables
BOLD_ON="\033[1m"
BOLD_OFF="\033[0m"
RED='\E[31;47m'
BLUE='\E[36;40m'
GREEN='\E[32;40m'

clear

echo -e "\n##################################################"
echo "#                                                #"
echo "# rspchx.sh                                      #"
echo "#                                                #"
echo "# author  : josef kelly                          #"
echo "# license : mit                                  #"
echo "# version : 1.1                                  #"
echo "#                                                #"
echo "##################################################"

warning_prompt () {
    echo -e $RED
    echo -e "${BOLD_ON}${1}${BOLD_OFF}"
    tput sgr0
}

message () {
    echo -e $GREEN
    echo -e "${1}"
    tput sgr0
}

if [ -e "$OUTFILE" ]
then
    rm $OUTFILE
fi

if [ -e "$LOANS" ]
then
    rm $LOANS
fi

if [ ! -e "$PS_CONFIG" ]
then
    echo "File does not exist"
    read -p "Press ENTER to exit."
    exit 0
fi

if [ ! -d "${1}" ]
then
    echo "Directory does not exist: $1"
    read -p "Press ENTER to exit."
    exit 0
fi

echo -n "Converting pdfs... "

for f in ${1}/*.pdf
do
    pdftotext -q "$f"
done

message "complete"
echo -n "Processing loans... "

for f in ${1}/loans/*.txt
do
    cat "$f" >> "$LOANS"
done

message "complete"

echo -n "Extracting data... "

for f in ${1}/*.txt
do
    LINE_NUMBER=1
    FILE=$(echo ${f##*/} | cut -f1 -d'-')
    
    while read line
    do
        is_ssn=$(echo $line | cut -f2 -d' ')
        
        if [ "${#is_ssn}" -eq 11 ] && [ "${is_ssn:3:1}" == "-" ] && [ "${is_ssn:6:1}" == "-" ]
        then
            ee_id=$(echo $line | cut -f1 -d' ')
            loan_loc=$(grep -n "$ee_id" "$LOANS" | cut -f1 -d:)
            
            if [ "${#loan_loc}" -gt 0 ]
            then
                loan_info=$(sed -n "${loan_loc}p" "$LOANS" | cut -f3 -d'-')
                loan_one=$(echo $loan_info | cut -f2 -d' ')
                loan_two=$(echo $loan_info | cut -f3 -d' ')
            else
                loan_info=""
                loan_one=""
                loan_two=""
            fi
        
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
            
            ps_percent=$(grep "${shop:0:3}" "$PS_CONFIG" | cut -f2 -d' ' | tr -d '\r')
            pay_sanitized=$(echo $gross | tr -d ',')
            ps_amount=$(echo "$pay_sanitized * $ps_percent" | bc)
            
            echo "${FILE},${ssn},${shop:0:3},\"${last_name}\",\"${first_name}\",${gross},4K,${ee_amount},PS,${ps_amount},${loan_one},${loan_two},,dob,doh,dot,address,city,state,zip" >> ${OUTFILE}
            
            #reset
            ee_percent=""
            ee_amount=""
            er_percent=""
            er_amount=""
            balance=""
            loan_info=""
            loan_one=""
            loan_two=""
            name=""
            first_name=""
            last_name=""
            gross=""
            has_ee=""
            ssn=""
            shop=""
            ee_id=""
            loan_loc=""
            ps_percent=""
            pay_sanitized=""
            ps_amount=""
        fi
        
        let LINE_NUMBER=${LINE_NUMBER}+1
    done < "$f"
done

message "complete"

read -p "Complete. Press ENTER to exit."
