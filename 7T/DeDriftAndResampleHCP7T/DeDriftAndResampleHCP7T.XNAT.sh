#!/bin/bash

PIPELINE_NAME="DeDriftAndResampleHCP7T"
SCRIPT_NAME="DeDriftAndResampleHCP7T.XNAT.sh"

# echo message with script name as prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

inform "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=${HOME}/SCRIPTS
inform "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=${PIPELINE_TOOLS_HOME}/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh
source ${SCRIPTS_HOME}/epd-python_setup.sh

# Show script usage information
usage()
{
	inform ""
	inform "TBW"
	inform ""
}

# Parse specified command line options and verify that required options are 
# specified. "Return" the options to use in global variables
get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_project
	unset g_subject
	unset g_session
	unset g_structural_reference_project
	unset g_structural_reference_session
	unset g_working_dir
	unset g_workflow_id
	unset g_setup_script
	unset g_keep_all
	unset g_prevent_push
	
	g_keep_all="FALSE"
	g_prevent_push="FALSE"
	
	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--help)
				usage
				exit 1
				;;
			--user=*)
				g_user=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--password=*)
				g_password=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--server=*)
				g_server=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--project=*)
				g_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--session=*)
				g_session=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--structural-reference-project=*)
				g_structural_reference_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--structural-reference-session=*)
				g_structural_reference_session=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--workflow-id=*)
				g_workflow_id=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--keep-all)
				g_keep_all="TRUE"
				index=$(( index + 1 ))
				;;
			--prevent-push)
				g_prevent_push="TRUE"
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	local error_count=0

	# check required parameters
	if [ -z "${g_user}" ]; then
		inform "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		inform "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_password: *******"
	fi

	if [ -z "${g_server}" ]; then
		inform "ERROR: server (--server=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		inform "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		inform "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_session: ${g_session}"
	fi

	if [ -z "${g_structural_reference_project}" ]; then
		inform "ERROR: structural reference project (--structural-reference-project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_structural_reference_project: ${g_structural_reference_project}"
	fi

	if [ -z "${g_structural_reference_session}" ]; then
		inform "ERROR: structural reference session (--structural-reference-session=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_structural_reference_session: ${g_structural_reference_session}"
	fi

	if [ -z "${g_working_dir}" ]; then
		inform "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_workflow_id}" ]; then
		inform "ERROR: workflow ID (--workflow-id=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_workflow_id: ${g_workflow_id}"
	fi

	if [ -z "${g_setup_script}" ]; then
		inform "ERROR: set up script (--setup-script=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

	if [ -z "${g_keep_all}" ]; then
		g_keep_all="FALSE"
	fi
	inform "g_keep_all: ${g_keep_all}"

	if [ -z "${g_prevent_push}" ]; then
		g_prevent_push="FALSE"
	fi
	inform "g_prevent_push: ${g_prevent_push}"
	
	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

die()
{
	xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	exit 1
}

