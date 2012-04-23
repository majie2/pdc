#! /bin/bash
# processes payroll
# arg 1 : text file containing all deduction details
#       : pdf save as plain text
# arg 2 : directory of ee roster txt files, pdfs must be saved manually as plain text
# arg 3 : directory of pay detail pdfs

ERR_COUNT_CENSUS_NA=0
ERR_COUNT_CODE_NA=0
ERR_COUNT_ADDRESS_CORRUPT=0

OUTFILE="/home/$(whoami)/output.csv"
rm ${OUTFILE}

if [ ! -e "${1}" ]
then
    echo "File does not exist: $1"
    exit 0
fi

if [ ! -d "${2}" ]
then
    echo "Directory does not exist: $2"
    exit 0
fi

if [ ! -d "${3}" ]
then
    echo "Directory does not exist: $3"
    exit 0
fi

echo "Processing pay detail pdfs..."

if [ -e "${3}/all.txt" ]
then
    rm "${3}/all.txt"
fi

if [ -e "${2}/all.txt" ]
then
    rm "${2}/all.txt"
fi

# convert all pay detail pdfs to txt files
for f in "${3}"*.pdf
do
    pdftotext "${f}" "${f}.txt"
done

# concatenate all converted files into one file
for f in "${3}/"*.txt
do
    cat "${f}" >> "${3}/all.txt"
done

echo "Processing employee rosters..."

for f in "${2}/"*.txt
do
    cat "${f}" >> "${2}/all.txt"
done

# convert MM/DD/YY to MMDDYYYY
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
        
        if [ $day -lt 10 ]
        then
            day="0$day"
        fi
        
        echo "${month}${day}${year}"
    fi
} 

# don't print anything since we haven't gathered any information
print_info=false

# current ssn is NOTHING!
current="null"

