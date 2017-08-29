#!/bin/bash

PIPELINE_NAME="IcaFixProcessingHCP7T"
SCRIPT_NAME="IcaFixProcessingHCP7T.XNAT.sh"

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

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline

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
	unset g_scan
	unset g_working_dir
	unset g_workflow_id
	unset g_xnat_session_id
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
			--structural-reference-project=*)
				g_structural_reference_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--structural-reference-session=*)
				g_structural_reference_session=${argument/*=/""}
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
			--xnat-session-id=*)
				g_xnat_session_id=${argument/*=/""}
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
		inform "No workflow ID specified. Will skip workflow updates."
	else
		inform "g_workflow_id: ${g_workflow_id}"
	fi

	if [ -z "${g_scan}" ] ; then
		inform "ERROR: --scan= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_scan: ${g_scan}"
	fi
	
	if [ -z "${g_xnat_session_id}" ] ; then
		inform "ERROR: --xnat-session-id= required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_xnat_session_id: ${g_xnat_session_id}"
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
	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	else
		inform "FAILING"
	fi
	exit 1
}

update_steps()
{
	local current_step=${1}
	local msg=${2}
	local step_percent=${3}

	inform "---------- Step Information: Begin ----------"
	inform "Current Step: ${current_step}"
	inform "   Step Desc: ${msg}"
	inform "Step Percent: ${step_percent}"
	inform "---------- Step Information: End ------------"
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

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	fi

	# Step - Link functionally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Link functionally preprocessed data from DB" ${step_percent}
	else
		update_steps ${current_step} "Link functionally preprocessed data from DB" ${step_percent}
	fi

	preproc_scan=${g_scan%_7T*}${g_scan##*_7T}
	inform "preproc_scan: ${preproc_scan}"
	link_hcp_func_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" \
		"${g_session}" "${preproc_scan}" "${g_working_dir}"

	# Step - Link Supplemental Structurally preprocessed data from DB
	#      - the higher resolution greyordinates space
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Link supplemental structurally preprocessed data from DB" ${step_percent}
	else
		update_steps ${current_step} "Link supplemental structurally preprocessed data from DB" ${step_percent}
	fi
	
	link_hcp_supplemental_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" \
		"${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link Structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Link Structurally preprocessed data from DB" ${step_percent}
	else
		update_steps ${current_step} "Link Structurally preprocessed data from DB" ${step_percent}
	fi

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
		"${g_structural_reference_session}" "${g_working_dir}"

	# Step - Link unprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Link unprocessed data from DB" ${step_percent}
	else
		update_steps ${current_step} "Link unprocessed data from DB" ${step_percent}
	fi

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" \
		"${g_structural_reference_session}" "${g_working_dir}"
	link_hcp_7T_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" \
		"${g_working_dir}"
	link_hcp_7T_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_7T_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Create a start_time file" ${step_percent}
	else
		update_steps ${current_step} "Create a start_time file" ${step_percent}
	fi

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

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Set up environment to run scripts" ${step_percent}
	else
		update_steps ${current_step} "Set up environment to run scripts" ${step_percent}
	fi

	# Source setup script to setup environment for running the script
	inform "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}

	#inform "Sourcing ${SCRIPTS_HOME}/fsl5_setup.sh"
	#source ${SCRIPTS_HOME}/fsl5_setup.sh

	inform "Sourcing ${SCRIPTS_HOME}/R_setup.sh"
	source ${SCRIPTS_HOME}/R_setup.sh

	# Step - run hcp_fix
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "run hcp_fix" ${step_percent}
	else
		update_steps ${current_step} "run hcp_fix" ${step_percent}
	fi

	icafix_cmd=""
	icafix_cmd+="${HCPPIPEDIR_FIX}/hcp_fix"
	icafix_cmd+=" ${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/${g_scan}.nii.gz"
	icafix_cmd+=" 2000"
	icafix_cmd+=" ${FSL_FIXDIR}/training_files/HCP7T_hp2000.RData"

	inform ""
	inform "icafix_cmd: ${icafix_cmd}"
	inform ""

	pushd ${g_working_dir}
	${icafix_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# Step - run ReApplyFixPipeline for 59k low res mesh
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "run ReApplyFixPipeline for 59k low res mesh" ${step_percent}
	else
		update_steps ${current_step} "run ReApplyFixPipeline for 59k low res mesh" ${step_percent}
	fi

	reapplyfix_cmd=""
	reapplyfix_cmd+="${HCPPIPEDIR}/ReApplyFix/ReApplyFixPipeline.sh"
	reapplyfix_cmd+=" --path=${g_working_dir} "
	reapplyfix_cmd+=" --subject=${g_subject} "
	reapplyfix_cmd+=" --fmri-name=${g_scan} "
	reapplyfix_cmd+=" --high-pass=2000 "
	reapplyfix_cmd+=" --reg-name=MSMSulc "
	reapplyfix_cmd+=" --low-res-mesh=59 "

	inform ""
	inform "reapplyfix_cmd: ${reapplyfix_cmd}"
	inform ""

	pushd ${g_working_dir}
	${reapplyfix_cmd}
	if [ $? -ne 0 ]; then
		die
	fi
	popd

	# Step - Show any newly created or modified files
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Show newly created or modified files" ${step_percent}
	else
		update_steps ${current_step} "Show newly created or modified files" ${step_percent}
	fi
	
	inform "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# Step - Remove any files that are not newly created or modified
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	
	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Remove files not newly created or modified" ${step_percent}
	else
		update_steps ${current_step} "Remove files not newly created or modified" ${step_percent}
	fi
	
	inform "The following files are being removed"
	find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete

	# Step - Move data up in directory tree to match what is expected to be in pushed resource
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
							 ${current_step} "Move data up in directory tree" ${step_percent}
	else
		update_steps ${current_step} "Move data up in directory tree" ${step_percent}
	fi

	mv --verbose ${g_working_dir}/${g_subject}/MNINonLinear/Results/rfMRI_REST* ${g_working_dir}
	mv --verbose ${g_working_dir}/${g_subject}/MNINonLinear/Results/tfMRI_MOVIE* ${g_working_dir}
	rm --verbose --recursive --force ${g_working_dir}/${g_subject}
	mkdir --verbose ${g_working_dir}/${g_subject}
	mv --verbose ${g_working_dir}/rfMRI_REST* ${g_working_dir}/${g_subject}
	mv --verbose ${g_working_dir}/tfMRI_MOVIE* ${g_working_dir}/${g_subject}

	# Step - Complete Workflow
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ -n "${g_workflow_id}" ]; then
		xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
	else
		update_steps ${current_step} "Complete" ${step_percent}
	fi
}

# Invoke the main function to get things started
main $@
