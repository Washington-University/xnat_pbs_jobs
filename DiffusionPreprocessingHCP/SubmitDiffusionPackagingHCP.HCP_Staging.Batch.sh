#!/bin/bash

project="HCP_Staging"
subject_file_name="${project}.DiffusionPackagingHCP.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

for subject in ${subjects} ; do

	if [[ ${subject} != \#* ]]; then

 		echo ""
		echo "--------------------------------------------------------------------------------"
		echo " Submitting Diffusion Packaging job for subject: ${subject}"
		echo "--------------------------------------------------------------------------------"

		${XNAT_PBS_JOBS}/DiffusionPreprocessingHCP/SubmitDiffusionPackagingHCP.OneSubject.sh \
			--project=${project} \
			--subject=${subject} 

	fi
	
done
