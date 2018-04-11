#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	inform "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

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

echo "If you do not specify a seed, then a blank seed specification"
echo "will be passed to the pipeline and the default random number"
echo "generator seed will be used."
printf "Random Number Generator Seed []: "
read seed

DEFAULT_PROJECT=HCP_Staging

echo "If you do not specify a project, then the default project: ${DEFAULT_PROJECT}"
echo "will be used."
printf "project: "
read project

if [ -z "${project}" ]; then
	project=${DEFAULT_PROJECT}
fi

subject_file_name="${SUBJECT_FILES_DIR}/${project}.StructuralPreprocessingHCP.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}

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
