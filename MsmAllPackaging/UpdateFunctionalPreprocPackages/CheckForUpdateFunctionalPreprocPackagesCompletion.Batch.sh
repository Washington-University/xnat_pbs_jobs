#!/bin/bash

if [ -z "${SUBJECT_FILES_DIR}" ]; then
	echo "Environment variable SUBJECT_FILES_DIR must be set!"
	exit 1
fi

data_root="/HCP"
project="${1}"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.CheckUpdateFunctionalPreprocPackagesCompletion.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

rm -f ${project}.complete.status
rm -f ${project}.incomplete.status

for subject in ${subjects} ; do
	if [[ ${subject} != \#* ]]; then
		./CheckForUpdateFunctionalPreprocPackagesCompletion.sh \
			--project=${project} \
			--archive-root="${data_root}/hcpdb/archive/${project}/arc001" \
			--subject=${subject} \
			--output-dir="${data_root}/hcpdb/packages/PostMsmAll/${project}"
	fi
done
