#!/bin/bash

data_root="/HCP"
project="${1}"
subject_file_name="${project}.CheckUpdateFunctionalPreprocPackagesCompletion.subjects"
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
