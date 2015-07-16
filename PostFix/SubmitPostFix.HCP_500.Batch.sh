#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

project="HCP_500"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.PostFix.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=1
max_shadow_number=8

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir:8080"

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting RestingStateStats job for subject: ${subject}"
		echo " Using data server: ${data_server}"
		echo "--------------------------------------------------------------------------------"
		
		./SubmitPostFix.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--server=${server} \
			--project=${project} \
			--subject=${subject}
		
		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	else

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Skipping subject: ${subject}"
		echo "--------------------------------------------------------------------------------"

	fi

done
