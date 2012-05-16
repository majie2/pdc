#! /bin/bash

SC_PATH="/mnt/pd/Rserection/process/sc"

DEDUCTION_PATH="${SC_PATH}/deduction.txt"
PAYDETAIL_PATH="${SC_PATH}/detail.txt"
ROSTER_PATH="${SC_PATH}/roster.txt"

PAYDETAIL_PDF="${SC_PATH}/detail.pdf"

if [ ! -e "$1" ]
then
    echo "File does not exist: $1"
    exit 0
fi

if [ ! -e "$2" ]
then
    echo "File does not exist: $2"
    exit 0
fi

if [ ! -e "$3" ]
then
    echo "File does not exist: $3"
    exit 0
fi

convert_date () {
    if [ "${#1}" -gt 1 ]
    then
        month=$(echo ${1} | cut -f1 -d'/')
        day=$(echo ${1} | cut -f2 -d'/')
        year=$(echo ${1} | cut -f3 -d'/')
        
        if [ $year -lt 13 ]
        then
            year="20$year"
        else
            year="19$year"
        fi
        
        if [ $month -lt 10 ]
        then
            month="0$month"
        fi
        
        echo "$month/$day/$year"
    fi
}

print_info=false
current="null"

while read line
do            
    if [ "${line:3:1}" = "-" ] && [ "${line:6:1}" = "-" ]
    then
        ssn=$(echo ${line:0:11})
        
        if [ "$ssn" != "$current" ]
        then
            if [ "$current" != "null" ]
            then
                #print everything
                stripped_ssn=$(echo $current | tr -d '-')
                dob=$(convert_date "$dob")
                doh=$(convert_date "$doh")
                dot=$(convert_date "$dot")
                echo "\"$stripped_ssn\",\"${shop:3:3}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,%er,\"$loan_one\",\"$loan_two\",total,"
                
                dob=""
                doh=""
                dot=""
                address=""
                state=""
                zip=""
                gross_pay=""
                gross_pay_key=""
                gross_pay_line=""
            fi
            
            current=$(echo $ssn)
            census=$(grep "$ssn" "$2")
            census=$(echo -n $census)
            
            address_extract=$(echo $census | cut -f2 -d',' | cut -f3 -d'-')
            address_count=$(echo $address_extract | wc -w)
            
            if [ ${census: -1} == "Y" ]
            then
                #active
                address=$(echo $address_extract | cut -f3-${address_count} -d' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
                dob=$(echo $census | cut -f3 -d',' | cut -f4 -d' ')
                doh=$(echo $census | cut -f3 -d',' | cut -f5 -d' ')
                dot=""
            elif [ ${census: -1} == "N" ]
            then
                #not active
                address=""
            elif [[ ${census: -1} =~ [0-9] ]]
            then
                active_key=$(echo $census | grep -o '/' | wc -l)
                let active_key=$active_key+1
                active=$(echo $census | cut -f${active_key} -d'/' | cut -f2 -d' ')
                
                if [ "$active" == "Y" ]
                then
                    address=$(echo $address_extract | cut -f6-${address_count} -d' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
                    dob=$(echo $address_extract | cut -f2 -d' ')
                    doh=$(echo $address_extract | cut -f4 -d' ')
                    dot=""
                else
                    address=$(echo $address_extract | cut -f7-${address_count} -d' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
                    dob=$(echo $address_extract | cut -f2 -d' ')
                    doh=$(echo $address_extract | cut -f4 -d' ')
                    dot=$(echo $address_extract | cut -f5 -d' ')
                fi
            fi
            
            state=$(echo $census | cut -f3 -d',' | cut -f2 -d' ')
            zip=$(echo $census| cut -f3 -d',' | cut -f3 -d' ')

            #reset
            middle_test=$(echo $line | cut -f4 -d' ')
            
            if [[ "$middle_test" =~ [0-9] ]]
            then
                location=0
                first_name_extract=$(echo $line | cut -f3 -d' ')
                #shop=$(echo $middle_test)
            else
                location=1
                first_name_extract=$(echo $line | cut -f3-4 -d' ')
                #shop=$(echo $line | cut -f5 -d' ')
            fi
            
            first_name=$(echo $first_name_extract | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            last_name=$(echo $line | cut -f2 -d' ' | cut -f1 -d',' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            deduction=""
            loan_one=""
            loan_two=""
            shop="300"
            
            let code_location=$location+6
            let amnt_location=$location+5
            
            gross_pay_line=$(grep -n -m 1 "xxx-xx-${current: -4}" "$3")
            
            if [[ "$gross_pay_line" == *"Gross Pay"* ]]
            then
                gross_pay_key=$(echo $gross_pay_line | grep -b -o "Gross Pay" | cut -f1 -d:)
                gross_pay=$(echo ${gross_pay_line:${gross_pay_key}} | cut -f3 -d' ')
            else
                gross_pay_key=$(echo $gross_pay_line | cut -f1 -d:)
                let gross_pay_key=$gross_pay_key+2
                gross_pay=$(sed "${gross_pay_key}q;d" "$3" | cut -f3 -d' ')
            fi
        fi
        
        code=$(echo $line | cut -f${code_location} -d' ')
        
        if [ "$code" == "03" ] #deduction
        then
            deduction=$(echo $line | cut -f${amnt_location} -d' ')
        elif [ "$code" == "12" ] #loan 1
        then
            loan_one=$(echo $line | cut -f${amnt_location} -d' ')
        elif [ "$code" == "02" ] #loan 2
        then
            loan_two=$(echo $line | cut -f${amnt_location} -d' ')
        else
            echo "NO CODE AVAILABLE"
        fi
    fi
done < "$1"

stripped_ssn=$(echo $current | tr -d '-')
dob=$(convert_date "$dob")
doh=$(convert_date "$doh")
dot=$(convert_date "$dot")
echo "\"$stripped_ssn\",\"${shop:3:3}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,%er,\"$loan_one\",\"$loan_two\",total,"

read -p "Complete. Press ENTER to exit."