# Main processing
main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Set up step counters
	total_steps=16
	current_step=0

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# Step - Figure out what scans are available for this subject/session
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Figure out what scans are available for this subject session" ${step_percent}

	# All functionally preprocessed scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	all_functionally_preprocessed_scan_names=""
	resting_state_scan_dirs=`ls -d rfMRI_REST*_preproc`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_preproc} # take the _preproc off the end
		all_functionally_preprocessed_scan_names+="${scan_name} "
	done

	task_scan_dirs=`ls -d tfMRI_*_preproc`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_preproc} # take the _preproc off the end
		all_functionally_preprocessed_scan_names+="${scan_name} "
	done
	all_functionally_preprocessed_scan_names=${all_functionally_preprocessed_scan_names% } # remove the trailing space

	inform "Found the following functionally preprocessed scans: ${all_functionally_preprocessed_scan_names}"
	
	popd > /dev/null

	# All functional scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	all_functional_scan_names=""
	resting_state_scan_dirs=`ls -d rfMRI_REST*_unproc`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_unproc} # take the _unproc off the end
		all_functional_scan_names+="${scan_name} "
	done

	task_scan_dirs=`ls -d tfMRI_*_unproc`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_unproc} # take the _unproc off the end
		all_functional_scan_names+="${scan_name} "
	done
	all_functional_scan_names=${all_functional_scan_names% } # remove the trailing space

	inform "Found the following functional scans: ${all_functional_scan_names}"

	popd > /dev/null

	# Fix processed Resting state scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	fix_processed_resting_state_scan_names=""
	resting_state_scan_dirs=`ls -d rfMRI_REST*_FIX`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_FIX} # take the _FIX off the end
		fix_processed_resting_state_scan_names+="${scan_name} "
	done
	fix_processed_resting_state_scan_names=${fix_processed_resting_state_scan_names% } # remove trailing space
	
	if [ -z "${fix_processed_resting_state_scan_names}" ]; then
		fix_processed_resting_state_scan_names="NONE"
	fi

	inform "Found the following FIX Processed resting state scans: ${fix_processed_resting_state_scan_names}"

	popd > /dev/null

	# Fix processed Task scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	fix_processed_task_scan_names=""
	task_scan_dirs=`ls -d tfMRI_*_FIX`

	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_FIX} # take the _FIX off the end
		if [[ ${scan_name} == tfMRI_7T* ]] ; then
			inform "Not adding ${scan_name} to fix_processed_task_scan_names"
		else
			inform "Adding ${scan_name} to fix_processed_task_scan_names"
			fix_processed_task_scan_names+="${scan_name} "
		fi
	done
	fix_processed_task_scan_names=${fix_processed_task_scan_names% } # remove trailing space

	if [ -z "${fix_processed_task_scan_names}" ]; then
		fix_processed_task_scan_names="NONE"
	fi

	inform "Found the following FIX Processed task scans: ${fix_processed_task_scan_names}"

	popd > /dev/null

	# Fix processed Movie scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	fix_processed_movie_scan_names=""
	movie_scan_dirs=`ls -d tfMRI_MOVIE*_FIX`
	for movie_scan_dir in ${movie_scan_dirs} ; do
		scan_name=${movie_scan_dir%%_FIX} # take the _FIX off the end
		fix_processed_movie_scan_names+="${scan_name} "
	done
	fix_processed_movie_scan_names=${fix_processed_movie_scan_names% } # remove trailing space

	if [ -z "${fix_processed_movie_scan_names}" ]; then
		fix_processed_movie_scan_names="NONE"
	fi

	inform "Found the following FIX Processed movie scans: ${fix_processed_movie_scan_names}"

	popd > /dev/null

	# Retinotopy scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	retinotopy_scan_names=""
	retinotopy_scan_dirs=`ls -d tfMRI_RET*_preproc`
	for retinotopy_scan_dir in ${retinotopy_scan_dirs} ; do
		scan_name=${retinotopy_scan_dir%%_preproc} # take the _preproc off the end
		retinotopy_scan_names+="${scan_name} "
	done
	retinotopy_scan_names=${retinotopy_scan_names% } # remove trailing space

	if [ -z "${retinotopy_scan_names}" ]; then
		retinotopy_scan_names="NONE"
	fi

	inform "Found the following retinotopy scans: ${retinotopy_scan_names}"

	sorted_retinotopy_scan_names=""
	for rscan in tfMRI_RETCCW_AP tfMRI_RETCW_PA tfMRI_RETEXP_AP tfMRI_RETCON_PA tfMRI_RETBAR1_AP tfMRI_RETBAR2_PA ; do
		if [[ ${retinotopy_scan_names} == *${rscan}* ]] ; then
			inform "${rscan} is in ${retinotopy_scan_names}"
			sorted_retinotopy_scan_names+="${rscan} "
		else
			inform "${rscan} is NOT in ${retinotopy_scan_names}"
		fi
	done
	sorted_retinotopy_scan_names=${sorted_retinotopy_scan_names% } # remove trailing space

	if [ -z "${sorted_retinotopy_scan_names}" ]; then
		sorted_retinotopy_scan_names="NONE"
	fi

	inform "Sorted retinotopy scans: ${sorted_retinotopy_scan_names}"

	retinotopy_scan_files=""
	for rscan_name in ${sorted_retinotopy_scan_names} ; do
		if [ "${rscan_name}" != "NONE" ]; then
			prefix=${rscan_name%%_*}
			scan=${rscan_name#${prefix}_}
			scan=${scan%%_*}
			pe_dir=${rscan_name##*_}
			long_scan_name="${prefix}_${scan}_7T_${pe_dir}"
			
			retinotopy_scan_files+="${g_working_dir}/${g_subject}/MNINonLinear/Results/${long_scan_name}/${long_scan_name}.nii.gz "
		fi
	done
	retinotopy_scan_files=${retinotopy_scan_files% } # remove trailing space

	inform "Retinotopy scan files: ${retinotopy_scan_files}"
	
	concatenated_retinotopy_scan_name=${sorted_retinotopy_scan_names//tfMRI_/}
	concatenated_retinotopy_scan_name=${concatenated_retinotopy_scan_name// /_}
	concatenated_retinotopy_scan_name="tfMRI_7T_${concatenated_retinotopy_scan_name}"

	inform "Concatenated retinotopy scan name: ${concatenated_retinotopy_scan_name}"

	concatenated_retinotopy_scan_file_name="${g_working_dir}/${g_subject}/MNINonLinear/Results/${concatenated_retinotopy_scan_name}/${concatenated_retinotopy_scan_name}.nii.gz"
	inform "concatenated retinotopy scan file name: ${concatenated_retionotopy_scan_file_name}"
	
	popd > /dev/null

	# Multi-run ICAFIX processing scans
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES > /dev/null

	multirun_fix_processed_scan_names=""
	multirun_fix_processed_scan_dirs=`ls -d tfMRI_7T_*_FIX`
	for multirun_fix_processed_scan_dir in ${multirun_fix_processed_scan_dirs} ; do
		scan_name=${multirun_fix_processed_scan_dir%%_FIX} # take _FIX off the end
		multirun_fix_processed_scan_names+="${scan_name} "
	done
	multirun_fix_processed_scan_names=${multirun_fix_processed_scan_names% } # remove trailing space

	if [ -z "${multirun_fix_processed_scan_names}" ]; then
		multirun_fix_processed_scan_names="NONE"
	fi

	inform "Found the following multi-run ICAFIX processed scans: ${multirun_fix_processed_scan_names}"

	popd > /dev/null

	# VERY IMPORTANT NOTE:
	#
	# Since ConnectomeDB resources contain overlapping files (e.g. the functionally preprocessed
	# data resource may contain some of the exact same files as the structurally preprocessed
	# data resource), extra care must be taken with the order in which data is linked in to the
	# working directory.
	#
	# If, for example, a file named ${subject}/subdir1/subdir2/this_file.nii.gz exists in both
	# the structurally preprocessed data resource and in the functionally preprocessed data 
	# resource, whichever resource we link in to the working directory _first_ will take 
	# precedence.  (This is due to the behavior of the lndir command used by the link_hcp...
	# functions, and is unlike the behavior of the rsync command used by the get_hcp...
	# functions. The rsync command will copy/update the newer version of the file from its 
	# source.)
	#
	# The lndir command will report to stderr any links that it could not (would not) create 
	# because they already exist in the destination directories.
	#
	# So, if we link in the structurally preprocessed data first and then link in the functionally
	# preprocessed data second, the file ${subject}/subdir1/subdir2/this_file.nii.gz in the 
	# working directory will be linked back to the structurally preprocessed version of the file.
	#
	# Since functional preprocessing comes _after_ structural preprocessing, this is not likely
	# to be what we want.  Instead, we want the file as it exists after functional preprocessing
	# to be the one that is linked in to the working directory.
	#
	# Therefore, it is important to consider the order in which we call the link_hcp... functions
	# below.  We should call them in order from the results of the latest prerequisite pipelines
	# to the earliest prerequisite pipelines.

	# Step - Link Group Average Drift Data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
 	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Group Average Drift Data from DB" ${step_percent}

	# Note: Using the same group average drift data that was used for the HCP_900 release
	link_hcp_msm_group_average_drift_data "${DATABASE_ARCHIVE_ROOT}" "HCP_900" "${g_working_dir}"

	# # Step - Link MSM All registration data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	 	${current_step} "Link MSM-All registration data from DB" ${step_percent}

	# Note: Using results of MSM All registration using reference project (3T)
	link_hcp_msm_all_registration_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
		"${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link Multirun ICAFIX processed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
						 ${current_step} "Link Multirun ICAFIX processed data from DB" ${step_percent}
	
	for scan_name in ${multirun_fix_processed_scan_names} ; do
		resource_dir=${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${scan_name}_FIX
		if [ -d ${resource_dir} ]; then
			link_hcp_concatenated_fix_proc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${scan_name}" "${g_working_dir}"
		fi
	done
	
	# Step - Link FIX processed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link FIX processed data from DB" ${step_percent}

	for scan_name in ${fix_processed_resting_state_scan_names} ${fix_processed_task_scan_names} ; do
		if [ "${scan_name}" != "NONE" ]; then
			if [ -d ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${scan_name}_FIX ]; then
				link_hcp_fix_proc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${scan_name}" "${g_working_dir}"
			fi
		fi
	done

 	# Step - Link functionally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link functionally preprocessed data from DB" ${step_percent}

	for scan_name in ${all_functionally_preprocessed_scan_names} ; do
		link_hcp_func_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${scan_name}" "${g_working_dir}"
	done
	
	# Step - Link supplemental structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link supplemental structurally preprocessed data from DB" ${step_percent}

	link_hcp_supplemental_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
		"${g_structural_reference_session}" "${g_working_dir}"

 	# Step - Link structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link structurally preprocessed data from DB" ${step_percent}

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
		"${g_structural_reference_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
	# Step - Copy files that are opened for writing by DeDriftAndResample.sh script
	# These spec files already exist prior to running this pipeline, and are modified by the
	# pipeline script.
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Copy files that are opened for writing" ${step_percent}
	
	t1w_native_spec_file=${g_working_dir}/${g_subject}/T1w/Native/${g_subject}.native.wb.spec

	rm ${t1w_native_spec_file}
	cp -a --preserve=timestamps --verbose \
		${DATABASE_ARCHIVE_ROOT}/${g_structural_reference_project}/arc001/${g_structural_reference_session}/RESOURCES/Structural_preproc/T1w/Native/${g_subject}.native.wb.spec \
		${t1w_native_spec_file}

	native_spec_file=${g_working_dir}/${g_subject}/MNINonLinear/Native/${g_subject}.native.wb.spec

	rm ${native_spec_file}
	cp -a --preserve=timestamps --verbose \
		${DATABASE_ARCHIVE_ROOT}/${g_structural_reference_project}/arc001/${g_structural_reference_session}/RESOURCES/Structural_preproc/MNINonLinear/Native/${g_subject}.native.wb.spec \
		${native_spec_file}

	# ----------------------------------------------------------------------------------------------
	# Step - Remove files that are re-created by the ReApplyFixPipeline.sh script which is invoked
	#        by the DeDriftAndResample.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Remove files that are re-created by ReApplyFixPipeline" ${step_percent}

	local HighPass="2000" 
	for scan_name in ${fix_processed_resting_state_scan_names} ${fix_processed_task_scan_names} ; do
		if [ "${scan_name}" != "NONE" ]; then
			if [ -d ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${scan_name}_FIX ] ; then
				
				#working_ica_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${scan_name}/${scan_name}_hp${HighPass}.ica
				
				echo "scan_name: ${scan_name}"
				
				scan_without_pe_dir=${scan_name%_*}
				echo "scan_without_pe_dir: ${scan_without_pe_dir}"
				
				pe_dir=${scan_name##*_}
				echo "pe_dir: ${pe_dir}"
				
				long_scan_name=${scan_without_pe_dir}_7T_${pe_dir}
				echo "long_scan_name: ${long_scan_name}"
				
				working_ica_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${long_scan_name}/${long_scan_name}_hp${HighPass}.ica
				echo "working_ica_dir: ${working_ica_dir}"
				
				if [ -e "${working_ica_dir}/Atlas.dtseries.nii" ] ; then
					rm --verbose ${working_ica_dir}/Atlas.dtseries.nii
				fi
				
				if [ -e "${working_ica_dir}/Atlas.nii.gz" ] ; then
					rm --verbose ${working_ica_dir}/Atlas.nii.gz
				fi
				
				if [ -e "${working_ica_dir}/filtered_func_data.nii.gz" ] ; then
					rm --verbose ${working_ica_dir}/filtered_func_data.nii.gz
				fi
				
				if [ -d "${working_ica_dir}/mc" ] ; then
					rm --recursive --verbose ${working_ica_dir}/mc
				fi
				
				if [ -e "${working_ica_dir}/Atlas_hp_preclean.dtseries.nii" ] ; then
					rm --verbose ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii
				fi
				
			fi
		fi
	done

	for scan_name in ${multirun_fix_processed_scan_names} ; do
		resource_dir=${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${scan_name}_FIX
		if [ -d ${resource_dir} ] ; then

			echo "scan_name: ${scan_name}"
			
			working_ica_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${scan_name}/${scan_name}_hp${HighPass}.ica
			echo "working_ica_dir: ${working_ica_dir}"
			
			if [ -e "${working_ica_dir}/Atlas.dtseries.nii" ] ; then
				cp -a --preserve=timestamps --verbose ${working_ica_dir}/Atlas.dtseries.nii ${working_ica_dir}/Atlas.dtseries.nii.NOLINK
				rm --verbose ${working_ica_dir}/Atlas.dtseries.nii
				mv ${working_ica_dir}/Atlas.dtseries.nii.NOLINK ${working_ica_dir}/Atlas.dtseries.nii
			fi
		
			if [ -e "${working_ica_dir}/Atlas.nii.gz" ] ; then
				cp -a --preserve=timestamps --verbose ${working_ica_dir}/Atlas.nii.gz ${working_ica_dir}/Atlas.nii.gz.NOLINK
				rm --verbose ${working_ica_dir}/Atlas.nii.gz
				mv ${working_ica_dir}/Atlas.nii.gz.NOLINK ${working_ica_dir}/Atlas.nii.gz
			fi
			
			if [ -e "${working_ica_dir}/filtered_func_data.nii.gz" ] ; then
				cp -a --preserve=timestamps --verbose ${working_ica_dir}/filtered_func_data.nii.gz ${working_ica_dir}/filtered_func_data.nii.gz.NOLINK
				rm --verbose ${working_ica_dir}/filtered_func_data.nii.gz
				mv ${working_ica_dir}/filtered_func_data.nii.gz.NOLINK ${working_ica_dir}/filtered_func_data.nii.gz
			fi
			
			#if [ -d "${working_ica_dir}/mc" ] ; then
			#	rm --recursive --verbose ${working_ica_dir}/mc
			#fi
			
			if [ -e "${working_ica_dir}/Atlas_hp_preclean.dtseries.nii" ] ; then
				cp -a --preserve=timestamps --verbose ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii.NOLINK
				rm --verbose ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii
				mv  ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii.NOLINK  ${working_ica_dir}/Atlas_hp_preclean.dtseries.nii
			fi
			
		fi
	done

	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Create a start_time file" ${step_percent}
	
	start_time_file="${g_working_dir}/${PIPELINE_NAME}.starttime"
	if [ -e "${start_time_file}" ]; then
		echo "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi
	
	# Sleep for 1 minute to make sure start_time file is created at least a
	# minute after any files copied or linked above.
	echo "Sleep for 1 minute before creating start_time file."
	sleep 1m || die

	echo "Creating start time file: ${start_time_file}"
	touch ${start_time_file} || die 
	ls -l ${start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the script below
	# are created at least 1 minute after the start_time file
	echo "Sleep for 1 minute after creating start_time file."
	sleep 1m || die 

	# Step - Run DeDriftAndResample.sh script
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run DeDriftAndResamplePipeline.sh script" ${step_percent}
	
	# Source setup script to setup environment for running the script
	if [ -e "${g_setup_script}" ]; then
		inform "Sourcing ${g_setup_script} to set up environment"
		source ${g_setup_script}
	else
		inform "Set up environment script: ${g_setup_script}, DOES NOT EXIST"
		inform "ABORTING"
		die
	fi

	# Setup variables for command line arguments

	local HighResMesh="164"
	local LowResMeshes="32" # Delimit with @ e.g. 32@59, multiple resolutions not currently supported for fMRI data
	local RegName="MSMAll_InitalReg_2_d40_WRN" # From MSMAllPipeline.bat

	local DeDriftRegFiles=""
	DeDriftRegFiles+="${g_working_dir}/DeDriftingGroup/MNINonLinear/DeDriftMSMAll/DeDriftingGroup.L.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"
	DeDriftRegFiles+="@"
	DeDriftRegFiles+="${g_working_dir}/DeDriftingGroup/MNINonLinear/DeDriftMSMAll/DeDriftingGroup.R.sphere.DeDriftMSMAll.164k_fs_LR.surf.gii"

	local ConcatRegName="MSMAll" # Final name of ${RegName}, the string that identifies files as being registered with this method
	local Maps="sulc curvature corrThickness thickness" # List of Structural Maps to be resampled
	local MyelinMaps="MyelinMap SmoothedMyelinMap" #List of Myelin Maps to be Resampled (No _BC, this will be reapplied)

	#local rfMRINames="${fix_processed_resting_state_scan_names}" #List of Resting State Maps Space delimited list or NONE

	local rfMRINames=""
	if [ "${fix_processed_resting_state_scan_names}" != "NONE" ] ; then
		for scan_name in ${fix_processed_resting_state_scan_names} ; do
			scan_without_pe_dir=${scan_name%_*}
			pe_dir=${scan_name##*_}
			rfMRINames+="${scan_without_pe_dir}_7T_${pe_dir} "
		done
	fi

	if [ "${fix_processed_movie_scan_names}" != "NONE" ] ; then
		for scan_name in ${fix_processed_movie_scan_names} ; do
			scan_without_pe_dir=${scan_name%_*}
			pe_dir=${scan_name##*_}
			rfMRINames+="${scan_without_pe_dir}_7T_${pe_dir} "
		done
	fi

	rfMRINames=${rfMRINames% } # remove trailing space

	if [ -z "${rfMRINames}" ]; then
		rfMRINames="NONE"
	fi

	local tfMRINames="" #Space delimited list or NONE

	if [ "${retinotopy_scan_names}" != "NONE" ] ; then
		for scan_name in ${retinotopy_scan_names} ; do
			scan_without_pe_dir=${scan_name%_*}
			pe_dir=${scan_name##*_}
			tfMRINames+="${scan_without_pe_dir}_7T_${pe_dir} "
		done
	fi

	tfMRINames=${tfMRINames% } # remove trailing space

	if [ -z "${tfMRINames}" ]; then
		tfMRINames="NONE"
	fi

	local SmoothingFWHM="2" #Should equal previous grayordiantes smoothing (because we are resampling from unsmoothed native mesh timeseries
	# For value of HighPass, see step above in which prefiltered_func_data_mcf.par files are copied.
	#local HighPass="2000" #For resting state fMRI

	Maps=`echo "$Maps" | sed s/" "/"@"/g`
	MyelinMaps=`echo "$MyelinMaps" | sed s/" "/"@"/g`
	rfMRINames=`echo "$rfMRINames" | sed s/" "/"@"/g`
	tfMRINames=`echo "$tfMRINames" | sed s/" "/"@"/g`

	# Run DeDriftAndResamplePipeline.sh script
	dedrift_cmd=""
	dedrift_cmd+="${HCPPIPEDIR}/DeDriftAndResample/DeDriftAndResamplePipeline.sh"
	dedrift_cmd+=" --path=${g_working_dir}"
	dedrift_cmd+=" --subject=${g_subject}"
	dedrift_cmd+=" --high-res-mesh=${HighResMesh}"
	dedrift_cmd+=" --low-res-meshes=${LowResMeshes}"
	dedrift_cmd+=" --registration-name=${RegName}"
	dedrift_cmd+=" --dedrift-reg-files=${DeDriftRegFiles}"
	dedrift_cmd+=" --concat-reg-name=${ConcatRegName}"
	dedrift_cmd+=" --maps=${Maps}"
	dedrift_cmd+=" --myelin-maps=${MyelinMaps}"
	dedrift_cmd+=" --rfmri-names=${rfMRINames}"
	dedrift_cmd+=" --tfmri-names=${tfMRINames}"
	dedrift_cmd+=" --smoothing-fwhm=${SmoothingFWHM}"
	dedrift_cmd+=" --highpass=${HighPass}"
	dedrift_cmd+=" --matlab-run-mode=0" # Use compiled MATLAB

	inform "dedrift_cmd: ${dedrift_cmd}"

	${dedrift_cmd}
	return_code=$?
	if [ ${return_code} -ne 0 ]; then
		inform "Non-zero return code: ${return_code}"
		inform "ABORTING"
		die 
	fi

	# Step - Call ReApplyFixPipelineMultiRun.sh to handle the ReApplyFix functionality
	#        on the multi-run concatenated scans
	#        Note that for the non-concatenated scans, ReApplyFixPipeline.sh is already called
	#        within DeDriftAndResamplePipeline.sh
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Call ReApplyFixPipelineMultiRun.sh" ${step_percent}

	if [ "${sorted_retinotopy_scan_names}" != "NONE" ]; then
		reapply_fix_multirun_cmd=""
		reapply_fix_multirun_cmd+="${HCPPIPEDIR}/ReApplyFixMultiRun/ReApplyFixPipelineMultiRun.sh"
		reapply_fix_multirun_cmd+=" --path=${g_working_dir}"
		reapply_fix_multirun_cmd+=" --subject=${g_subject}"
		reapply_fix_multirun_cmd+=" --fmri-names=${retinotopy_scan_files// /@}"
		reapply_fix_multirun_cmd+=" --concat-fmri-name=${concatenated_retinotopy_scan_file_name}"
		reapply_fix_multirun_cmd+=" --high-pass=${HighPass}"
		reapply_fix_multirun_cmd+=" --reg-name=${ConcatRegName}"
		reapply_fix_multirun_cmd+=" --matlab-run-mode=0" # Use compiled MATLAB
		
		inform "reapply_fix_multirun_cmd: ${reapply_fix_multirun_cmd}"
		
		${reapply_fix_multirun_cmd}
		return_code=$?
		if [ ${return_code} -ne 0 ]; then
			inform "Non-zero return code: ${return_code}"
			inform "ABORTING"
			die 
		fi
		
	else
		inform "NOT running ReApplyFixPipelineMultiRun.sh because there are no retinotopy scans"

	fi

	# Step - Show any newly created or modified files
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Show newly created or modified files" ${step_percent}
	
	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}


	if [ "${g_keep_all}" != "TRUE" ]; then
	
		# Step - Remove any files that are not newly created or modified
		current_step=$(( current_step + 1 ))
		step_percent=$(( (current_step * 100) / total_steps ))
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Remove files not newly created or modified" ${step_percent}
		
		echo "The following files are being removed"
		find ${g_working_dir} -not -newer ${start_time_file} -print -delete 

	fi
	
	# Step - Complete Workflow
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
}

# Invoke the main function to get things started
main $@

if [ "${g_prevent_push}" = "TRUE" ]; then
	inform "Exiting with status code 1 to prevent DB push."
	exit 1
fi

