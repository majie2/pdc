#! /bin/bash
# processes payroll
# arg 1 : text file containing all deduction details
#       : pdf save as plain text
# arg 2 : directory of ee roster txt files, pdfs must be saved manually as plain text
# arg 3 : directory of pay detail pdfs
# arg 4 : config file for ps

ERR_COUNT_CENSUS_NA=0
ERR_COUNT_CODE_NA=0
ERR_COUNT_ADDRESS_CORRUPT=0
ERR_COUNT_MULTIPLE_GROSS=0

OUTFILE="barrett_sc.csv"
#OUTFILE="/mnt/pd/Rserection/process/barrett_sc.csv"
rm ${OUTFILE}

PS_CONFIG="$4"

# system variables
BOLD_ON="\033[1m"
BOLD_OFF="\033[0m"
RED='\E[31;47m'
BLUE='\E[36;40m'
GREEN='\E[32;40m'

clear

echo -e "\n##################################################"
echo "#                                                #"
echo "# rsdedrepsc2.sh                                 #"
echo "#                                                #"
echo "# author  : josef kelly                          #"
echo "# license : mit                                  #"
echo "# version : 1.2                                  #"
echo "#                                                #"
echo "##################################################"

warning_prompt () {
    echo -e $RED
    echo -e "${BOLD_ON}${1}${BOLD_OFF}"
    tput sgr0
}

directory_exists () {
    if [ ! -d "${1}" ]
    then
        warning_prompt "Directory does not exist: $1"
        echo "Exiting..."
        exit 0
    fi
}

file_exists () {
    if [ ! -e "${1}" ]
    then
        warning_prompt "File does not exist: $1"
        echo "Exiting..."
        exit 0
    fi
}

remove_if_exists () {
    if [ -e "${1}" ]
    then
        rm "${1}"
    fi
}

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
        
        echo "${month}${day}${year}"
    fi
}

# check if files & directories exist
file_exists "$1"
file_exists "$4"
directory_exists "$2"
directory_exists "$3"

# remove leftover concatenated files
remove_if_exists "${3}/all.txt"
remove_if_exists "${2}/all.txt"

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

for f in "${2}/"*.txt
do
    cat "${f}" >> "${2}/all.txt"
done

# don't print anything since we haven't gathered any information
print_info=false

# current ssn is NOTHING!
current="null"
COUNT_RECORDS=0
TARGET_RECORDS=$(grep '[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}' "${1}" | wc -l)

