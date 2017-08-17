#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

subject_file_name="CheckForFunctionalPreprocessingHCP7TCompletion.Batch.subjects"
inform "Retrieving subject list from ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

rm -f *.complete.status
rm -f *.incomplete.status

for subject in ${subjects} ; do
	if [[ ${subject} != \#* ]]; then

		#project=HCP_Staging_7T
		project=HCP_1200

		#./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=${project} --subject=${subject} --post-patch # --details
		#./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=${project} --subject=${subject} # --details
		#./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=${project} --subject=${subject} --details
		./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=${project} --subject=${subject} --post-patch

	fi

done
