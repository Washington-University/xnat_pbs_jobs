#!/bin/bash

DEBUG_MODE="FALSE"
#DEBUG_MODE="TRUE"

inform()
{
	local msg=${1}
	echo "CheckForAddResolutionPatchHCP7TCompletion.sh: ${msg}"
}

debug_msg()
{
	local msg=${1}
	if [ "${DEBUG_MODE}" = "TRUE" ] ; then
		msg="DEBUG: ${msg}"
		inform "${msg}"
	fi
}

if [ "${COMPUTE}" = "NRG" ] ; then
	HCP_DATA_ROOT="/data"
elif [ "${COMPUTE}" = "CHPC" ] ; then
	HCP_DATA_ROOT="/HCP"
else
	inform "COMPUTE environment '${COMPUTE}' is current not supported"
	inform "Exiting with non-zero status (Unsuccessful execution)"
	exit 1
fi

ARCHIVE_ROOT="${HCP_DATA_ROOT}/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"

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

main() 
{
	get_options $@

	tmp_file="${g_project}.${g_subject}.tmp"
	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	subject_complete="TRUE"
	all_files_newer_than_patch_starttime="N/A"

	presentDir=`pwd`
	archiveDir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"

	# does Structural_preproc_supplemental exist

	struct_preproc_supplemental_dir=${archiveDir}/RESOURCES/Structural_preproc_supplemental

	if [ -d "${struct_preproc_supplemental_dir}" ] ; then
		resource_exists="TRUE"
		resource_date=$(stat -c %y ${struct_preproc_supplemental_dir})
		resource_date=${resource_date%%\.*}
	else
		resource_exists="FALSE"
		resource_date="N/A"
		subject_complete="FALSE"
	fi

	files=""

	check_dir="${struct_preproc_supplemental_dir}"
	starttime_file="${check_dir}/AddResolutionPatchHCP7T.starttime"

	if [ -e "${starttime_file}" ]; then
		starttime_date=$(stat -c %y ${starttime_file})
		starttime_date=${starttime_date%%\.*}

		check_dir="${struct_preproc_supplemental_dir}/MNINonLinear/fsaverage_LR59k"

		files+=" ${check_dir}/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
		
		check_dir="${struct_preproc_supplemental_dir}/T1w/fsaverage_LR59k"

		files+=" ${check_dir}/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
		files+=" ${check_dir}/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
		

		all_files_exist="TRUE"
		all_files_newer_than_patch_starttime="TRUE"
		for filename in ${files} ; do

			# echo "Checking file: ${filename}"
			
			if [ ! -e "${filename}" ] ; then
				all_files_exist="FALSE"
				subject_complete="FALSE"
				
				if [ "${g_details}" = "TRUE" ]; then
					echo "Does not exist: ${filename}"
				fi
			else
				# file exists
				file_date=$(stat -c %y ${filename})
				file_date=${file_date%%\.*}

				starttime_timestamp=$(date -d "${starttime_date}" +%s)
				file_timestamp=$(date -d "${file_date}" +%s)

				if [ ${file_timestamp} -lt ${starttime_timestamp} ]; then
					# file is not newer than the start of the patch run
					# so the file cannot be right
					all_files_newer_than_patch_starttime="FALSE"
					subject_complete="FALSE"
				fi
			fi
			
		done

	else

		# starttime_file does not exist
		all_files_exist="FALSE"
		subject_complete="FALSE"

		if [ "${g_details}" = "TRUE" ]; then
			echo "Start time file does not exist: ${starttime_file}"
		fi
		
	fi

	echo -e "${g_subject}\t${g_project}\tStructural_preproc_supplemental\t${resource_exists}\t${resource_date}\t${all_files_exist}\t${all_files_newer_than_patch_starttime}" >> ${tmp_file}


	if [ "${subject_complete}" = "TRUE" ]; then
		cat ${tmp_file} >> ${g_project}.complete.status
	else
		cat ${tmp_file} >> ${g_project}.incomplete.status
	fi
	cat ${tmp_file}
	rm -f ${tmp_file}
}

main $@
