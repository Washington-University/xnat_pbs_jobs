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

echo "If you do not specify a seed, then a blank seed specification"
echo "will be passed to the pipeline and the default random number"
echo "generator seed will be used."
printf "Random Number Generator Seed []: "
read seed

project="HCP_Staging"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.StructuralPreprocessingHCP.subjects"
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
		echo " Submitting Structural Preprocessing job for subject: ${subject}"
		echo " Using server: ${server}"
		echo "--------------------------------------------------------------------------------"

		${HOME}/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/SubmitStructuralPreprocessingHCP.OneSubject.sh \
			--user=${userid} \
			--put-server=${server} \
			--project=${project} \
			--subject=${subject} \
			--seed=${seed} \
			--password=${password}

		#delay=$((delay + interval))
		
		shadow_number=$((shadow_number+1))
		
		if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
			shadow_number=${start_shadow_number}
		fi
		
	fi
	
done
