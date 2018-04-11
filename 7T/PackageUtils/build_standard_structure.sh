#!/bin/bash

g_script_name=$(basename ${0})

inform()
{
	local msg=${1}
	echo "${g_script_name}: ${msg}"
}

error()
{
	local msg=${1}
	inform "ERROR: ${msg}"
}

abort()
{
	local msg=${1}
	inform "ABORTING: ${msg}"
	exit 1
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	abort "XNAT_PBS_JOBS ENVIRONMENT VARIABLE MUST BE DEFINED"
else
	inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
fi

source ${XNAT_PBS_JOBS}/GetHcpDataUtils/GetHcpDataUtils.sh

get_options()
{
	local arguments=($@)

	unset g_archive_root
	unset g_dest_dir
	unset g_subject
	unset g_three_t_project
	unset g_seven_t_project

	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--archive-root=*)
				g_archive_root=${argument/*=/""}
				;;
			--dest-dir=*)
				g_dest_dir=${argument/*=/""}
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				;;
			--three-t-project=*)
				g_three_t_project=${argument/*=/""}
				;;
			--seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
				;;
			*)
				abort "Unrecognized Option: ${argument}"
				;;
		esac

		index=$(( index + 1 ))
	done

	local error_count=0

	# check required parameters

	if [ -z "${g_archive_root}" ]; then
		error "--archive-root= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "archive root: ${g_archive_root}"
	fi

	if [ -z "${g_dest_dir}" ]; then
		error "--dest-dir= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "destination directory: ${g_dest_dir}"
	fi

	if [ -z "${g_subject}" ]; then
		error "--subject= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "subject: ${g_subject}"
	fi

	if [ -z "${g_three_t_project}" ]; then
		error "--three-t-project= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "3T project: ${g_three_t_project}"
	fi

	if [ -z "${g_seven_t_project}" ]; then
		error "--seven-t-project= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "7T project: ${g_seven_t_project}"
	fi
	
	if [ ${error_count} -gt 0 ]; then
		abort "ERRORS DETECTED: EXITING"
	fi
}

clean_db_archive_artifacts()
{
	pushd ${g_dest_dir}
	inform "Removing previous job logs"
	find . -maxdepth 3 -name "*job.sh*" -print -delete
	
	inform "Removing catalog.xml files"
	find . -maxdepth 3 -name "*catalog.xml" -print -delete

	inform "Removing Provenance.xml files"
	find . -maxdepth 3 -name "*Provenance.xml" -print -delete

	inform "Removing matlab.log files"
	find . -maxdepth 3 -name "*matlab.log" -print -delete

	inform "Removing StructuralHCP.err files"
	find . -maxdepth 3 -name "StructuralHCP.err" -print -delete

	inform "Removing StructuralHCP.log files"
	find . -maxdepth 3 -name "StructuralHCP.log" -print -delete

	inform "Removing starttime files"
	find . -maxdepth 3 -name "*.starttime" -print -delete
	popd
}

main()
{
	# get command line options
	get_options $@

	# set values derived from command line options
	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"
	
	# DeDriftAndResample HighRes data
	link_hcp_resampled_and_dedrifted_highres_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_dest_dir}"

	# DeDriftAndResample data
	link_hcp_resampled_and_dedrifted_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_dest_dir}"

	local scan_dirs
	local scan_dir
	local short_scan_dir
	local scan
	
	# Resting State Stats data
	scan_dirs=$(ls -1d ${g_subject_7T_resources_dir}/*_RSS)
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_RSS}
		link_hcp_7T_resting_state_stats_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_dest_dir}"
	done

	# PostFix data
	scan_dirs=$(ls -1d ${g_subject_7T_resources_dir}/*_PostFix)
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_PostFix}
		link_hcp_postfix_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_dest_dir}"
	done

	# FIX processed data
	scan_dirs=$(ls -1d ${g_subject_7T_resources_dir}/*_FIX)
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_FIX}
		if [ "${scan}" == "tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA" ]; then
			link_hcp_concatenated_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_dest_dir}"
		else
			link_hcp_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_dest_dir}"
		fi
	done
	
	# Functional preproc data
	scan_dirs=$(ls -1d ${g_subject_7T_resources_dir}/*fMRI*preproc)
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_preproc}
		link_hcp_func_preproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${g_dest_dir}" 
	done

	# Supplemental struc preproc data
	link_hcp_supplemental_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_dest_dir}"

	# Structurally preproc data
	link_hcp_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_dest_dir}"

	# unproc data
	link_hcp_struct_unproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${g_dest_dir}"
	link_hcp_7T_resting_state_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_dest_dir}"
	link_hcp_7T_diffusion_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_dest_dir}"
	link_hcp_7T_task_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${g_dest_dir}"

	# remove db archive artifacts
	clean_db_archive_artifacts
}

# Invoke the main function to get things started
main $@
