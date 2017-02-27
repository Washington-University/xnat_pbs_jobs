#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

project="HCP_1200"
subject_file_name="${project}.IcaFixPackaging.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=1
max_shadow_number=8

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir"

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting ICA+FIX Packaging job for subject: ${subject}"
		echo "--------------------------------------------------------------------------------"

		${HOME}/pipeline_tools/xnat_pbs_jobs/IcaFixProcessingHCP/SubmitIcaFixPackagingHCP.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--server=${server} \
			--project=${project} \
			--subject=${subject} 

		shadow_number=$((shadow_number+1))
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi
	
done
