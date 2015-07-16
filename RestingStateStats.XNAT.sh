#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # RestingStateStats.XNAT.sh
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
# This script runs the RestingStateStats pipeline script from the Human 
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
    echo "  Run the HCP RestingStateStats.sh pipeline script in an"
	echo "  XNAT-aware and XNAT-pipeline-like manner."
	echo ""
	echo "  Usage: RestingStateStats.XNAT.sh <options>"
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
#   - get prerequisite data for RestingStateStats.sh
#   - run the script
#   - push only newly created or modified data back to the DB
#   - cleanup the working directory
#   - send an completion notification email if requested
main()
{
	get_options $@

	# Set up step counters
	total_steps=12
	current_step=0

	# Command for running the XNAT Data Client
	xnat_data_client_cmd="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"

	# Command for running the XNAT REST Client
	# Note: XNAT Data Client should be used, but the version currently available for HCP use,
	# as specified above, seems to have a bug in it and doesn't allow downloading of the 
	# functionally preprocessed data or the ICA FIX processed data. Thus the use of the 
	# XNAT REST Client.  The XNAT REST Client takes much longer to download resources and
	# the time it takes to download the functionally preprocessed data is long enough that
	# the specified jsession expires during the download. Thus the use of the username 
	# and password in the downloading of data via the XNAT REST Client and the uploading
	# of data at the end.
	xnat_rest_client_cmd="java -Xmx2048m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-rest-client-1.6.2-SNAPSHOT.jar"

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
	get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Password ${g_password} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline RestingStateStats -Status Queued -JSESSION ${g_jsession}"
	echo "get_workflow_id_cmd: ${get_workflow_id_cmd}"
	workflowID=`${get_workflow_id_cmd}`
	if [ $? -ne 0 ]; then
		echo "Fetching workflow failed. Aborting"
		exit 1
	fi
	echo "XNAT workflow ID: ${workflowID}"
	show_xnat_workflow ${workflowID}
	
 	# Step - Get structurally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Get structurally preprocessed data from DB" ${step_percent}
	
	struct_preproc_uri="http://${g_server}"
	struct_preproc_uri+="/REST/projects/${g_project}"
	struct_preproc_uri+="/subjects/${g_subject}"
	struct_preproc_uri+="/experiments/${sessionID}"
	struct_preproc_uri+="/resources/Structural_preproc"
	struct_preproc_uri+="/files?format=zip"
	
	retrieval_cmd="${xnat_data_client_cmd} "
	retrieval_cmd+="-u ${g_user} "
	retrieval_cmd+="-p ${g_password} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-r ${struct_preproc_uri} "
	retrieval_cmd+="-o ${g_subject}_Structural_preproc.zip"
		
	pushd ${g_working_dir}
	
	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd}
	
	unzip ${g_subject}_Structural_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/Structural_preproc/files/* ${g_subject}
	rm -rf ${g_session}
	rm ${g_subject}_Structural_preproc.zip
	
	popd
	
 	# Step - Get functionally preprocessed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Get functionally preprocessed data from DB" ${step_percent}
	
	rest_client_host="http://${g_server}"
	
	func_preproc_uri="REST/projects/${g_project}"
	func_preproc_uri+="/subjects/${g_subject}"
	func_preproc_uri+="/experiments/${sessionID}"
	func_preproc_uri+="/resources/${g_scan}_preproc"
	func_preproc_uri+="/files?format=zip"
	
	retrieval_cmd="${xnat_rest_client_cmd} "
	retrieval_cmd+="-host ${rest_client_host} "
	retrieval_cmd+="-u ${g_user} "
	retrieval_cmd+="-p ${g_password} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-remote ${func_preproc_uri}"
	
	pushd ${g_working_dir}
	
	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd} > ${g_subject}_${g_scan}_Functional_preproc.zip
	
	unzip ${g_subject}_${g_scan}_Functional_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/${g_scan}_preproc/files/* ${g_subject}
	rm -rf ${g_session}
	rm ${g_subject}_${g_scan}_Functional_preproc.zip
	
	popd

 	# Step - Get FIX processed data from DB
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Get FIX processed data from DB" ${step_percent}
	
	rest_client_host="http://${g_server}"
	
	fix_proc_uri="REST/projects/${g_project}"
	fix_proc_uri+="/subjects/${g_subject}"
	fix_proc_uri+="/experiments/${sessionID}"
	fix_proc_uri+="/resources/${g_scan}_FIX"
	fix_proc_uri+="/files?format=zip"
	
	retrieval_cmd="${xnat_rest_client_cmd} "
	retrieval_cmd+="-host ${rest_client_host} "
	retrieval_cmd+="-u ${g_user} "
	retrieval_cmd+="-p ${g_password} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-remote ${fix_proc_uri}"
	
	pushd ${g_working_dir}
	
	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd} > ${g_subject}_${g_scan}_FIX_preproc.zip
	
	unzip ${g_subject}_${g_scan}_FIX_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/${g_scan}_FIX/files/* ${g_subject}/MNINonLinear/Results
	rm -rf ${g_session}
	rm ${g_subject}_${g_scan}_FIX_preproc.zip
	
	popd 

	# Step - Create a start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Create a start_time file" ${step_percent}
	
	start_time_file="${g_working_dir}/RestingStateStats.starttime"
	if [ -e "${start_time_file}" ]; then
		echo "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi
	
	echo "Creating start time file: ${start_time_file}"
	touch ${start_time_file}
	ls -l ${start_time_file}
	
	# Step - Sleep for 1 minute to make sure any files created or modified
	#        by the RestingStateStats.sh script are created at least 1 
	#        minute after the start_time file
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Sleep for 1 minute" ${step_percent}
	sleep 1m

	# Step - Run RestingStateStats.sh script
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Run RestingStateStats.sh script" ${step_percent}
	
	# Source setup script to setup environment for running the script
	source ${SCRIPTS_HOME}/SetUpHCPPipeline_MSM_All.sh
		
	# Run RestingStateStats.sh script
	${HCPPIPEDIR}/RestingStateStats/RestingStateStats.sh \
		--path=${g_working_dir} \
		--subject=${g_subject} \
		--fmri-name=${g_scan} \
		--high-pass=2000 \
		--low-res-mesh=32 \
		--final-fmri-res=2 \
		--brain-ordinates-res=2 \
		--smoothing-fwhm=2 \
		--output-proc-string="_hp2000_clean"
		
	# Step - Show any newly created or modified files
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Show newly created or modified files" ${step_percent}
	
	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# Step - Remove any files that are not newly created or modified
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	update_xnat_workflow ${workflowID} ${current_step} "Remove files not newly created or modified" ${step_percent}
	
	echo "NOT Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -not -newer ${start_time_file} -delete 
	
	# include removal of any empty directories
	find ${g_working_dir}/${g_subject} -type d -empty -delete

	# Step - Complete Workflow
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	complete_xnat_workflow ${workflowID}

	# Step - Send notification email
	echo "About to think about sending email"
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	
	echo "current_step: ${current_step}"
	echo "step_percent: ${step_percent}"
	echo "g_start_step: ${g_start_step}"
	
	echo "Should do this step"
	echo "g_notify_email: ${g_notify_email}"
	if [ -n "${g_notify_email}" ]; then
		echo "should be sending the mail now"
		mail -s "RestingStateStats Completion for ${g_subject}" ${g_notify_email} <<EOF
The RestingStateStats.XNAT.sh run has completed for:
Project: ${g_project}
Subject: ${g_subject}
Session: ${g_session}
Scan:    ${g_scan}
EOF
	fi
}

# Invoke the main function to get things started
main $@