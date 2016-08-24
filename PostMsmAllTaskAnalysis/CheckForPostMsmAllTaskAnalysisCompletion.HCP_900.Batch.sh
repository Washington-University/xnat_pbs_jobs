#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

project="HCP_900"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.PostMsmAllTaskAnalysis.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do
	if [[ ${subject} != \#* ]]; then
		./CheckForPostMsmAllTaskAnalysisCompletion.sh --project=${project} --subject=${subject} # --details
	fi
done
