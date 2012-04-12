#! /bin/bash
# parses text extract of rs deduction reports

while read line
do
    payment_date=""
    deduction_amount=""
    deduction_code=""
    deduction_description=""
    check_number=""
            
    if [ "${line:3:1}" = "-" ] && [ "${line:6:1}" = "-" ]
    then
        ssn=$(echo ${line:0:11})
        name=$(echo ${line:12})
        
        first_name=$(echo $name | cut -f2 -d' ' | tr -d '\r')
        last_name=$(echo $name | cut -f1 -d',')        
    elif [[ "${line:0:1}" =~ [0-9] ]]
    then
        check_number=$(echo $line | cut -f1 -d' ')
        
        if [ "${#check_number}" -eq 8 ] && [[ "$check_number" != *"/"* ]]
        then
            payment_date=$(echo $line | cut -f2 -d' ')
            deduction_amount=$(echo $line | cut -f3 -d' ')
            deduction_code=$(echo $line | cut -f4 -d' ')
            
            if [[ "$line" == *Deduction* ]]
            then
                deduction_description="Deduction" #$(echo ${line: -17})
                
                echo "${ssn},300,$last_name,$first_name,,4k,$deduction_amount,PS,,,"
            elif [[ "$line" == *Loan* ]]
            then
                deduction_description="Loan" #$(echo ${line: -15})
                
                echo "${ssn},300,$last_name,$first_name,,4k,,PS,,$deduction_amount,"
            fi
            
            #echo "$ssn: frst $first_name"
            #echo "$ssn: last $last_name"
            #echo "$ssn: Chk# $check_number"
            #echo "$ssn: Date $payment_date"
            #echo "$ssn: Damt $deduction_amount"
            #echo "$ssn: Code $deduction_code"
            #echo "$ssn: Desc $deduction_description"
        fi
    fi
done < $1