while read line
do
    # tests if the line starts with a ssn
    if [ "${line:3:1}" = "-" ] && [ "${line:6:1}" = "-" ]
    then
        ssn=$(echo ${line:0:11})
        
        # print information if a new ssn pops up
        if [ "$ssn" != "$current" ]
        then
            # make sure the ssn actually exists
            if [ "$current" != "null" ]
            then
                # clean up the ssn
                stripped_ssn=$(echo $current | tr -d '-')
                
                # clean up the dates
                dob=$(convert_date "$dob")
                doh=$(convert_date "$doh")
                dot=$(convert_date "$dot")
                
                if [ ! "${#dob}" -gt 1 ] || [ ! "${#doh}" -gt 1 ]
                then
                    echo "Date(s) missing for $stripped_ssn"
                    echo "DOB: ${dob}"
                    echo "DOH: ${doh}"
                fi
                
                # print everything
                echo "\"$stripped_ssn\",\"${shop:3:3}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,,\"$loan_one\",\"$loan_two\",,\"$dob\",\"$doh\",\"$dot\",\"$address\",\"$city\",\"$state\",\"$zip\"" >> ${OUTFILE}
                
                # reset all the variables just to make sure
                dob=""
                doh=""
                dot=""
                address=""
                city=""
                state=""
                zip=""
                gross_pay=""
                gross_pay_key=""
                gross_pay_line=""
            fi
            
            # set current to the most recent ssn (hook to start gathering data)
            current=$(echo $ssn)
            
            # find census information by ssn
            census=$(grep "$ssn" "${2}/all.txt" | tr -d '\r')
            
            # newlines are annoying eh?
            census=$(echo $census)
            
            address_extract=$(echo $census | cut -f2 -d',' | cut -f3 -d'-')
            address_count=$(echo $address_extract | wc -w)
            
            if [ "${#census}" -gt 1 ]
            then
                if [ "${census: -1}" == "Y" ]
                then
                    #active
                    address=$(echo $address_extract | cut -f3-${address_count} -d' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
                    dob=$(echo $census | cut -f3 -d',' | cut -f4 -d' ')
                    doh=$(echo $census | cut -f3 -d',' | cut -f5 -d' ')
                    dot=""
                elif [ "${census: -1}" == "N" ]
                then
                    #not active
                    address=""
                elif [[ "${census: -1}" =~ [0-9] ]]
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
            else
                let ERR_COUNT_CENSUS_NA=${ERR_COUNT_CENSUS_NA}+1
            fi
            
            # check if the address has a date in it
            if [[ "${address}" == *"/"* ]]
            then
                address=$(echo $address_extract | cut -f2-${address_count} -d' ' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
                
                let count_blocks=$(echo $address | grep -o '/' | wc -l)+1
                let address_1_key=$(echo $address | cut -f1 -d'/' | wc -w)-1
                address_2_key=$(echo $address | cut -f${count_blocks} -d'/' | wc -w)
                
                address_clean_1=$(echo $address | cut -f1 -d'/' | cut -f1-${address_1_key} -d' ')
                address_clean_2=$(echo $address | cut -f${count_blocks} -d'/' | cut -f2-${address_2_key} -d' ')
                
                echo "There is a problem with this address: ${address}"
                echo "Changing to: ${address_clean_1} ${address_clean_2}"
                
                address="${address_clean_1} ${address_clean_2}"
                
                let ERR_COUNT_ADDRESS_CORRUPT=${ERR_COUNT_ADDRESS_CORRUPT}+1
            fi
            
            city_end_key=$(echo $address | wc -w)
            
            if [[ "${address}" == *"El Sobrante" ]] || [[ "${address}" == *"San Leandro" ]] || [[ "${address}" == *"San Jose" ]] || [[ "${address}" == *"Garden Grove" ]]
            then
                let city_start_key=${city_end_key}-1
                let add_end_key=${city_start_key}-1
            else
                city_start_key=${city_end_key}
                let add_end_key=${city_start_key}-1
            fi
            
            if [ "${#address}" -gt 1 ]
            then
                city=$(echo $address | cut -f${city_start_key}-${city_end_key} -d' ')
                address=$(echo $address | cut -f1-${add_end_key} -d' ')
            fi
            
            state=$(echo $census | cut -f3 -d',' | cut -f2 -d' ')
            zip=$(echo $census| cut -f3 -d',' | cut -f3 -d' ')

            #reset
            middle_test=$(echo $line | cut -f4 -d' ')
            
            if [[ "$middle_test" =~ [0-9] ]]
            then
                location=0
                first_name_extract=$(echo $line | cut -f3 -d' ')
                shop=$(echo $middle_test)
            else
                location=1
                first_name_extract=$(echo $line | cut -f3-4 -d' ')
                shop=$(echo $line | cut -f5 -d' ')
            fi
            
            first_name=$(echo $first_name_extract | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            last_name=$(echo $line | cut -f2 -d' ' | cut -f1 -d',' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            deduction=""
            loan_one=""
            loan_two=""
            
            let code_location=$location+7
            let amnt_location=$location+6
            
            gross_pay_line=$(grep -n -m 1 "xxx-xx-${current: -4}" "${3}/all.txt")
            
            if [[ "${gross_pay_line}" == *"Gross Pay"* ]]
            then
                gross_pay_key=$(echo $gross_pay_line | grep -b -o "Gross Pay" | cut -f1 -d:)
                gross_pay=$(echo ${gross_pay_line:${gross_pay_key}} | cut -f3 -d' ')
            else
                gross_pay_key=$(echo $gross_pay_line | cut -f1 -d:)
                let gross_pay_key=${gross_pay_key}+2
                gross_pay=$(sed "${gross_pay_key}q;d" "${3}/all.txt" | cut -f3 -d' ')
            fi
        fi
        
        # get the code
        code=$(echo $line | cut -f${code_location} -d' ')
        
        # determine the deduction type by code
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
            let ERR_COUNT_CODE_NA=${ERR_COUNT_CODE_NA}+1
        fi
    fi
done < "$1"

stripped_ssn=$(echo $current | tr -d '-')
dob=$(convert_date "$dob")
doh=$(convert_date "$doh")
dot=$(convert_date "$dot")
echo "\"$stripped_ssn\",\"${shop:3:3}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,,\"$loan_one\",\"$loan_two\",total,\"$dob\",\"$doh\",\"$dot\",\"$address\",\"$city\",\"$state\",\"$zip\"" >> ${OUTFILE}

if [ $ERR_COUNT_CENSUS_NA -gt 0 ] || [ $ERR_COUNT_CODE_NA -gt 0 ] || [ $ERR_COUNT_ADDRESS_CORRUPT -gt 0 ]
then
    echo "There were errors:"
    echo "Census not found: ${ERR_COUNT_CENSUS_NA}"
    echo "Deduction code not found: ${ERR_COUNT_CODE_NA}"
    echo "Address contained illegal characters: ${ERR_COUNT_ADDRESS_CORRUPT}"
fi

cp ${OUTFILE} "/mnt/401FILES/Rserection/output.csv"
