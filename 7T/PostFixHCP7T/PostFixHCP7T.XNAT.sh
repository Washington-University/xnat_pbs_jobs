#!/bin/bash

PIPELINE_NAME="PostFixHCP7T"
SCRIPT_NAME="PostFixHCP7T.XNAT.sh"

# echo message with script name as prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

inform "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to set up the environment
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
	unset g_scan
	unset g_working_dir
	unset g_workflow_id
	unset g_setup_script

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
			--scan=*)
				g_scan=${argument/*=/""}
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
			*)
				usage
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
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

	if [ -z "${g_scan}" ] ; then
		inform "ERROR: --scan= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_scan: ${g_scan}"
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

	if [ -z "${g_setup_script}" ] ; then
		inform "ERROR: set up script (--setup-script=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

die()
{
	xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	exit 1
}

main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	# Set up step counters
	total_steps=12
	current_step=0

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# Step - Link FIX processed and functionally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link FIX processed and functionally preprocessed data from DB" ${step_percent}

	# Is it a single scan or a concatenated scan?
	# Reduce ${g_scan} to a space separated list of just the scan names

	# remove any tesla spec from the string
	tesla_spec="7T"
	scans=${g_scan//${tesla_spec}/}
	scans=${scans//__/_}
	inform "scans: ${scans}"

	# Does ${scans} now start with tfMRI or rfMRI?
	if [[ ${scans} == tfMRI_* ]]; then
		prefix="tfMRI_"
	elif [[ ${scans} == rfMRI_* ]]; then
		prefix="rfMRI_"
	else
		inform "Do not recognize scan prefix."
		die 
	fi

	inform "prefix: ${prefix}"

	# remove the prefix
	scans=${scans#${prefix}}

	inform "scans: ${scans}"

	# put spaces after phase encoding descriptors
	scans=${scans//_AP_/_AP }
	scans=${scans//_PA_/_PA }
	scans=${scans//_LR_/_LR }
	scans=${scans//_RL_/_RL }

	inform "scans: ${scans}"
	
	# figure out if the processed scan is a concatenation of several scans
	if [[ "${scans}" =~ [\ ] ]]; then
		g_concatenated="TRUE"
	else
		g_concatenated="FALSE"
	fi

	if [ "${g_concatenated}" = "TRUE" ]; then
		# concatenated

		# get the FIX processed data for the concatenated scan
		link_hcp_concatenated_fix_proc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
											"${g_session}" "${g_scan}" "${g_working_dir}"

		# get the functionally preprocessed data for the individual scans that
		# were concatenated
		for scan in ${scans} ; do
			preproc_scan=${prefix}${scan}
			inform "preproc_scan: ${preproc_scan}"

			link_hcp_func_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
									   "${g_session}" "${preproc_scan}" "${g_working_dir}"
		done

		# get files that are opened for writing
		# Whether they are actually written to or not, if a file is opened in write mode,
		# that open will fail due to the read-only nature of the files in the DB archive.
		filtered_func_data_dir="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_hp2000.ica/filtered_func_data.ica"
		filtered_mask_files="${filtered_func_data_dir}/mask*"
		echo "filtered_mask_files: ${filtered_mask_files}"
		rm ${filtered_mask_files}

		cp_cmd="cp -a --preserve=timestamps"
		cp_cmd+=" ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${g_scan}_FIX/${g_scan}/${g_scan}_hp2000.ica/filtered_func_data.ica/mask*"
		cp_cmd+=" ${filtered_func_data_dir}"
		inform "cp_cmd: ${cp_cmd}"
		${cp_cmd}
				
	else
		# scans is really only one. Not concatenated
		# preproc_scan=${g_scan%_${tesla_spec}*}${g_scan##*_${tesla_spec}}
		# inform "preproc_scan: ${preproc_scan}"
		preproc_scan=${prefix}${scans}
		inform "preproc_scan: ${preproc_scan}"

		link_hcp_fix_proc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
							   "${g_session}" "${preproc_scan}" "${g_working_dir}"

		link_hcp_func_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
								   "${g_session}" "${preproc_scan}" "${g_working_dir}"

		# get files that are opened for writing
		# Whether they are actually written to or not, if a file is opened in write mode,
		# that open will fail due to the read-only nature of the files in the DB archive.
		filtered_func_data_dir="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}_hp2000.ica/filtered_func_data.ica"
		filtered_mask_files="${filtered_func_data_dir}/mask*"
		echo "filtered_mask_files: ${filtered_mask_files}"
		rm ${filtered_mask_files}

		cp -a --preserve=timestamps \
	 	   ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${preproc_scan}_FIX/${g_scan}/${g_scan}_hp2000.ica/filtered_func_data.ica/mask* \
		   ${filtered_func_data_dir}

	fi

	find ${g_working_dir}/${g_subject} -name "*XNAT_PBS_job*" -delete
	find ${g_working_dir}/${g_subject} -name "*catalog.xml" -delete
	find ${g_working_dir}/${g_subject} -name "*starttime" -delete
		
	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Create a start_time file" ${step_percent}

	start_time_file="${g_working_dir}/${PIPELINE_NAME}.starttime"
	if [ -e "${start_time_file}" ]; then
		inform "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi

	# Sleep for 1 minute to make sure start_time file is created at least a
	# minute after any files copied or linked above.
	inform "Sleep for 1 minute before creating start_time file."
	sleep 1m || die 
	
	inform "Creating start time file: ${start_time_file}"
	touch ${start_time_file} || die 
	ls -l ${start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the scripts 
	# are created at least 1 minute after the start_time file
	inform "Sleep for 1 minute after creating start_time file."
	sleep 1m || die 

	# Step - Set up environment to run scripts
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up environment to run scripts" ${step_percent}

	# Source setup script to setup environment for running the script
	if [ -e "${g_setup_script}" ]; then
		inform "Sourcing ${g_setup_script} to set up environment"
		source ${g_setup_script}
	else
		inform "Set up environment script: ${g_setup_script}, DOES NOT EXIST"
		inform "ABORTING"
		exit 1
	fi

	# Step - run PostFix.sh script
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run PostFix.sh script" ${step_percent}

	postfix_cmd=""
	postfix_cmd+="${HCPPIPEDIR}/PostFix/PostFix.sh"
	postfix_cmd+=" --path=${g_working_dir} "
	postfix_cmd+=" --subject=${g_subject} "
	postfix_cmd+=" --fmri-name=${g_scan} "
	postfix_cmd+=" --high-pass=2000 "
	postfix_cmd+=" --template-scene-dual-screen=${HCPPIPEDIR}/PostFix/PostFixScenes/ICA_Classification_DualScreenTemplate.scene "
	postfix_cmd+=" --template-scene-single-screen=${HCPPIPEDIR}/PostFix/PostFixScenes/ICA_Classification_SingleScreenTemplate.scene "

	inform ""
	inform "postfix_cmd: ${postfix_cmd}"
	inform ""

	pushd ${g_working_dir}
	${postfix_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# Step - Show any newly created or modified files
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Show newly created or modified files" ${step_percent}
	
	inform "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# Step - Remove any files that are not newly created or modified
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Remove files not newly created or modified" ${step_percent}
	
	inform "The following files are being removed"
	find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete

	# Step - Complete Workflow
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
}

# Invoke the main function to get things started
main $@
