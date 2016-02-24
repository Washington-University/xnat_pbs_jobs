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

project="HCP_Staging"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.FunctionalPreprocessingHCP.subjects"
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
		echo " Submitting FSFs Creationg jobs for subject: ${subject}"
		echo " Using put-server: ${server}"
		echo "--------------------------------------------------------------------------------"
		
		/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/FunctionalPreprocessingHCP/SubmitCreateFSFs.OneSubject.sh \
			--user=${userid} \
			--password=${password} \
			--project=${project} \
			--subject=${subject} \
			--put-server=${server}

		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi

	fi

done
