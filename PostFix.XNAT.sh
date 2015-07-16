#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # PostFix.XNAT.sh
#
# ## Copyright Notice
#
# Copyright (C) 2015 The Human Connectome Project
#
# * Washington University in St. Louis
# * University of Minnesota
# * Oxford University
#
# ## Author(s)
#
# * Timothy B. Brown, Neuroinformatics Research Group, 
#   Washington University in St. Louis
#
# ## Description
#
# This script runs the PostFix pipeline script from the Human 
# Connectome Project for a specified project, subject, session, and scan 
# in the ConnectomeDB (db.humanconnectome.org) XNAT database.
#
# The script is run not as an XNAT pipeline (under the control of the
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
# 
# * The data to be processed is retrieved from the specified XNAT database.
# * A new XNAT workflow ID is created to keep track of the processing steps.
# * That workflow ID is updated as processing steps occur, and marked as 
#   complete when the processing is finished.
# * The results of processing are placed back in the specified XNAT database.
# 
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU power, storage space), this script can 
# simply be invoked interactively.
#
#~ND~END~

# If any commands exit with a non-zero value, this script exits
set -e

echo "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for XNAT related utilities
# - for updating XNAT workflows
XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# home directory for XNAT pipeline engine installation
# - for utilities used to get XNAT session information,
#   retrieve XNAT data, and create an XNAT workflow
XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# Show script usage information 
usage()
{
    echo ""
    echo "  Run the HCP PostFix.sh pipeline script in an"
	echo "  XNAT-aware and XNAT-pipeline-like manner."
	echo ""
	echo "  Usage: PostFix.XNAT.sh <options>"
	echo ""
	echo "  Options: [ ] = optional, < > = user-supplied-value"
	echo ""
	echo "   [--help] : show usage information and exit"
	echo ""
	echo "    --user=<username>      : XNAT DB username"
	echo "    --password=<password>  : XNAT DB password"
	echo "    --server=<server>      : XNAT server (e.g. db.humanconnectome.org)"
	echo "    --project=<project>    : XNAT project (e.g. HCP_500)"
	echo "    --subject=<subject>    : XNAT subject ID within project (e.g. 100307)"
	echo "    --session=<session>    : XNAT session ID within project (e.g. 100307_3T)"
	echo "    --scan=<scan>          : Scan ID (e.g. rfMRI_REST1_LR)"
	echo "    --working-dir=<dir>    : Working directory in which to place retrieved data"
	echo "                             and in which to produce results"
	echo "    --jsession=<jsession>  : Session ID for already establish web session on"
	echo "                             the server"
	echo "   [--notify=<email>]      : Email address to which to send completion notification"
	echo "                             If not specified, no completion notification email is sent"
	echo "   [--start-step=<stepno>  : Step number at which to start. Defaults to 1" 
	echo ""
}

