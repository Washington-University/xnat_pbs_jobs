#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # DiffusionPreprocessingHCP_PreEddy.XNAT.sh
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
# This script runs the Diffusion Preprocessing pipeline PreEddy phase 
# consisting of the DiffPreprocPipeline_PreEddy.sh pipeline script from
# the Human Connectome Project for a specified project, subject, session,
# in the ConnectomeDB (${XNAT_PBS_JOBS_XNAT_SERVER}) XNAT database.
#
# The script is run not as an XNAT pipeline (under the control of the
# XNAT Pipeline Engine), but in an "XNAT-aware" and "pipeline-like" manner.
# 
# The data to be processed are retrieved via filesystem operations instead
# of using REST API calls. So the database archive and resource directory 
# structure is "known and used" by this script.
# 
# This script can be invoked by a job submitted to a worker or execution
# node in a cluster, e.g. a Sun Grid Engine (SGE) managed or Portable Batch
# System (PBS) managed cluster. Alternatively, if the machine being used
# has adequate resources (RAM, CPU power, storage space), this script can 
# simply be invoked interactively.
#
# Typical Run Time: 5 - 6 hrs
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

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# source XNAT workflow utility functions
source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh

# source utility functions for getting data
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

# set up to run Python
source ${SCRIPTS_HOME}/epd-python_setup.sh

RLLR_POSITIVE_DIR="RL"
RLLR_NEGATIVE_DIR="LR"

PAAP_POSITIVE_DIR="PA"
PAAP_NEGATIVE_DIR="AP"

TESLA_SPEC="3T"

