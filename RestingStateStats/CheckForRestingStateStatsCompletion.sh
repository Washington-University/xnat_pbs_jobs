#!/bin/bash

#ARCHIVE_ROOT="/data/hcpdb/archive"
ARCHIVE_ROOT="/HCP/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"
PIPELINE_VERSION="v3.13.1"

usage() {
	echo "Usage information TBW"
}

get_options() {
    local arguments=($@)

    # initialize global output variables
    unset g_project
	unset g_subject
	unset g_details
	g_details="FALSE"
	
    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --help)
                usage
                exit 1
                ;;
            --project=*)
                g_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
                g_subject=${argument/*=/""}
                index=$(( index + 1 ))
				;;
			--details)
				g_details="TRUE"
				index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                usage
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z ${g_project} ]; then
        echo "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z ${g_subject} ]; then
        echo "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ "${error_count}" -gt 0 ]; then
		usage
		exit 1
	fi
}

main() {

	get_options $@

	tmp_file="${g_project}.${g_subject}.tmp"

	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	subject_complete="TRUE"

	presentDir=`pwd`
	archiveDir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	#echo "archiveDir: ${archiveDir}"

	scans="rfMRI_REST1_LR"
	scans+=" rfMRI_REST1_RL"
	scans+=" rfMRI_REST2_LR"
	scans+=" rfMRI_REST2_RL"

	#echo "scans: ${scans}"

	for scan in ${scans} ; do
		# does preproc Resource exist
		preproc_resource_dir=${archiveDir}/RESOURCES/${scan}_preproc
		if [ -d "${preproc_resource_dir}" ] ; then

			# does Resting State States Resource exist

			resourceDir=${archiveDir}/RESOURCES/${scan}_RSS
			if [ -d "${resourceDir}" ] ; then
				resource_exists="TRUE"
			else
				resource_exists="FALSE"
				subject_complete="FALSE"
			fi
		
			all_files_exist="TRUE"

			check_dir="${resourceDir}/MNINonLinear/Results/${scan}"
			check_prefix="${check_dir}/${scan}"

			file_suffixes=""
			file_suffixes+=" _Atlas_hp2000_clean_bias.dscalar.nii"
			file_suffixes+=" _Atlas_hp2000_clean_vn.dscalar.nii"
			file_suffixes+=" _Atlas_stats.dscalar.nii"
			file_suffixes+=" _Atlas_stats.txt"
			file_suffixes+=" _CSF.txt"
			file_suffixes+=" _WM.txt"

			for suffix in ${file_suffixes} ; do
				filename="${check_prefix}${suffix}"
				
				if [ ! -e "${filename}" ] ; then
					all_files_exist="FALSE"
					subject_complete="FALSE"

					if [ "${g_details}" = "TRUE" ]; then
						echo "Does not exist: ${filename}"
					fi
				fi
			done

			check_dir="${resourceDir}/MNINonLinear/Results/${scan}/RestingStateStats"
			check_prefix="${check_dir}/${scan}"

			file_suffixes=""
			file_suffixes+=" _Atlas_1-2_OrigTCS-HighPassTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_1-2_OrigTCS-HighPassTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_1-5_OrigTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_1-5_OrigTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_1_OrigTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_1_OrigTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_2-3_HighPassTCS-PostMotionTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_2-3_HighPassTCS-PostMotionTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_2-5_HighPassTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_2-5_HighPassTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_2_HighPassTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_2_HighPassTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_3-4_PostMotionTCS-CleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_3-4_PostMotionTCS-CleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_3-5_PostMotionTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_3-5_PostMotionTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_3_PostMotionTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_3_PostMotionTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_4-5_CleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_4-5_CleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_4-6_CleanedTCS-WMCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_4-6_CleanedTCS-WMCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_4-7_CleanedTCS-CSFCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_4-7_CleanedTCS-CSFCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_4-8_CleanedTCS-WMCSFCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_4-8_CleanedTCS-WMCSFCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_4_CleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_4_CleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_5_UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_5_UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_6-5_WMCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_6-5_WMCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_6_WMCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_6_WMCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_7-5_CSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_7-5_CSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_7_CSFCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_7_CSFCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_8-5_WMCSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_8-5_WMCSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_8_WMCSFCleanedTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_8_WMCSFCleanedTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_9_StructNoiseTCS_QC_Summary_Plot.png"
			file_suffixes+=" _Atlas_9_StructNoiseTCS_QC_Summary_Plot_z.png"
			file_suffixes+=" _Atlas_CleanedCSFtc.txt"
			file_suffixes+=" _Atlas_CleanedMGT.txt"
			file_suffixes+=" _Atlas_CleanedWMtc.txt"
			file_suffixes+=" _Atlas_HighPassMGT.txt"
			file_suffixes+=" _Atlas_NoiseMGT.txt"
			file_suffixes+=" _Atlas_OrigMGT.txt"
			file_suffixes+=" _Atlas_PostMotionMGT.txt"
			file_suffixes+=" _Atlas_UnstructNoiseMGT.txt"
			
			for suffix in ${file_suffixes} ; do
				filename="${resourceDir}/MNINonLinear/Results/${scan}/RestingStateStats/${scan}${suffix}"

				if [ ! -e "${filename}" ] ; then
					all_files_exist="FALSE"
					subject_complete="FALSE"

					if [ "${g_details}" = "TRUE" ]; then
						echo "Does not exist: ${filename}"
					fi
				fi
			done

			echo -e "${g_subject}\t\t${g_project}\t${PIPELINE_VERSION}\t${scan}_RSS\t${resource_exists}\t${all_files_exist}" >> ${tmp_file}

		else
			echo -e "${g_subject}\t\t${g_project}\t${PIPELINE_VERSION}\t${scan}_RSS\t---\t---" >> ${tmp_file}
		fi

	done

	if [ "${subject_complete}" = "TRUE" ]; then
		cat ${tmp_file} >> ${g_project}.complete.status
	else
		cat ${tmp_file} >> ${g_project}.incomplete.status
	fi
	cat ${tmp_file}
	rm -f ${tmp_file}
}

main $@
