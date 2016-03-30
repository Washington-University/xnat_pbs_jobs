#!/bin/bash

echo "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to set up the environment
SETUP_SCRIPTS_HOME=${HOME}/SCRIPTS
echo "SETUP_SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
echo "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=${PIPELINE_TOOLS_HOME}/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"



# # source function libraries
# source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh




# # Show script usage information
# usage()
# {
# 	echo ""
# 	echo "TBW"
# 	echo ""
# }

# # Parse specified command line options and verify that required options are
# # specified. "Return" the options to use in global variables
# get_options()
# {
# 	local arguments=($@)

# 	# initialize global output variables
# 	unset g_user
# 	unset g_password
# 	unset g_server
# 	unset g_workflow_id
# 	unset g_project
# 	unset g_subject
# 	unset g_session
# 	unset g_working_dir
# 	unset g_xnat_session_id

# 	# parse arguments
# 	local num_args=${#arguments[@]}
# 	local argument
# 	local index=0

# 	while [ ${index} -lt ${num_args} ]; do
# 		argument=${arguments[index]}

# 		case ${argument} in
# 			--help)
# 				usage
# 				exit 1
# 				;;
# 			--user=*)
# 				g_user=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--password=*)
# 				g_password=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--server=*)
# 				g_server=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--workflow-id=*)
# 				g_workflow_id=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--project=*)
# 				g_project=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--subject=*)
# 				g_subject=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--session=*)
# 				g_session=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--working-dir=*)
# 				g_working_dir=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			--xnat-session-id=*)
# 				g_xnat_session_id=${argument/*=/""}
# 				index=$(( index + 1 ))
# 				;;
# 			*)
# 				usage
# 				echo "ERROR: unrecognized option: ${argument]"
# 				echo ""
# 				exit 1
# 				;;
# 		esac
# 	done

# 	local error_count=0

# 	# check required parameters
# 	if [ -z "${g_user}" ]; then
# 		echo "ERROR: user (--user=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_user: ${g_user}"
# 	fi

# 	if [ -z "${g_password}" ]; then
# 		echo "ERROR: password (--password=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_password: *******"
# 	fi

# 	if [ -z "${g_server}" ]; then
# 		echo "ERROR: server (--server=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_server: ${g_server}"
# 	fi

# 	if [ -z "${g_workflow_id}" ]; then
# 		echo "ERROR: workflow ID (--workflow-id=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_workflow_id: ${g_workflow_id}"
# 	fi

# 	if [ -z "${g_project}" ]; then
# 		echo "ERROR: project (--project=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_project: ${g_project}"
# 	fi

# 	if [ -z "${g_subject}" ]; then
# 		echo "ERROR: subject (--subject=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_subject: ${g_subject}"
# 	fi

# 	if [ -z "${g_session}" ]; then
# 		echo "ERROR: session (--session=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_session: ${g_session}"
# 	fi

# 	if [ -z "${g_working_dir}" ]; then
# 		echo "ERROR: working directory (--working-dir=) required"
# 		error_count=$(( error_count + 1 ))
# 	else
# 		echo "g_working_dir: ${g_working_dir}"
# 	fi

# 	if [ -z "${g_xnat_session_id}" ] ; then
# 		echo "ERROR: --xnat-session-id= required"
# 		error_count=$(( error_count + 1 ))
# 	fi
# 	echo "g_xnat_session_id: ${g_xnat_session_id}"

# 	if [ ${error_count} -gt 0 ]; then
# 		echo "For usage information, use --help"
# 		exit 1
# 	fi
# }

# die()
# {
# 	xnat_workflow_fail ${g_server} ${g_user} ${g_password} ${g_workflow_id}
# 	exit 1
# }

# Main processing
#   Carry out the necessary steps
main()
{
#	get_options $@

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"



# 	# Set up step counters
# 	total_steps=1000 # TODO: Change to match actual number of steps
# 	current_step=0

# 	# Set up to run Python
# 	echo "Setting up to run Python"
# 	source ${SETUP_SCRIPTS_HOME}/epd-python_setup.sh

# 	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

# 	# ----------------------------------------------------------------------------------------------
# 	# Step - Link Structurally preprocessed data from DB
# 	# ----------------------------------------------------------------------------------------------


# 	# Try without this first?

# 	current_step=$(( current_step + 1 ))
# 	step_percent=$(( (current_step * 100) / total_steps ))

# 	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
# 		${current_step} "Link Structurally preprocessed data from DB" ${step_percent}

# 	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

# 	# ----------------------------------------------------------------------------------------------
#  	# Step - Link unprocessed data from DB
# 	# ----------------------------------------------------------------------------------------------
# 	current_step=$(( current_step + 1 ))
# 	step_percent=$(( (current_step * 100) / total_steps ))

# 	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
# 		${current_step} "Link unprocessed data from DB" ${step_percent}

# 	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"



# #	link_hcp_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
# #	link_hcp_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
# #	link_hcp_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

# 	# ----------------------------------------------------------------------------------------------
# 	# Step 3 - Create a start_time file
# 	# ----------------------------------------------------------------------------------------------
# 	current_step=$(( current_step + 1 ))
# 	step_percent=$(( (current_step * 100) / total_steps ))

# 	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
# 		${current_step} "Create a start_time file" ${step_percent}

# 	start_time_file="${g_working_dir}/AddResolutionHCP7T.starttime"
# 	if [ -e "${start_time_file}" ]; then
# 		echo "Removing old ${start_time_file}"
# 		rm -f ${start_time_file}
# 	fi

# 	# Sleep for 1 minute to make sure start_time file is created at least a
# 	# minute after any files copied or linked above.
# 	echo "Sleep for 1 minute before creating start_time file."
# 	sleep 1m || die 
	
# 	echo "Creating start time file: ${start_time_file}"
# 	touch ${start_time_file} || die 
# 	ls -l ${start_time_file}

# 	# Sleep for 1 minute to make sure any files created or modified by the scripts 
# 	# are created at least 1 minute after the start_time file
# 	echo "Sleep for 1 minute after creating start_time file."
# 	sleep 1m || die 




}

# Invoke the main function to get things started
main $@