# Parse specified command line options and verify that required options are
# specified. "Return" the options to use in global variables.
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
	unset g_jsession
	unset g_notify_email
	unset g_start_step
	g_start_step=1

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
			--jsession=*)
				g_jsession=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--notify=*)
				g_notify_email=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--start-step=*)
				g_start_step=${argument/*=""}
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
		echo "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		echo "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_password: *******"
	fi

	if [ -z "${g_server}" ]; then
		echo "ERROR: server (--server=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		echo "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		echo "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		echo "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_session: ${g_session}"
	fi

	if [ -z "${g_scan}" ]; then
		echo "ERROR: scan (--scan=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_jsession}" ]; then
		echo "ERROR: jsession (--jsession=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_jsession: ${g_jsession}"
	fi

	echo "g_notify_email: ${g_notify_email}"

	if [ -z "${g_start_step}" ]; then
		echo "ERROR: starting step (--start-step=) required"
		error_count=$(( error_count + 1 ))
	else
		if ! [[ ${g_start_step} =~ ^[0-9]+$ ]]; then
			echo "ERROR: starting step must be numeric"
			error_count=$(( error_count + 1 ))
		else
			echo "g_start_step: ${g_start_step}"
		fi
	fi

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

# Show information about a specified XNAT Workflow
show_xnat_workflow()
{
	local workflow_id=${1}
	
	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--server="${g_server}" \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		show
}

# Update information (step id, step description, and percent complete)
# for a specified XNAT Workflow
update_xnat_workflow()
{
	local workflow_id=${1}
	local step_id=${2}
	local step_desc=${3}
	local percent_complete=${4}

	echo ""
	echo ""
	echo "---------- Step: ${step_id} "
	echo "---------- Desc: ${step_desc} "
	echo ""
	echo ""

	echo "update_xnat_workflow - workflow_id: ${workflow_id}"
	echo "update_xnat_workflow - step_id: ${step_id}"
	echo "update_xnat_workflow - set_desc: ${step_desc}"
	echo "update_xnat_workflow - percent_complete: ${percent_complete}"

	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--server="${g_server}" \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		update \
		--step-id="${step_id}" \
		--step-description="${step_desc}" \
		--percent-complete="${percent_complete}"
}

# Mark the specified XNAT Workflow as complete
complete_xnat_workflow()
{
	local workflow_id=${1}

	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--server="${g_server}" \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		complete
}

# Main processing 
#   Carry out the necessary steps to: 
#   - get prerequisite data for PostFix.sh
#   - run the script
#   - push only newly created or modified data back to the DB
#   - cleanup the working directory
#   - send an completion notification email if requested
main()
{
	get_options $@

	# Set up step counters
	total_steps=5
	current_step=0

	# Set up to run Python
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g ConnectomeDB_E1234)
	echo "Getting XNAT Session ID"
	get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=db.humanconnectome.org --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	echo "get_session_id_cmd: ${get_session_id_cmd}"
	sessionID=`${get_session_id_cmd}`
	echo "XNAT session ID: ${sessionID}"

	# Get XNAT Workflow ID
	server="https://db.humanconnectome.org/"
	echo "Getting XNAT workflow ID for this job from server: ${server}"
	get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Password ${g_password} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline PostFix -Status Queued -JSESSION ${g_jsession}"
	echo "get_workflow_id_cmd: ${get_workflow_id_cmd}"
	workflowID=`${get_workflow_id_cmd}`
	if [ $? -ne 0 ]; then
		echo "Fetching workflow failed. Aborting"
		exit 1
	fi
	echo "XNAT workflow ID: ${workflowID}"
	show_xnat_workflow ${workflowID}




	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ "${current_step}" -ge "${g_start_step}" ]; then

		update_xnat_workflow ${workflowID} ${current_step} "Create a start_time file" ${step_percent}
		
		start_time_file="${g_working_dir}/PostFix.starttime"
		if [ -e "${start_time_file}" ]; then
			echo "Removing old ${start_time_file}"
			rm -f ${start_time_file}
		fi
		
		echo "Creating start time file: ${start_time_file}"
		touch ${start_time_file}
		ls -l ${start_time_file}
		
	fi

	# Step - Sleep for 1 minute to make sure any files created or modified
	#        by the PostFix.sh script are created at least 1 
	#        minute after the start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ "${current_step}" -ge "${g_start_step}" ]; then

		update_xnat_workflow ${workflowID} ${current_step} "Sleep for 1 minute" ${step_percent}
		sleep 1m

	fi

	# Step - Run PostFix.sh script
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ "${current_step}" -ge "${g_start_step}" ]; then

		update_xnat_workflow ${workflowID} ${current_step} "Run PostFix.sh script" ${step_percent}
		
		# Source setup script to setup environment for running the script
		source ${SCRIPTS_HOME}/SetUpHCPPipeline_MSM_All.sh
		
		# Run PostFix.sh script
		${HCPPIPEDIR}/PostFix/PostFix.sh \
			--path=${g_working_dir} \
			--subject=${g_subject} \
			--fmri-name=${g_scan} \
			--high-pass=2000 \
			--template-scene-dual-screen=${HCPPIPEDIR}/PostFix/PostFixScenes/ICA_Classification_DualScreenTemplate.scene \
			--template-scene-single-screen=${HCPPIPEDIR}/PostFix/PostFixScenes/ICA_Classification_SingleScreenTemplate.scene

	fi




	# Step - Show any newly created or modified files
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ "${current_step}" -ge "${g_start_step}" ]; then

		update_xnat_workflow ${workflowID} ${current_step} "Show newly created or modified files" ${step_percent}

		echo "Newly created/modified files:"
		find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}

	fi



	# Step - Send notification email
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	if [ "${current_step}" -ge "${g_start_step}" ]; then

		if [ -n "${g_notify_email}" ]; then
			mail -s "PostFix Completion for ${g_subject}" ${g_notify_email} <<EOF
The PostFix.XNAT.sh run has completed for:
Project: ${g_project}
Subject: ${g_subject}
Session: ${g_session}
Scan:    ${g_scan}
EOF
		fi

	fi
}

# Invoke the main function to get things started
main $@

