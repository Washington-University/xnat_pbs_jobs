#!/bin/bash

project="HCP_Staging_RT"
subject_file_name="${project}.CheckUpdateTaskAnalysisPackagesCompletion.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do
	if [[ ${subject} != \#* ]]; then
		./CheckForUpdateTaskAnalysisPackagesCompletion.sh \
			--archive-root="/HCP/hcpdb/archive/${project}/arc001" \
			--subject=${subject} \
			--output-dir="/HCP/hcpdb/packages/PostMsmAll/${project}"
	fi
done
