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

ICA_FIX_SCANS_LIST=""
ICA_FIX_SCANS_LIST+=" REST1_PA "
ICA_FIX_SCANS_LIST+=" REST2_AP "
ICA_FIX_SCANS_LIST+=" REST3_PA "
ICA_FIX_SCANS_LIST+=" REST4_AP "
ICA_FIX_SCANS_LIST+=" MOVIE1_AP "
ICA_FIX_SCANS_LIST+=" MOVIE2_PA "
ICA_FIX_SCANS_LIST+=" MOVIE3_PA "
ICA_FIX_SCANS_LIST+=" MOVIE4_AP "

RESTING_PREFIX="rfMRI_"
TASK_PREFIX="tfMRI_"

UNPROC_SUFFIX="_unproc"
PREPROC_SUFFIX="_preproc"
FIX_SUFFIX="_FIX"

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_details
	unset g_scans
	unset g_report_level
	unset g_post_patch
	g_post_patch="FALSE"

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
			--scan=*)
				g_scans+=" "
				g_scans+=${argument/*=/""}
				g_scans+=" "
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
			--post-patch)
			    g_post_patch="TRUE"
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

	if [ -z "${g_scans}" ]; then
		g_scans=${ICA_FIX_SCANS_LIST}
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

	for scan in ${g_scans} ; do

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

		scan_without_pe_dir=${scan%_*}
		verbose_msg "scan_without_pe_dir: ${scan_without_pe_dir}"

		pe_dir=${scan#*_}
		verbose_msg "pe_dir: ${pe_dir}"

		# Does preprocessed resource for this scan exist?
		if [ -d "${preproc_resource_dir}" ] ; then
			verbose_msg "Preprocessed resource directory for this scan does exist"

			# Does FIX resource for this scan exist?
			if [ -d "${fix_resource_dir}" ] ; then
				verbose_msg "FIX resource exists, I've got some further checking to do"
				fix_resource_exists="TRUE"

				fix_resource_date=$(stat -c %y ${fix_resource_dir})
				fix_resource_date=${fix_resource_date%%\.*}

				# Do the expected files exist
				g_all_files_exist="TRUE"


				results_dir=${fix_resource_dir} # rfMRI_REST1_PA_FIX   Note: The MNINonLinear/Results directories are removed from FIX results resources
				results_scan_dir=${results_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir} # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA
				ica_dir=${results_scan_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_hp2000.ica  # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_7T_PA_hp2000.ica
				

				check_dir=${results_scan_dir}

				if [ "${g_post_patch}" = "TRUE" ]; then
					check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_1.6mm_hp2000_clean.dtseries.nii"
				else
					check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_MSMSulc.59k_hp2000_clean.dtseries.nii"
				fi
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_hp2000_clean.dtseries.nii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_hp2000_clean.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_hp2000.nii.gz"


				check_dir=${ica_dir}
				verbose_msg "1. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/Atlas_hp_preclean.dtseries.nii"
				check_file_exists "${check_dir}/Atlas.nii.gz"
				check_file_exists "${check_dir}/mask.nii.gz"

				check_dir=${ica_dir}/filtered_func_data.ica # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_PA_hp2000.ica/filtered_func_data.ica
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "2. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/eigenvalues_percent"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/mask.nii.gz"
				check_file_exists "${check_dir}/mean.nii.gz"
				check_file_exists "${check_dir}/melodic_dewhite"
				check_file_exists "${check_dir}/melodic_FTdewhite"
				check_file_exists "${check_dir}/melodic_FTmix"
				check_file_exists "${check_dir}/melodic_IC.nii.gz"
				check_file_exists "${check_dir}/melodic_ICstats"
				check_file_exists "${check_dir}/melodic_mix"
				check_file_exists "${check_dir}/melodic_oIC.nii.gz"
				check_file_exists "${check_dir}/melodic_pcaD"
				check_file_exists "${check_dir}/melodic_pcaE"
				check_file_exists "${check_dir}/melodic_pca.nii.gz"
				check_file_exists "${check_dir}/melodic_PPCA"
				check_file_exists "${check_dir}/melodic_Tmodes"
				check_file_exists "${check_dir}/melodic_unmix"
				check_file_exists "${check_dir}/melodic_white"
				check_file_exists "${check_dir}/Noise__inv.nii.gz"

				# report/
				# stats/

				check_dir=${ica_dir}/fix # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_PA_hp2000.ica/fix
				verbose_msg "3. check_dir: ${check_dir}"

				# edge1.nii.gz
				# edge2.nii.gz
				# edge3.nii.gz
				# edge4.nii.gz
				# edge5.nii.gz
				check_file_exists "${check_dir}/fastsg_mixeltype.nii.gz"
				# fastsg_pve_0.nii.gz
				# fastsg_pve_1.nii.gz
				# fastsg_pve_2.nii.gz
				# fastsg_pveseg.nii.gz
				check_file_exists "${check_dir}/fastsg_seg.nii.gz"
				check_file_exists "${check_dir}/features.csv"
				check_file_exists "${check_dir}/features_info.csv"
				check_file_exists "${check_dir}/features.mat"
				check_file_exists "${check_dir}/highres2std.mat"
				check_file_exists "${check_dir}/hr2exf.nii.gz"
				check_file_exists "${check_dir}/hr2exfTMP.nii.gz"
				check_file_exists "${check_dir}/hr2exfTMP.txt"
				check_file_exists "${check_dir}/logMatlab.txt"
				# maske1.nii.gz
				# maske2.nii.gz
				# maske3.nii.gz
				# maske4.nii.gz
				# maske5.nii.gz
				check_file_exists "${check_dir}/std1mm2exfunc0dil2.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc0dil.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc0.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc1dil2.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc1dil.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc1.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc2dil2.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc2dil.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc2.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc3dil2.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc3dil.nii.gz"
				check_file_exists "${check_dir}/std1mm2exfunc3.nii.gz"
				check_file_exists "${check_dir}/std2exfunc.mat"
				check_file_exists "${check_dir}/std2highres.mat"
				check_file_exists "${check_dir}/subcort.nii.gz"


				check_dir=${ica_dir}/reg # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_PA_hp2000.ica/reg
				verbose_msg "4. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/highres2example_func.mat"
				check_file_exists "${check_dir}/veins_exf.nii.gz"
				check_file_exists "${check_dir}/veins.nii.gz"

				check_dir=${ica_dir}/mc # rfMRI_REST1_7T_FIX/MNINonLinear/Results/rfMRI_REST1_7T_PA/rfMRI_REST1_PA_hp2000.ica/mc
				verbose_msg "5. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/prefiltered_func_data_mcf_conf_hp.nii.gz"
				check_file_exists "${check_dir}/prefiltered_func_data_mcf_conf.nii.gz"
				check_file_exists "${check_dir}/prefiltered_func_data_mcf.par"

			else
				# fix resource for this scan does not exist, but should
				verbose_msg "FIX resource does not exist but should"
				fix_resource_exists="FALSE"
				fix_resource_date="N/A"
				g_subject_complete="FALSE"
				g_all_files_exist="FALSE"
			fi

		else
			# Preprocessed resource dir for this scan does not exist
			verbose_msg "preproc does not exist"
			fix_resource_exists="---"
			fix_resource_date="---"
			g_all_files_exist="---"
		fi

		if [ "${g_report_level}" != "QUIET" ] ; then
			echo -e "${g_project}\t${g_subject}\t${short_fix_resource_dir}\t${fix_resource_exists}\t${fix_resource_date}\t${g_all_files_exist}" >> ${tmp_file}
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
