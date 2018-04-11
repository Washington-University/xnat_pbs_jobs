#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "Environment variable XNAT_PBS_JOBS must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MIN_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MIN_SHADOW must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MAX_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MAX_SHADOW must be set!"
	exit 1
fi

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

project="HCP_Staging_RT"
subject_file_name="${project}.StructuralPackagingHCP.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

shadow_number=${start_shadow_number}

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

		server="db-shadow${shadow_number}.nrg.mir"

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting Structural Packaging job for subject: ${subject}"
		echo "--------------------------------------------------------------------------------"

		${XNAT_PBS_JOBS}/StructuralPreprocessingHCP/SubmitStructuralPackagingHCP.OneSubject.sh \
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