# Show script usage information
usage()
{
	cat <<EOF

Run the HCP Diffusion Preprocessing pipeline PreEddy phase script 
(DiffPreprocPipeline_PreEddy.sh) in an XNAT-aware and 
XNAT-pipeline-like manner.

Usage: DiffusionPreprocessingHCP_PreEddy.XNAT.sh PARAMETER...

PARAMETERs are: [ ] = optional, < > = user-supplied-value
  [--help]              show usage information and exit with a non-zero return code
  --user=<username>     XNAT DB username
  --password=<password> XNAT DB password
  --server=<server>     XNAT server (e.g. ${XNAT_PBS_JOBS_XNAT_SERVER})
  --project=<project>   XNAT project (e.g. HCP_500)
  --subject=<subject>   XNAT subject ID within project (e.g. 100307)
  --session=<session>   XNAT session ID within project (e.g. 100307_3T)
  --working-dir=<dir>   Working directory in which to place retrieved data
                        and in which to produce results
  --workflow-id=<id>    XNAT Workflow ID to update as steps are completed
  --phase-encoding-dir=<dir-indication>"
                        One of {RLLR, PAAP}"

Return Status Value:

  0                     help was not requested, all parameters were properly
                        formed, all required parameters were provided, and
                        no processing failure was detected
  Non-zero              Otherwise - help requested, malformed parameters,
                        some required parameters not provided, or a processing
                        failure was detected
 
EOF
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
	unset g_working_dir
	unset g_workflow_id
	unset g_phase_encoding_dir

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
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--workflow-id=*)
				g_workflow_id=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--phase-encoding-dir=*)
				g_phase_encoding_dir=${argument/*=/""}
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

	if [ -z "${g_phase_encoding_dir}" ]; then
		echo "ERROR: phase encoding dir specifier (--phase-encoding-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		if [ "${g_phase_encoding_dir}" != "RLLR" ] ; then
			if [ "${g_phase_encoding_dir}" != "PAAP" ] ; then
				echo "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dir}"
				error_count=$(( error_count + 1 ))
			fi
		fi
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

get_scan_data()
{
	local resource_name="${1}"
	local file_name="${2}"
	local item_name="${3}"
	
	local result=`${XNAT_UTILS_HOME}/xnat_scan_info -s "${XNAT_PBS_JOBS_XNAT_SERVER}" -u ${g_user} -p ${g_password} -pr ${g_project} -su ${g_subject} -se ${g_session} -r "${resource_name}" get_data -f "${file_name}" -i "${item_name}"`
	echo ${result}
}

# Main processing
#   Carry out the necessary steps to:
#   - get prerequisite data for the Diffusion Preprocessing pipeline
#   - run the DiffPreprocPipeline_PreEddy.sh script
main()
{
	get_options $@

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"

	# Set up step counters
	total_steps=12
	current_step=0

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# ----------------------------------------------------------------------------------------------
	# Step - Link Structurally preprocessed data from DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Structurally preprocessed data from DB" ${step_percent}

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
 	# Step - Link unprocessed data from DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link unprocessed data from DB" ${step_percent}

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
	# Step - Create a start_time file
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Create a start_time file" ${step_percent}
	
	start_time_file="${g_working_dir}/DiffusionPreprocessingHCP.starttime"
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

	# Sleep for 1 minute to make sure any files created or modified by the scripts 
	# are created at least 1 minute after the start_time file
	echo "Sleep for 1 minute after creating start_time file."
	sleep 1m || die 

	# ----------------------------------------------------------------------------------------------
	# Step - Set up to run DiffPreprocPipeline_PreEddy.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up to run DiffPreprocPipeline_PreEddy.sh script" ${step_percent}
	
	# Source setup script to setup environment for running the script

	setup_file=${XNAT_PBS_JOBS}/DiffusionPreprocessingHCP/SetUpHCPPipeline_DiffusionPreprocHCP.sh
	if [ ! -e "${setup_file}" ] ; then
		echo "setup_file: ${setup_file} DOES NOT EXIST - ABORTING"
		die
	fi

	echo "--- sourcing setup file: ${setup_file}"
	source "${setup_file}"

	echo "--- determining what positive and negative DWI files are available"
	# figure out what positive and negative DWI files are available

	if [ "${g_phase_encoding_dir}" = "RLLR" ] ; then
		positive_dir=${RLLR_POSITIVE_DIR}
		negative_dir=${RLLR_NEGATIVE_DIR}
	elif [ "${g_phase_encoding_dir}" = "PAAP" ] ; then
		positive_dir=${PAAP_POSITIVE_DIR}
		negative_dir=${PAAP_NEGATIVE_DIR}
	else
		echo "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dir}"
		exit 1
	fi

	# build the posData string and the echoSpacing while we're at it
	positive_scans=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir*_${positive_dir}.nii.gz" | sort`
	posData=""
	posData_count=0
	for pos_scan in ${positive_scans} ; do
		if [ -z "${posData}" ] ; then
			# get echo spacing from the first DWI scan we encounter
			short_name=${pos_scan##*/}
			echoSpacing=`get_scan_data Diffusion_unproc ${short_name} "parameters/echoSpacing"`
			echoSpacing=`echo "${echoSpacing} 1000.0" | awk '{printf "%.12f", $1 * $2}'`
			echo "echoSpacing: ${echoSpacing}"
		else
			# this is not the first positive DWI scan we've encountered, so add a separator to the posData string we are building
			posData+="@"
		fi
		posData+="${pos_scan}"
		posData_count=$(( posData_count + 1 ))
	done
	echo "posData: ${posData}"
	echo "posData_count: ${posData_count}"

	# build the negData string
	negative_scans=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir*_${negative_dir}.nii.gz" | sort`
	negData=""
	negData_count=0
	for neg_scan in ${negative_scans} ; do
		if [ ! -z "${negData}" ] ; then
			# this is not the first negative DWI scan we've encountered, so add a separator to the negData string we are building
			negData+="@"
		fi
		negData+="${neg_scan}"
		negData_count=$(( negData_count + 1 ))
	done
	echo "negData: ${negData}"
	echo "negData_count: ${negData_count}"

	if [ "${posData_count}" -ne "${negData_count}" ]; then

		posData=""
		negData=""
		for diff_directions in 95 96 97 ; do
			pos_scan=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir${diff_directions}_${positive_dir}.nii.gz"`
			echo "pos_scan: ${pos_scan}"

			if [ -n "${posData}" ]; then
				posData+="@"
			fi

			if [ -n "${pos_scan}" ]; then
				posData+="${pos_scan}"
			else
				posData+="EMPTY"
			fi

			neg_scan=`find ${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/Diffusion -maxdepth 1 -name "${g_subject}_${TESLA_SPEC}_DWI_dir${diff_directions}_${negative_dir}.nii.gz"`
			echo "neg_scan: ${neg_scan}"

			if [ -n "${negData}" ]; then
				negData+="@"
			fi

			if [ -n "${neg_scan}" ]; then
				negData+="${neg_scan}"
			else
				negData+="EMPTY"
			fi

		done

	fi

	echo "posData: ${posData}"
	echo "negData: ${negData}"

	# ----------------------------------------------------------------------------------------------
	# Step - Run the DiffPreprocPipeline_PreEddy.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the DiffPreprocPipeline_PreEddy.sh script" ${step_percent}

	PreEddy_cmd=""
	PreEddy_cmd+="${HCPPIPEDIR}/DiffusionPreprocessing/DiffPreprocPipeline_PreEddy.sh"
 	PreEddy_cmd+=" --path=${g_working_dir}"
 	PreEddy_cmd+=" --subject=${g_subject}"
	
	if [ "${g_phase_encoding_dir}" = "RLLR" ] ; then
		PreEddy_cmd+=" --PEdir=1"
	elif [ "${g_phase_encoding_dir}" = "PAAP" ] ; then
		PreEddy_cmd+=" --PEdir=2"
	else
		echo "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dir}"
		exit 1
	fi

	PreEddy_cmd+=" --posData=${posData}"
	PreEddy_cmd+=" --negData=${negData}"
	PreEddy_cmd+=" --echospacing=${echoSpacing}"
	#PreEddy_cmd+=" --printcom=''"

	echo ""
	echo "PreEddy_cmd: ${PreEddy_cmd}"
	echo ""

	${PreEddy_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
}

# Invoke the main function to get things started
main $@

