#!/bin/bash

#ARCHIVE_ROOT="/data/hcpdb/archive"
ARCHIVE_ROOT="/HCP/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"
PIPELINE_VERSION="v3.7.1"

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
		# does FIX resource exist
		fix_resource_dir=${archiveDir}/RESOURCES/${scan}_FIX
		if [ -d "${fix_resource_dir}" ] ; then

			# does PostFix resource exist
			resourceDir=${archiveDir}/RESOURCES/${scan}_PostFix
			if [ -d "${resourceDir}" ] ; then
				resource_exists="TRUE"
			else
				resource_exists="FALSE"
				subject_complete="FALSE"
			fi

			check_dir="${resourceDir}/MNINonLinear/Results/${scan}"
			files=""
			files+="${check_dir}/${g_subject}_${scan}_ICA_Classification_dualscreen.scene"
			files+=" ${check_dir}/${g_subject}_${scan}_ICA_Classification_singlescreen.scene"
			files+=" ${check_dir}/ReclassifyAsNoise.txt"
			files+=" ${check_dir}/ReclassifyAsSignal.txt"
			files+=" ${check_dir}/${scan}_Atlas_hp2000.dtseries.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/Noise.txt"
			files+=" ${check_dir}/${scan}_hp2000.ica/Signal.txt"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/ICAVolumeSpace.txt"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/mask.nii.gz"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_FTmix.sdseries.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_mix.sdseries.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_oIC.dscalar.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_oIC.dtseries.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_oIC_vol.dscalar.nii"
			files+=" ${check_dir}/${scan}_hp2000.ica/filtered_func_data.ica/melodic_oIC_vol.dtseries.nii"
			
			all_files_exist="TRUE"
			for filename in ${files} ; do
			
				if [ ! -e "${filename}" ] ; then
					all_files_exist="FALSE"
					subject_complete="FALSE"

					if [ "${g_details}" = "TRUE" ]; then
						echo "Does not exist: ${filename}"
					fi
				fi
			done

			#echo -e "\tScan: ${scan}\tResource Exists: ${resource_exists}\tFiles Exist: ${all_files_exist}" >> ${tmp_file}
			echo -e "${g_subject}\t\t${g_project}\t${PIPELINE_VERSION}\t${scan}_PostFix\t${resource_exists}\t${all_files_exist}" >> ${tmp_file}


		else
			#echo -e "\tScan: ${scan}\tFIX processed scan DOES NOT EXIST" >> ${tmp_file}
			echo -e "${g_subject}\t\t${g_project}\t${PIPELINE_VERSION}\t${scan}_PostFix\t---\t---" >> ${tmp_file}
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