while read line
do
    # does the line contain a ssn
    contains_ssn=$(echo $line | grep -b -o '[0-9]\{3\}-[0-9]\{2\}-[0-9]\{4\}')
    
    if [ "${#contains_ssn}" -gt 0 ]
    then
        offset=$(echo $contains_ssn | cut -f1 -d:)
    fi
    
    # tests if the line starts with a ssn
    if [ "${line:3:1}" = "-" ] && [ "${line:6:1}" = "-" ]
    then
        ssn=$(echo ${line:0:11})
        let COUNT_RECORDS=$COUNT_RECORDS+1
        
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
                
                if [ ! "${#dob}" -gt 1 ]
                then
                    echo -e "\n${RED}Date of Birth missing for: $current"
                elif [ ! "${#doh}" -gt 1 ]
                then
                    echo -e "\n${RED}Date of Hire missing for: $current"
                fi
                
                tput sgr0
                
                ps_percent=$(grep "${shop}" "$PS_CONFIG" | cut -f2 -d' ' | tr -d '\r')
                pay_sanitized=$(echo $gross_pay | tr -d ',')
                ps_amount=$(echo "$pay_sanitized * $ps_percent" | bc)
                
                # print everything
                echo "\"$stripped_ssn\",\"${shop}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,$ps_amount,\"$loan_one\",\"$loan_two\",,\"$dob\",\"$doh\",\"$dot\",\"$address\",\"$city\",\"$state\",\"$zip\"" >> ${OUTFILE}
                
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
                ps_percent=""
                ps_amount=""
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
                
                echo -e "\n${RED}There is a problem with this address: ${address}"
                echo -e "${GREEN}Changing to: ${address_clean_1} ${address_clean_2}"
                tput sgr0
                
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
            shop="300"

            #reset
            middle_test=$(echo $line | cut -f4 -d' ')
            
            if [[ "$middle_test" =~ [0-9] ]]
            then
                location=0
                first_name_extract=$(echo $line | cut -f3 -d' ')
            else
                location=1
                first_name_extract=$(echo $line | cut -f3-4 -d' ')
            fi
            
            first_name=$(echo $first_name_extract | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            last_name=$(echo $line | cut -f2 -d' ' | cut -f1 -d',' | sed 's/.*/\L&/; s/[a-z]*/\u&/g')
            deduction=""
            loan_one=""
            loan_two=""
            
            let code_location=$location+6
            echo "CODE LOC: ${code_location}"
            let amnt_location=$location+5
            
            #gross_pay_line=$(grep -n -m 1 "xxx-xx-${current: -4}" "${3}/all.txt")
            gross_pay_count=$(grep "xxx-xx-${current: -4}" "${3}/all.txt" | wc -l)
            gross_pay_line=$(grep -m 1 -A 2 -B 2 "xxx-xx-${current: -4}" "${3}/all.txt" | grep "Gross Pay")
            
            if [ "${#gross_pay_line}" -gt 0 ]
            then
                gross_pay_key=$(echo $gross_pay_line | grep -b -o "Gross Pay" | cut -f1 -d:)
                gross_pay=$(echo ${gross_pay_line:${gross_pay_key}} | cut -f3 -d' ')
            fi
            
            #if [[ "${gross_pay_line}" == *"Gross Pay"* ]]
            #then
            #    gross_pay_key=$(echo $gross_pay_line | grep -b -o "Gross Pay" | cut -f1 -d:)
            #    gross_pay=$(echo ${gross_pay_line:${gross_pay_key}} | cut -f3 -d' ')
            #else
            #    gross_pay_key=$(echo $gross_pay_line | cut -f1 -d:)
            #    let gross_pay_key=${gross_pay_key}+2
            #    gross_pay=$(sed "${gross_pay_key}q;d" "${3}/all.txt" | cut -f3 -d' ')
            #fi
            
            # i'll add a fix later that just bloody finds it correctly
            if [[ "$gross_pay" =~ [a-z] ]]
            then
                echo -e "\n${RED}There is a problem with the gross pay for: $current"
                echo -e "${GREEN}Gross pay amount: $gross_pay"
                tput sgr0
            fi
            
            if [ "$gross_pay_count" -gt 1 ]
            then
                echo -e "\n${RED}Found multiple pay detail entries for: $current"
                echo -e "${GREEN}Using gross pay for first match - amount: $gross_pay"
                tput sgr0
                let ERR_COUNT_MULTIPLE_GROSS=${ERR_COUNT_MULTIPLE_GROSS}+1
                
                gross_pay_additional_line=$(grep -A 2 -B 2 "xxx-xx-${current: -4}" "${3}/all.txt" | grep "Gross Pay" | sed -n "2p")
                gross_pay_additional_key=$(echo $gross_pay_additional_line | grep -b -o "Gross Pay" | cut -f1 -d:)
                gross_pay_additional=$(echo ${gross_pay_additional_line:${gross_pay_additional_key}} | cut -f3 -d' ')
                
                echo "Other amount: $gross_pay_additional"
            fi
        fi
        
        # get the code
        code=$(echo $line | cut -f${code_location} -d' ')
        echo "CODE: ${code}"
        
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

if [ ! "${#dob}" -gt 1 ]
then
    echo -e "\n${RED}Date of Birth missing for: $current"
elif [ ! "${#doh}" -gt 1 ]
then
    echo -e "\n${RED}Date of Hire missing for: $current"
fi

tput sgr0

ps_percent=$(grep "${shop}" "$PS_CONFIG" | cut -f2 -d' ' | tr -d '\r')
pay_sanitized=$(echo $gross_pay | tr -d ',')
ps_amount=$(echo "$pay_sanitized * $ps_percent" | bc)

echo "\"$stripped_ssn\",\"${shop}\",\"$last_name\",\"$first_name\",\"${gross_pay}\",4K,\"$deduction\",PS,$ps_amount,\"$loan_one\",\"$loan_two\",,\"$dob\",\"$doh\",\"$dot\",\"$address\",\"$city\",\"$state\",\"$zip\"" >> ${OUTFILE}

warning_prompt "#  ERROR  #"
echo "Census not found: ${ERR_COUNT_CENSUS_NA}"
echo "Deduction code not found: ${ERR_COUNT_CODE_NA}"
echo "Address contained illegal characters: ${ERR_COUNT_ADDRESS_CORRUPT}"
echo "Participants with multiple details: ${ERR_COUNT_MULTIPLE_GROSS}"

if [ ! "$COUNT_RECORDS" -eq "$TARGET_RECORDS" ]
then
    echo "$TARGET_RECORDS found, $COUNT_RECORDS added. Check totals."
fi

read -p "Press ENTER to exit."
