#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # DiffusionPreprocessingHCP_Eddy_repol.XNAT.sh
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
# This script runs the Diffusion Preprocessing pipeline Eddy phase 
# consisting of the DiffPreprocPipeline_Eddy.sh pipeline script from
# the Human Connectome Project for a specified project, subject, session,
# in the ConnectomeDB (db.humanconnectome.org) XNAT database.
#
# 
# THIS VERSION INCLUDES COMMAND LINE OPTIONS FOR PERFORMING OUTLIER REPLACEMENT
#
#
# The script is run not as an XNAT pipeline (under the control of the
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
# 
# The data to be processed are assumed to have already been retrieved 
# by the PreEddy phase. This script also assumes that the PreEddy phase
# has already been run on the specified working directory.
#
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU power, storage space), this script can 
# simply be invoked interactively.
#
# Typical Run Time: 1 - 2 hrs
#
#~ND~END~

echo "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=${HOME}/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
echo "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=${PIPELINE_TOOLS_HOME}/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# source XNAT workflow utility functions
source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh

# set up to run Python
source ${SCRIPTS_HOME}/epd-python_setup.sh

# Parse specified command line options and verify that required options are 
# specified. "Return" the options to use in global variables
get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_server
	unset g_subject
	unset g_working_dir
	unset g_workflow_id

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--help)
				#usage
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
			--subject=*)
				g_subject=${argument/*=/""}
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
			*)
				#usage
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

	if [ -z "${g_subject}" ]; then
		echo "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_subject: ${g_subject}"
	fi

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_workflow_id}" ]; then
		echo "ERROR: workflow ID (--workflow-id=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_workflow_id: ${g_workflow_id}"
	fi

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
#   Carry out the necessary steps to:
#   - run the DiffPreprocPipeline_Eddy.sh script
main()
{
	get_options $@

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"

	# Set up step counters
	total_steps=12
	current_step=5

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# ----------------------------------------------------------------------------------------------
	# Step - Set up to run DiffPreprocPipeline_Eddy.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up to run DiffPreprocPipeline_Eddy.sh script" ${step_percent}
	
	# Source setup script to setup environment for running the script

	setup_file="${SCRIPTS_HOME}/SetUpHCPPipeline_DiffusionPreprocHCP_repol.sh"
	if [ ! -e "${setup_file}" ] ; then
		echo "setup_file: ${setup_file} DOES NOT EXIST - ABORTING"
		die
	fi

	echo "--- sourcing setup file: ${setup_file}"
	source "${setup_file}"

	# ----------------------------------------------------------------------------------------------
	# Step - Run the DiffPreprocPipeline_Eddy.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the DiffPreprocPipeline_Eddy.sh script" ${step_percent}
	
	Eddy_cmd=""
	Eddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_Eddy.sh"
	Eddy_cmd+=" --path=${g_working_dir}"
	Eddy_cmd+=" --subject=${g_subject}"
	Eddy_cmd+=" --detailed-outlier-stats=True"
	Eddy_cmd+=" --replace-outliers=True"
	Eddy_cmd+=" --nvoxhp=2000"
	Eddy_cmd+=" --sep_offs_move=True"
	Eddy_cmd+=" --rms=True"
	Eddy_cmd+=" --ff=10"
	Eddy_cmd+=" --dont_peas"
	Eddy_cmd+=" --fwhm=0"

	echo ""
	echo "Eddy_cmd: ${Eddy_cmd}"
	echo ""

	${Eddy_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
}

# Invoke the main function to get things started
main $@
