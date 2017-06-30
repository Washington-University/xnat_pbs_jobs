#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # RestingStateStatsHCP7T.XNAT.sh
#
# ## Copyright Notice
#
# Copyright (C) 2016 The Human Connectome Project
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
# This script runs the RestingStatStats pipeline script from the 
# Human Connectome Project for a HCP7T subject.
#
# The script is run not as an XNAT pipeline (under the control of the 
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
#
# The data to be processed is retrieved via filesystem operations instead
# of using REST API calls to retrieve that data. So the database archive
# and resource directory structure is "known and used" by this script.
#
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU powere, storage space), this script can
# simply be invoked interactively.
#
#~ND~END~

PIPELINE_NAME="RestingStateStatsHCP7T"
SCRIPT_NAME="RestingStateStatsHCP7T.XNAT.sh"
XNAT_UTILS_HOME="${HOME}/pipeline_tools/xnat_utilities"

inform() 
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

usage()
{
	cat << EOF

Run the HCP RestingStateStats.sh pipeline script for an HCP 7T
subject in an XNAT-aware and XNAT-pipeline-like manner.

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --user=<username>       : XNAT DB username
   --password=<password>   : XNAT DB password
   --server=<server>       : XNAT server 
   --project=<project>     : XNAT project (e.g. HCP_Staging_7T)
   --subject=<subject>     : XNAT subject ID within project (e.g. 102311)
   --session=<session>     : XNAT session ID within project (e.g. 102311_7T)
   --structural-reference-project=<structural reference project>
                           : XNAT project containing the structural reference data 
   --structural-reference-session=<structural reference session>
                           : XNAT session ID within structural reference project
   --scan=<scan>           : Scan ID (e.g. rfMRI_REST1_PA)
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results
   --workflow-id=<id>      : XNAT Workflow ID to update as steps are completed
   --setup-script=<script> : Script to source to set up environment

EOF
}

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
				g_user=${argument#*=}
				index=$(( index + 1 ))
				;;
			--password=*)
				g_password=${argument#*=}
				index=$(( index + 1 ))
				;;
			--server=*)
				g_server=${argument#*=}
				index=$(( index + 1 ))
				;;
			--project=*)
				g_project=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			--session=*)
				g_session=${argument#*=}
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
				g_scan=${argument#*=}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			--workflow-id=*)
				g_workflow_id=${argument#*=}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option ${argument}"
				exit 1
				;;		
		esac

	done

	local error_msgs=""

	# check required parameters
	if [ -z "${g_user}" ]; then
		error_msgs+="\nERROR: user (--user=) required"
	else
		inform "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		error_msgs+="\nERROR: password (--password=) required"
	else
		inform "g_password: ***** password mask *****"
	fi

	if [ -z "${g_server}" ]; then
		error_msgs+="\nERROR: server (--server=) required"
	else
		inform "g_server: ${g_server}"
	fi

	if [ -z "${g_project}" ]; then
		error_msgs+="\nERROR: project (--project=) required"
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\nERROR: subject (--subject=) required"
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		error_msgs+="\nERROR: session (--session=) required"
	else
		inform "g_session: ${g_session}"
	fi

	if [ -z "${g_structural_reference_project}" ]; then
		error_msgs+="\nERROR: structural reference project (--structural-reference-project=) required"
	else
		inform "g_structural_reference_project: ${g_structural_reference_project}"
	fi

	if [ -z "${g_structural_reference_session}" ]; then
		error_msgs+="\nERROR: structural reference session (--structural-reference-session=) required"
	else
		inform "g_structural_reference_session: ${g_structural_reference_session}"
	fi

	if [ -z "${g_scan}" ]; then
		error_msgs+="\nERROR: scan (--scan=) required"
	else
		inform "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_workflow_id}" ]; then
		error_msgs+="\nERROR: workflow (--workflow-id=) required"
	else
		inform "g_workflow_id: ${g_workflow_id}"
	fi

	if [ -z "${g_setup_script}" ]; then
		error_msgs+="\nERROR: set up script (--setup-script=) required"
	else
		inform "g_setup_script: ${g_setup_script}"
	fi

	# check required environment variables
	if [ -z "${XNAT_PBS_JOBS}" ]; then
		error_msgs+="\nERROR: XNAT_PBS_JOBS environment variable must be set"
	else
		inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
	fi

	if [ -z "${SCRIPTS_HOME}" ]; then
		error_msgs+="\nERROR: SCRIPTS_HOME environment variable must be set"
	else
		inform "SCRIPTS_HOME: ${SCRIPTS_HOME}"
	fi

	if [ -z "${HOME}" ]; then
		error_msgs+="\nERROR: HOME environment variable must be set"
	else
		inform "HOME: ${HOME}"
	fi

	if [ -z "${XNAT_ARCHIVE_ROOT}" ]; then
		error_msgs+="\nERROR: XNAT_ARCHIVE_ROOT environment variable must be set"
	else
		inform "XNAT_ARCHIVE_ROOT: ${XNAT_ARCHIVE_ROOT}"
	fi

	if [ ! -z "${error_msgs}" ]; then
		usage
		echo -e ${error_msgs}
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
	inform "Job started on `hostname` at `date`"

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	get_options $@

	# Create a start_time file
	inform "Create a start time file"
	start_time_file=${g_working_dir}/${PIPELINE_NAME}.starttime
	if [ -e "${start_time_file}" ]; then
		inform "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi

	# Sleep for 1 minute to make sure start time file is created at least a
	# minute after any files retrieved in the "get data" job
	inform "Sleep for 1 minute before creating start time file."
	sleep 1m || die

	# Create start time file
	inform "Creating start time file: ${start_time_file}"
	touch ${start_time_file} || die
	ls -l ${start_time_file}

	# Sleep for 1 minute to make sure any files created or modified by the scripts
	# are created at least 1 minute after the start time file
	inform "Sleep for 1 minute after creating start time file."
	sleep 1m || die

	# Set up to run EPD Python 2
	inform "Setting up to run EPD Python 2"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	# Set up to use XNAT workflow utilities
	inform "Setting up to use XNAT workflow utilities"
	source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh

	# Set up step counters
	total_steps=2
	current_step=0

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# Set up environment to run scripts
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	# Source set up script
	source ${g_setup_script}

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up environment to run scripts" ${step_percent}

	# Run RestingStateStats.sh script
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	# Set up variables to pass in to RestingStateStats.sh
	RegName="NONE"
	OrigHighPass="2000"
	LowResMesh="32"
	FinalfMRIResolution="1.60"
	BrainOrdinatesResolution="2"
	SmoothingFWHM="2"
	OutputProcSTRING="_hp2000_clean"
	dlabelFile="NONE"
	MatlabRunMode="0" # Compiled Matlab
	BCMode="NONE" # One of REVERT (revert bias field correction), NONE (don't change bias field correction), CORRECT (revert original bias field correction and apply new one)
	OutSTRING="stats"
	WM="${HCPPIPEDIR}/global/config/FreeSurferWMRegLut.txt"
	CSF="${HCPPIPEDIR}/global/config/FreeSurferCSFRegLut.txt"

	# determine fMRI name
	inform "Determine fMRI name"
	phase_encoding_dir="${g_scan##*_}"
	inform "phase_encoding_dir: ${phase_encoding_dir}"

	base_fmriname="${g_scan%_*}"
	inform "base_fmriname: ${base_fmriname}"

	fmriname="${base_fmriname}_7T_${phase_encoding_dir}"
	inform "fmriname: ${fmriname}"

	# Run RestingStateStats.sh script
	cmd=${HCPPIPEDIR}/RestingStateStats/RestingStateStats.sh
	cmd+=" --path=${g_working_dir} "
	cmd+=" --subject=${g_subject} "
	cmd+=" --fmri-name=${fmriname} "
	cmd+=" --high-pass=${OrigHighPass} "
	cmd+=" --reg-name=${RegName} "
	cmd+=" --low-res-mesh=${LowResMesh} "
	cmd+=" --final-fmri-res=${FinalfMRIResolution} "
	cmd+=" --brain-ordinates-res=${BrainOrdinatesResolution} "
	cmd+=" --smoothing-fwhm=${SmoothingFWHM} "
	cmd+=" --output-proc-string=${OutputProcSTRING} "
	cmd+=" --dlabel-file=${dlabelFile} "
	cmd+=" --matlab-run-mode=${MatlabRunMode} "
	cmd+=" --bc-mode=${BCMode} "
	cmd+=" --out-string=${OutSTRING} "
	cmd+=" --wm=${WM} "
	cmd+=" --csf=${CSF} "

	inform "About to issue the following cmd"
	inform "${cmd}"

	${cmd}
	if [ $? -ne 0 ]; then
		die
 	fi

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run RestingStateStats.sh script" ${step_percent}

	# Complete the workflow
	xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
}

# Invoke the main to get things started
main $@
