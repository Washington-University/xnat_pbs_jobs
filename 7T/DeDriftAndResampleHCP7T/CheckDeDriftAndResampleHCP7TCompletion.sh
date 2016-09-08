#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

check_file_exists() 
{
	local filename=${1}
	if [ ! -e "${filename}" ]; then
		g_all_files_exist="FALSE"
		g_subject_complete="FALSE"
		if [ "${g_details}" = "TRUE" ]; then
			echo "File does not exist: ${filename}"
		fi
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
TESLA_SPEC="_7T"

SCANS_LIST=""
SCANS_LIST+=" REST1_PA "
SCANS_LIST+=" REST2_AP "
SCANS_LIST+=" REST3_PA "
SCANS_LIST+=" REST4_AP "
SCANS_LIST+=" MOVIE1_AP "
SCANS_LIST+=" MOVIE2_PA "
SCANS_LIST+=" MOVIE3_PA "
SCANS_LIST+=" MOVIE4_AP "
SCANS_LIST+=" RETBAR1_AP "
SCANS_LIST+=" RETBAR2_PA "
SCANS_LIST+=" RETCCW_AP "
SCANS_LIST+=" RETCON_PA "
SCANS_LIST+=" RETCW_PA "
SCANS_LIST+=" RETEXP_AP "

RESTING_PREFIX="rfMRI_"
TASK_PREFIX="tfMRI_"

UNPROC_SUFFIX="_unproc"
PREPROC_SUFFIX="_preproc"
FIX_SUFFIX="_FIX"
POSTFIX_SUFFIX="_PostFix"

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_details
	unset g_report_level

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
			--quiet)
				g_report_level="QUIET"
				index=$(( index + 1 ))
                ;;
			--verbose)
				g_report_level="VERBOSE"
				index=$(( index + 1 ))
                ;;
			--report-level=*)
				g_report_level=${argument/*=/""}
				g_report_level="$(echo ${g_report_level} | tr '[:lower:]' '[:upper:]')"
				index=$(( index + 1 ))
                ;;
            *)
                inform "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z "${g_project}" ]; then
        inform "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z "${g_subject}" ]; then
        inform "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ -z "${g_details}" ]; then
		g_details="FALSE"
	fi

	if [ -z "${g_report_level}" ]; then
		g_report_level="NORMAL"
	fi

	if [ "${g_report_level}" != "QUIET" ] && [ "${g_report_level}" != "NORMAL" ] && [ "${g_report_level}" != "VERBOSE" ] ; then
		inform "ERROR: unrecognized report level: ${g_report_level}"
		error_count=$(( error_count + 1 ))
	fi

	if [ "${error_count}" -gt 0 ]; then
		exit 1
	fi
}

verbose_msg()
{
	local msg=${1}
	if [ "${g_report_level}" = "VERBOSE" ] ; then
		msg="VERBOSE: ${msg}"
		inform "${msg}"
	fi
}

is_resting_state_scan()
{
	# first parameter is the variable to populate with "TRUE" or "FALSE"
	# second parameter is the scan specification ot check
	local scan_spec=${2}
	if [[ ${scan_spec} == *REST* ]]; then
		eval "$1='TRUE'"
	else
		eval "$1='FALSE'"
	fi
}

is_movie_scan()
{
	# first parameter is the variable to populate with "TRUE" or "FALSE"
	# second parameter is the scan specification ot check
	local scan_spec=${2}
	if [[ ${scan_spec} == *MOVIE* ]]; then
		eval "$1='TRUE'"
	else
		eval "$1='FALSE'"
	fi
}

is_retinotopy_scan()
{
	# first parameter is the variable to populate with "TRUE" or "FALSE"
	# second parameter is the scan specification ot check
	local scan_spec=${2}
	if [[ ${scan_spec} == *RET* ]]; then
		eval "$1='TRUE'"
	else
		eval "$1='FALSE'"
	fi
}

main()
{
	get_options $@

	start_dir=${PWD}

	tmp_file=${start_dir}/${g_project}.${g_subject}.tmp
	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	g_subject_complete="TRUE"

	archive_dir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	resources_dir="${archive_dir}/RESOURCES"

	for scan in ${SCANS_LIST} ; do

		verbose_msg "scan: ${scan}"

		is_resting_state_scan resting_state_scan ${scan}
		verbose_msg "resting_state_scan: ${resting_state_scan}"

		is_movie_scan movie_scan ${scan}
		verbose_msg "movie_scan: ${movie_scan}"

		is_retinotopy_scan retinotopy_scan ${scan}
		verbose_msg "retinotopy_scan: ${retinotopy_scan}"

		if [ "${resting_state_scan}" = "TRUE" ] ; then
			prefix=${RESTING_PREFIX}
		else
			prefix=${TASK_PREFIX}
		fi

		verbose_msg "prefix: ${prefix}"

		short_unproc_resource_dir=${prefix}${scan}${UNPROC_SUFFIX}
		unproc_resource_dir=${resources_dir}/${short_unproc_resource_dir}
		verbose_msg "unproc_resource_dir: ${unproc_resource_dir}"

		short_preproc_resource_dir=${prefix}${scan}${PREPROC_SUFFIX}
		preproc_resource_dir=${resources_dir}/${short_preproc_resource_dir}
		verbose_msg "preproc_resource_dir: ${preproc_resource_dir}"

		short_fix_resource_dir=${prefix}${scan}${FIX_SUFFIX}
		fix_resource_dir=${resources_dir}/${short_fix_resource_dir}
		verbose_msg "fix_resource_dir: ${fix_resource_dir}"

		short_postfix_resource_dir=${prefix}${scan}${POSTFIX_SUFFIX}
		postfix_resource_dir=${resources_dir}/${short_postfix_resource_dir}

		scan_without_pe_dir=${scan%_*}
		verbose_msg "scan_without_pe_dir: ${scan_without_pe_dir}"

		pe_dir=${scan#*_}
		verbose_msg "pe_dir: ${pe_dir}"

		short_dedrift_resource_dir=MSMAllDeDrift
		dedrift_resource_dir=${resources_dir}/${short_dedrift_resource_dir}
		verbose_msg "dedrift_resource_dir: ${dedrift_resource_dir}"

		# Does unprocessed resource for this scan exist?
		if [ -d "${unproc_resource_dir}" ] ; then
			verbose_msg "Unprocessed resource directory for this scan does exist"

			# Does dedrift resource exist?
			if [ -d "${dedrift_resource_dir}" ] ; then
				verbose_msg "DeDrift resource exists, I've got some further checking to do"
				dedrift_resource_exists="TRUE"

				dedrift_resource_date=$(stat -c %y ${dedrift_resource_dir})
				dedrift_resource_date=${dedrift_resource_date%%\.*}

				# Do the expected files exist
				g_all_files_exist="TRUE"

				results_dir=${dedrift_resource_dir} # MSMAllDeDrift

				results_scan_dir=${results_dir}/MNINonLinear/Results/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir} # MSMAllDeDrift/MNINonLinear/Results/rfMRI_REST1_7T_PA

				check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_MSMAll.dtseries.nii"
				check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_MSMAll.L.atlasroi.32k_fs_LR.func.gii"
				check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_MSMAll.R.atlasroi.32k_fs_LR.func.gii"
				check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s2_MSMAll.L.atlasroi.32k_fs_LR.func.gii"
				check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s2_MSMAll.R.atlasroi.32k_fs_LR.func.gii"


				if [[ (${resting_state_scan} = "TRUE") || (${movie_scan} = "TRUE") ]]; then

					check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_MSMAll_hp2000_clean.dtseries.nii"
					check_file_exists "${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_hp2000.ica"
					
					ica_dir=${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_hp2000.ica  # MSMAllDeDrift/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_7T_PA_hp2000.ica
					
					check_file_exists "${ica_dir}/Atlas.dtseries.nii"
					check_file_exists "${ica_dir}/Atlas_hp_preclean.dtseries.nii"
					check_file_exists "${ica_dir}/Atlas.nii.gz"
					
					mc_dir=${ica_dir}/mc
					
					check_file_exists "${mc_dir}/prefiltered_func_data_mcf_conf_hp.nii.gz"
					check_file_exists "${mc_dir}/prefiltered_func_data_mcf_conf.nii.gz"
					check_file_exists "${mc_dir}/prefiltered_func_data_mcf.par"
					
				fi

			else
				# DeDrift resource for this scan does not exist, but should
				verbose_msg "DeDrift resource does not exist but should"
				dedrift_resource_exists="FALSE"
				dedrift_resource_date="N/A"
				g_subject_complete="FALSE"
				g_all_files_exist="FALSE"
			fi

		else
			# Unprocessed resource dir for this scan does not exist
			verbose_msg "unproc does not exist"
			dedrift_resource_exists="---"
			dedrift_resource_date="---"
			g_all_files_exist="---"
		fi

		if [ "${g_report_level}" != "QUIET" ] ; then
			echo -e "${g_project}\t${g_subject}\t${short_dedrift_resource_dir}\t${scan}\t${dedrift_resource_exists}\t${dedrift_resource_date}\t${g_all_files_exist}" >> ${tmp_file}
		fi

	done

	if [ "${g_report_level}" != "QUIET" ]; then
		if [ "${g_subject_complete}" = "TRUE" ]; then
			cat ${tmp_file} >> ${start_dir}/${g_project}.complete.status
		else
			cat ${tmp_file} >> ${start_dir}/${g_project}.incomplete.status
		fi

		cat ${tmp_file}
		rm -f ${tmp_file}
	fi
}

# fire up the main to get things started
main $@

if [ "${g_subject_complete}" = "TRUE" ]; then
	exit 0
else
	exit 1
fi
