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

project="HCP_1200"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.DeDriftAndResample.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=3
max_shadow_number=3

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir:8080"

		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting DeDriftAndResample job for subject: ${subject}"
		echo " Using server: ${server}"
		echo " Submission delayed until ${delay} minutes from now"
		echo "--------------------------------------------------------------------------------"
		
#		at now + ${delay} minutes <<EOF 
			/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DeDriftAndResample/SubmitDeDriftAndResample.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--server=${server} \
			--project=${project} \
			--subject=${subject}
#EOF

#		delay=$((delay + interval))

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi

done
