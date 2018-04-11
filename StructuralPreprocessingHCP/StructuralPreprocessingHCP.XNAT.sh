#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # StructuralPreprocessingHCP.XNAT.sh
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
# This script runs the Structural Preprocessing pipeline consisting of the 
# PreFreeSurfer, FreeSurfer, and PostFreeSurfer pipeline scripts from the Human 
# Connectome Project for a specified project, subject, session, and scan 
# in the ConnectomeDB (${XNAT_PBS_JOBS_XNAT_SERVER}) XNAT database.
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
# has adequate resources (RAM, CPU power, storage space), this script can 
# simply be invoked interactively.
#
#~ND~END~

echo "Job started on `hostname` at `date`"

if [ -z "${SCRIPTS_HOME}" ]; then
	echo "ERROR: SCRIPTS_HOME environment variable must be set!"
	exit 1
fi

# home directory for scripts to be sourced to setup the environment
SETUP_SCRIPTS_HOME=${SCRIPTS_HOME}
echo "SETUP_SCRIPTS_HOME: ${SETUP_SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
echo "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=/export/HCP/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
echo "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=/export/HCP/pipeline

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
echo "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# Default script for setting up environment for running HCP Pipeline Scripts
DEFAULT_SETUP_SCRIPT="${SETUP_SCRIPTS_HOME}/SetUpHCPPipeline_StructuralPreprocHCP.sh"

# "base" of file name for first T1w scan
FIRST_T1W_FILE_NAME_BASE="T1w_MPR1"

# "base" of file name for second T1w scan
SECOND_T1W_FILE_NAME_BASE="T1w_MPR2"

# "base" of file name for first T2w scan
FIRST_T2W_FILE_NAME_BASE="T2w_SPC1"

# "base" of file name for second T2w scan
SECOND_T2W_FILE_NAME_BASE="T2w_SPC2"

# database resources suffix for unprocessed data
UNPROC_SUFFIX="_unproc"

# file name extension for compressed NIFTI fiiles
COMPRESSED_NIFTI_EXTENSION=".nii.gz"

# part of file name that indicates a Siemens Gradient Echo Magnitude Fieldmap file
MAG_FIELDMAP_NAME="FieldMap_Magnitude"

# part of file name that indicates a Siemens Gradient Echo Phase Fieldmap file
PHASE_FIELDMAP_NAME="FieldMap_Phase"

# part of file name that indicates a Spin Echo Fieldmap file
SPIN_ECHO_FIELDMAP_NAME="SpinEchoFieldMap"

# For phase encoding directions RL and LR, which one is the "positive" direction
RLLR_POSITIVE_DIR="RL"

# For phase encoding directions RL and LR, which one is the "negative" direction
RLLR_NEGATIVE_DIR="LR"

# For phase encoding directions PA and AP, which one is the "positive" direction
PAAP_POSITIVE_DIR="PA"

# For phase encoding directions PA and AP, which one is the "negative" direction
PAAP_NEGATIVE_DIR="AP"

# part of file name that indicates the Tesla rating for the scanner
TESLA_SPEC="3T"

# Show script usage information
usage()
{
	echo ""
	echo "  Run the HCP Structural Preprocessing pipeline scripts (PreFreeSurferPipeline.sh, "
	echo "  FreeSurferPipeline.sh, and PostFreeSurferPipeline.sh) in an XNAT-aware and "
	echo "  XNAT-pipeline-like manner."
	echo ""
	echo "  Usage: StructuralPreprocessingHCP.XNAT.sh <options>"
	echo ""
	echo "  Options: [ ] = optional, < > = user-supplied-value"
	echo ""
	echo "   [--help] : show usage information and exit"
	echo ""
	echo "    --user=<username>        : XNAT DB username"
	echo "    --password=<password>    : XNAT DB password"
	echo "    --server=<server>        : XNAT server (e.g. ${XNAT_PBS_JOBS_XNAT_SERVER})"
	echo "    --project=<project>      : XNAT project (e.g. HCP_500)"
	echo "    --subject=<subject>      : XNAT subject ID within project (e.g. 100307)"
	echo "    --session=<session>      : XNAT session ID within project (e.g. 100307_3T)"
	echo "    --working-dir=<dir>      : Working directory in which to place retrieved data"
	echo "                               and in which to produce results"
	echo "    --workflow-id=<id>       : XNAT Workflow ID to update as steps are completed"
	echo "   [--fieldmap-type=<type>]  : <type> values"
	echo "                               GE: Siemens Gradient Echo Fieldmaps"
	echo "                               SiemensGradientEcho: Siemens Gradient Echo Fieldmaps (equiv. to GE)"
    echo "                               SE: Spin Echo Fieldmaps"
	echo "                               SpinEcho: Spin Echo Fieldmaps (equiv. to SE)"
	echo "                               NONE: No fieldmaps"
	echo "                               If unspecified, defaults to GE"
	echo "   [--phase-encoding-dir=<dir-indication>]"
	echo "                             : <dir-indication> values"
	echo "                               RL: Phase Encoding directions used are RL (positive) and LR (negative)"
	echo "                               LR: same as RL"
	echo "                               PA: Phase Encoding directions used are PA (positive) and AP (negative)" 
	echo "                               AP: same as PA"
	echo "                               If unspecified, defaults to RL"
	echo "   [--seed=<rng-seed>]       : Random number generator seed for recon-all, passed to FreeSurferPipeline.sh script"
	echo "                               If unspecified, no seed value is passed to the FreeSurferPipeline.sh script."
	echo "                               In that case, no seed value is passsed to random number generator seed using"
	echo "                               tools."
	echo "   [--brainsize=<brainsize>] : brainsize value passed to the PreFreeSurferPipeline.sh script"
	echo "                               If unspecified, the default value of 150 is used."
	echo "    --xnat-session-id=$<xnat-session-id> "
	echo "                             : e.g. ConnectomeDB_E17905 "
	echo "   [--setup-script=<script>] : Full path to script to source to set up environment before running "
	echo "                               HCP Pipeline Scripts. If unspecified the default value of:"
	echo "                               ${DEFAULT_SETUP_SCRIPT} is used."
	echo ""
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
	unset g_fieldmap_type
	unset g_phase_encoding_dir
	unset g_seed
	unset g_brainsize
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
			--working-dir=*)
				g_working_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--workflow-id=*)
				g_workflow_id=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--fieldmap-type=*)
				g_fieldmap_type=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--phase-encoding-dir=*)
				g_phase_encoding_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--seed=*)
				g_seed=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--brainsize=*)
				g_brainsize=${argument/*=/""}
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

	# check parameters
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

	if [ -z "${g_fieldmap_type}" ]; then
		g_fieldmap_type="GE"
	fi
	echo "g_fieldmap_type: ${g_fieldmap_type}"

	if [[ ("${g_fieldmap_type}" != "GE") && ("${g_fieldmap_type}" != "SiemensGradientEcho") && ("${g_fieldmap_type}" != "SE") && ("${g_fieldmap_type}" != "SpinEcho") && ("${g_fieldmap_type}" != "NONE") ]] ; then
		echo "ERROR: unrecognized g_fieldmap_type: ${g_fieldmap_type}"
		error_count=$(( error_count + 1 ))
	fi

	if [ -z "${g_phase_encoding_dir}" ]; then
		g_phase_encoding_dir="RL"
	fi

	if [[ ("${g_phase_encoding_dir}" == "LR") || ("${g_phase_encoding_dir}" == "RL") ]] ; then
		g_phase_encoding_dir="RL"
		echo "g_phase_encoding_dir: ${g_phase_encoding_dir}"
	elif [[ ("${g_phase_encoding_dir}" == "AP") || ("${g_phase_encoding_dir}" == "PA") ]] ; then
		g_phase_encoding_dir="PA"
		echo "g_phase_encoding_dir: ${g_phase_encoding_dir}"
	else
		echo "ERROR: unrecognized g_phase_encoding_dir: ${g_phase_encoding_dir}"
		error_count=$(( error_count + 1 ))		
	fi

	if [ ! -z "${g_seed}" ]; then
		echo "g_seed: ${g_seed}"
	fi

	if [ -z "${g_brainsize}" ]; then
		g_brainsize="150"
	fi
	echo "g_brainsize: ${g_brainsize}"

	if [ -z "${g_xnat_session_id}" ] ; then
		echo "ERROR: --xnat-session-id= required"
		error_count=$(( error_count + 1 ))
	fi
	echo "g_xnat_session_id: ${g_xnat_session_id}"

	if [ -z "${g_setup_script}" ] ; then
		g_setup_script=${DEFAULT_SETUP_SCRIPT}
	fi
	echo "g_setup_script: ${g_setup_script}"

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

set_spin_echo_positive_and_negative_fieldmaps()
{
	if [[ "${g_phase_encoding_dir}" == "PA" ]]; then
		g_positive_spin_echo_fieldmap_name="${SPIN_ECHO_FIELDMAP_NAME}_${PAAP_POSITIVE_DIR}"
		g_negative_spin_echo_fieldmap_name="${SPIN_ECHO_FIELDMAP_NAME}_${PAAP_NEGATIVE_DIR}"
	elif [[ "${g_phase_encoding_dir}" == "RL" ]]; then
		g_positive_spin_echo_fieldmap_name="${SPIN_ECHO_FIELDMAP_NAME}_${RLLR_POSITIVE_DIR}"
		g_negative_spin_echo_fieldmap_name="${SPIN_ECHO_FIELDMAP_NAME}_${RLLR_NEGATIVE_DIR}"
	else
		echo "ERROR: unrecoginzied g_phase_encoding_dir: ${g_phase_encoding_dir}"
		exit 1
	fi
}

does_resource_exist()
{
	local resource_name="${1}"
	local does_it_exist=`${XNAT_UTILS_HOME}/xnat_scan_info -s "${XNAT_PBS_JOBS_XNAT_SERVER}" -u ${g_user} -p ${g_password} -pr ${g_project} -su ${g_subject} -se ${g_session} -r "${resource_name}" check_resource_exists`
	echo ${does_it_exist}
}

does_first_t1w_scan_exist()
{
	local does_it_exist=`does_resource_exist "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" check_resource_exists`
	echo ${does_it_exist}
}

does_second_t1w_scan_exist()
{
	local does_it_exist=`does_resource_exist "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" check_resource_exists`
	echo ${does_it_exist}
}

does_first_t2w_scan_exist()
{
	local does_it_exist=`does_resource_exist "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" check_resource_exists`
	echo ${does_it_exist}
}

does_second_t2w_scan_exist()
{
	local does_it_exist=`does_resource_exist "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" check_resource_exists`
	echo ${does_it_exist}
}

do_gradient_echo_field_maps_exist()
{
	magnitude_fieldmaps=`find ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/T[1-2]w*_unproc -maxdepth 1 -name "*${MAG_FIELDMAP_NAME}*"`
	phase_fieldmaps=`find ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/T[1-2]w*_unproc -maxdepth 1 -name "*${PHASE_FIELDMAP_NAME}*"`

	if [ -z "${magnitude_fieldmaps}" ] ; then
		echo "FALSE"
	elif [ -z "${phase_fieldmaps}" ] ; then
		echo "FALSE"
	else
		echo "TRUE"
	fi
}

get_scan_data() 
{
	local resource_name="${1}"
	local file_name="${2}"
	local item_name="${3}"

	local result=`${XNAT_UTILS_HOME}/xnat_scan_info -s "${XNAT_PBS_JOBS_XNAT_SERVER}" -u ${g_user} -p ${g_password} -pr ${g_project} -su ${g_subject} -se ${g_session} -r "${resource_name}" get_data -f "${file_name}" -i "${item_name}"`
	echo ${result}
}

get_parameters_for_first_t1w_scan() 
{
	g_first_t1w_series_description=""
	g_first_t1w_sample_spacing=""
	g_first_t1w_deltaTE=""
	g_first_t1w_positive_dwell_time=""
	g_first_t1w_negative_dwell_time=""

	g_first_t1w_series_description=`get_scan_data "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${FIRST_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "series_description"`
	echo "g_first_t1w_series_description: ${g_first_t1w_series_description}"

	# sample_spacing value in XNAT DB is in nanoseconds, but needs to be specified in seconds
	g_first_t1w_sample_spacing=`get_scan_data "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${FIRST_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "parameters/readoutSampleSpacing"`
	sample_spacing_in_secs=`echo "${g_first_t1w_sample_spacing} 1000000000.0" | awk '{printf "%.9f", $1/$2}'`
	g_first_t1w_sample_spacing=${sample_spacing_in_secs}
	echo "g_first_t1w_sample_spacing: ${g_first_t1w_sample_spacing}"

	if [[ ("${g_fieldmap_type}" = "GE") || ("${g_fieldmap_type}" = "SiemensGradientEcho") ]] ; then
		g_first_t1w_deltaTE=`get_scan_data "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}" "parameters/deltaTE"`
		echo "g_first_t1w_deltaTE: ${g_first_t1w_deltaTE}"

	elif [[ ("${g_fieldmap_type}" = "SE") || ("${g_fieldmap_type}" = "SpinEcho") ]] ; then
		g_first_t1w_positive_dwell_time=`get_scan_data "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_positive_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_first_t1w_positive_dwell_time: ${g_first_t1w_positive_dwell_time}"

		g_first_t1w_negative_dwell_time=`get_scan_data "${FIRST_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_negative_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_first_t1w_negative_dwell_time: ${g_first_t1w_negative_dwell_time}"
	fi
}

get_parameters_for_second_t1w_scan() 
{
	g_second_t1w_series_description=""
	g_second_t1w_sample_spacing=""
	g_second_t1w_deltaTE=""
	g_second_t1w_positive_dwell_time=""
	g_second_t1w_negative_dwell_time=""

	g_second_t1w_series_description=`get_scan_data "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${SECOND_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "series_description"`
	echo "g_second_t1w_series_description: ${g_second_t1w_series_description}"

	# sample_spacing value in XNAT DB is in nanoseconds, but needs to be specified in seconds	
	g_second_t1w_sample_spacing=`get_scan_data "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${SECOND_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "parameters/readoutSampleSpacing"`
	sample_spacing_in_secs=`echo "${g_second_t1w_sample_spacing} 1000000000.0" | awk '{printf "%.9f", $1/$2}'`
	g_second_t1w_sample_spacing=${sample_spacing_in_secs}
	echo "g_second_t1w_sample_spacing: ${g_second_t1w_sample_spacing}"

	if [[ ("${g_fieldmap_type}" = "GE") || ("${g_fieldmap_type}" = "SiemensGradientEcho") ]] ; then
		g_second_t1w_deltaTE=`get_scan_data "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}" "parameters/deltaTE"`
		echo "g_second_t1w_deltaTE: ${g_second_t1w_deltaTE}"

	elif [[ ("${g_fieldmap_type}" = "SE") || ("${g_fieldmap_type}" = "SpinEcho") ]] ; then
		g_second_t1w_positive_dwell_time=`get_scan_data "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_positive_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_second_t1w_positive_dwell_time: ${g_second_t1w_positive_dwell_time}"

		g_second_t1w_negative_dwell_time=`get_scan_data "${SECOND_T1W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_negative_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_second_t1w_negative_dwell_time: ${g_second_t1w_negative_dwell_time}"
	fi
}

get_parameters_for_first_t2w_scan()
{
	g_first_t2w_series_description=""
	g_first_t2w_sample_spacing=""
	g_first_t2w_deltaTE=""
	g_first_t2w_positive_dwell_time=""
	g_first_t2w_negative_dwell_time=""

	g_first_t2w_series_description=`get_scan_data "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${FIRST_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "series_description"`
	echo "g_first_t2w_series_description: ${g_first_t2w_series_description}"

	# sample_spacing value in XNAT DB is in nanoseconds, but needs to be specified in seconds
	g_first_t2w_sample_spacing=`get_scan_data "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${FIRST_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "parameters/readoutSampleSpacing"`
	sample_spacing_in_secs=`echo "${g_first_t2w_sample_spacing} 1000000000.0" | awk '{printf "%.9f", $1/$2}'`
	g_first_t2w_sample_spacing=${sample_spacing_in_secs}
	echo "g_first_t2w_sample_spacing: ${g_first_t2w_sample_spacing}"

	if [[ ("${g_fieldmap_type}" = "GE") || ("${g_fieldmap_type}" = "SiemensGradientEcho") ]] ; then
		g_first_t2w_deltaTE=`get_scan_data "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}" "parameters/deltaTE"`
		echo "g_first_t2w_deltaTE: ${g_first_t2w_deltaTE}"

	elif [[ ("${g_fieldmap_type}" = "SE") || ("${g_fieldmap_type}" = "SpinEcho") ]] ; then
		g_first_t2w_positive_dwell_time=`get_scan_data "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_positive_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_first_t2w_positive_dwell_time: ${g_first_t2w_positive_dwell_time}"

		g_first_t2w_negative_dwell_time=`get_scan_data "${FIRST_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_negative_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_first_t2w_negative_dwell_time: ${g_first_t2w_negative_dwell_time}"
	fi
}

get_parameters_for_second_t2w_scan()
{
	g_second_t2w_series_description=""
	g_second_t2w_sample_spacing=""
	g_second_t2w_deltaTE=""
	g_second_t2w_positive_dwell_time=""
	g_second__t2w_negative_dwell_time=""

	g_second_t2w_series_description=`get_scan_data "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${SECOND_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "series_description"`
	echo "g_second_t2w_series_description: ${g_second_t2w_series_description}"

	# sample_spacing value in XNAT DB is in nanoseconds, but needs to be specified in seconds
	g_second_t2w_sample_spacing=`get_scan_data "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${SECOND_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}" "parameters/readoutSampleSpacing"`
	sample_spacing_in_secs=`echo "${g_second_t2w_sample_spacing} 1000000000.0" | awk '{printf "%.9f", $1/$2}'`
	g_second_t2w_sample_spacing=${sample_spacing_in_secs}
	echo "g_second_t2w_sample_spacing: ${g_second_t2w_sample_spacing}"

	if [[ ("${g_fieldmap_type}" = "GE") || ("${g_fieldmap_type}" = "SiemensGradientEcho") ]] ; then
		g_second_t2w_deltaTE=`get_scan_data "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}" "parameters/deltaTE"`
		echo "g_second_t2w_deltaTE: ${g_second_t2w_deltaTE}"

	elif [[ ("${g_fieldmap_type}" = "SE") || ("${g_fieldmap_type}" = "SpinEcho") ]] ; then
		g_second_t2w_positive_dwell_time=`get_scan_data "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_positive_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_second_t2w_positive_dwell_time: ${g_second_t2w_positive_dwell_time}"

		g_second_t2w_negative_dwell_time=`get_scan_data "${SECOND_T2W_FILE_NAME_BASE}${UNPROC_SUFFIX}" "${g_session}_${g_negative_spin_echo_fieldmap_name}${COMPRESSED_NIFTI_EXTENSION}" "parameters/echoSpacing"`
		echo "g_second_t2w_negative_dwell_time: ${g_second_t2w_negative_dwell_time}"
	fi
}

log_exec_info()
{
	local pbs_exec_info_file_name=${g_working_dir}/StructuralPreprocessingHCP.XNAT.execinfo
	echo "PBS_JOBID: ${PBS_JOBID}" > ${pbs_exec_info_file_name}
	echo "PBS execution node: $(hostname)" >> ${pbs_exec_info_file_name}
}

# Main processing
#   Carry out the necessary steps to:
#   - get prerequisite data for the Strucutral Preprocessing pipeline 
#   - run the scripts
main()
{
	get_options $@

	log_exec_info

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"

	set_spin_echo_positive_and_negative_fieldmaps

	source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
	source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

	# Set up step counters
	total_steps=12
	current_step=0

	# Set up to run Python
	echo "Setting up to run Python"
	source ${SETUP_SCRIPTS_HOME}/epd-python_setup.sh

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# ----------------------------------------------------------------------------------------------
 	# Step - Link unprocessed data from DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link unprocessed data from DB" ${step_percent}

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
	# Step - Create a start_time file
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Create a start_time file" ${step_percent}

	start_time_file="${g_working_dir}/StructuralPreprocessingHCP.starttime"
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
	# Step - Set up to run PreFreeSurferPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up to run PreFreeSurferPipeline.sh script" ${step_percent}

	# Source setup script to setup environment for running the script
	echo "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}

	first_T1w_resource_exists=`does_first_t1w_scan_exist`
	echo "first_T1w_resource_exists: ${first_T1w_resource_exists}"

	if [ "${first_T1w_resource_exists}" = "TRUE" ] ; then
		get_parameters_for_first_t1w_scan
	fi

	second_T1w_resource_exists=`does_second_t1w_scan_exist`
	echo "second_T1w_resource_exists: ${second_T1w_resource_exists}"

	if [ "${second_T1w_resource_exists}" = "TRUE" ] ; then
		get_parameters_for_second_t1w_scan
	fi

	first_T2w_resource_exists=`does_first_t2w_scan_exist`
	echo "first_T2w_resource_exists: ${first_T2w_resource_exists}"

	if [ "${first_T2w_resource_exists}" = "TRUE" ] ; then
		get_parameters_for_first_t2w_scan
	fi

	second_T2w_resource_exists=`does_second_t2w_scan_exist`
	echo "second_T2w_resource_exists: ${second_T2w_resource_exists}"

	if [ "${second_T2w_resource_exists}" = "TRUE" ] ; then
		get_parameters_for_second_t2w_scan
	fi

	gradient_echo_field_maps_exist=`do_gradient_echo_field_maps_exist`
	echo "gradient_echo_field_maps_exist: ${gradient_echo_field_maps_exist}"

	# build specification of T1w scans

	t1_spec=""
	
	if [ "${first_T1w_resource_exists}" = "TRUE" ]; then
		first_T1w_file="${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${FIRST_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}"
		
		if [ -e "${first_T1w_file}" ] ; then
			t1_spec+=${first_T1w_file}
		else
			echo "The first T1w file: \'${first_T1w_file}\' does not exist"
			exit 1
		fi
	else
		echo "ERROR: NO FIRST T1W RESOURCE"
		exit 1
	fi

 	if [ "${second_T1w_resource_exists}" = "TRUE" ]; then
 		second_T1w_file="${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${SECOND_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${SECOND_T1W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}"

 		if [ -e "${second_T1w_file}" ] ; then
			t1_spec+=@
 			t1_spec+=${second_T1w_file}
 		else
 			echo "The second T1w file: \'${second_T1w_file}\' does not exist"
 			exit 1
 		fi
 	else
		t1_spec+=@
		t1_spec+=${first_T1w_file}
 	fi

 	echo "t1_spec: ${t1_spec}"

 	t2_spec=""

 	if [ "${first_T2w_resource_exists}" = "TRUE" ]; then
 		first_T2w_file="${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T2W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${FIRST_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}"

 		if [ -e "${first_T2w_file}" ] ; then
 			t2_spec+=${first_T2w_file}
 		else
 			echo "The first T2w file: \'${first_T2w_file}\' does not exist"
 			exit 1
 		fi
 	else
 		echo "ERROR: NO FIRST T2W RESOURCE"
 		exit 1
 	fi

 	if [ "${second_T2w_resource_exists}" = "TRUE" ]; then
 		second_T2w_file="${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${SECOND_T2W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${SECOND_T2W_FILE_NAME_BASE}${COMPRESSED_NIFTI_EXTENSION}"

 		if [ -e "${second_T2w_file}" ] ; then
 			t2_spec+=@
			t2_spec+=${second_T2w_file}
		else
			echo "The second T2w file: \'${second_T2w_file}\' does not exist"
			exit 1
		fi
 	else
		t2_spec+=@
		t2_spec+=${first_T2w_file}
	fi

 	echo "t2_spec: ${t2_spec}"

	# ----------------------------------------------------------------------------------------------
	# Step - Run the PreFreeSurferPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the PreFreeSurferPipeline.sh script" ${step_percent}

 	# Run PreFreeSurferPipeline.sh script
 	PreFreeSurfer_cmd=""
 	PreFreeSurfer_cmd+="${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh"
 	PreFreeSurfer_cmd+=" --path=${g_working_dir}"
 	PreFreeSurfer_cmd+=" --subject=${g_subject}"
 	PreFreeSurfer_cmd+=" --t1=${t1_spec}"
 	PreFreeSurfer_cmd+=" --t2=${t2_spec}"
 	PreFreeSurfer_cmd+=" --t1template=${HCPPIPEDIR}/global/templates/MNI152_T1_0.7mm.nii.gz"
 	PreFreeSurfer_cmd+=" --t1templatebrain=${HCPPIPEDIR}/global/templates/MNI152_T1_0.7mm_brain.nii.gz"
 	PreFreeSurfer_cmd+=" --t1template2mm=${HCPPIPEDIR}/global/templates/MNI152_T1_2mm.nii.gz"
 	PreFreeSurfer_cmd+=" --t2template=${HCPPIPEDIR}/global/templates/MNI152_T2_0.7mm.nii.gz"
 	PreFreeSurfer_cmd+=" --t2templatebrain=${HCPPIPEDIR}/global/templates/MNI152_T2_0.7mm_brain.nii.gz"
 	PreFreeSurfer_cmd+=" --t2template2mm=${HCPPIPEDIR}/global/templates/MNI152_T2_2mm.nii.gz"
	PreFreeSurfer_cmd+=" --templatemask=${HCPPIPEDIR}/global/templates/MNI152_T1_0.7mm_brain_mask.nii.gz"
	PreFreeSurfer_cmd+=" --template2mmmask=${HCPPIPEDIR}/global/templates/MNI152_T1_2mm_brain_mask_dil.nii.gz"
	PreFreeSurfer_cmd+=" --fnirtconfig=${HCPPIPEDIR}/global/config/T1_2_MNI152_2mm.cnf"
	PreFreeSurfer_cmd+=" --gdcoeffs=${HCPPIPEDIR}/global/config/coeff_SC72C_Skyra.grad"
	PreFreeSurfer_cmd+=" --brainsize=${g_brainsize}"

	if [[ ("${g_fieldmap_type}" == "GE") || ("${g_fieldmap_type}" == "SiemensGradientEcho") ]] ; then
		# add parameters for Siemens Gradient Echo fieldmap usage
		echo "add parameters for Siemens Gradient Echo fieldmap usage"

		echo "gradient_echo_field_maps_exist: ${gradient_echo_field_maps_exist}"
		if [[ "${gradient_echo_field_maps_exist}" == "TRUE" ]] ; then
			echo "adding parameters for when Siemens gradient echo fieldmaps should be used and do exist"
			PreFreeSurfer_cmd+=" --echodiff=${g_first_t1w_deltaTE}"
			PreFreeSurfer_cmd+=" --t1samplespacing=${g_first_t1w_sample_spacing}"
			PreFreeSurfer_cmd+=" --t2samplespacing=${g_first_t2w_sample_spacing}"
			PreFreeSurfer_cmd+=" --avgrdcmethod=FIELDMAP"
			PreFreeSurfer_cmd+=" --topupconfig=NONE"
			PreFreeSurfer_cmd+=" --fmapmag=${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}"
			PreFreeSurfer_cmd+=" --fmapphase=${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${PHASE_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}"
			PreFreeSurfer_cmd+=" --unwarpdir=z"
		else
			echo "adding parameters for when Siemens gradient echo fieldmaps should be used but do NOT exist"
			PreFreeSurfer_cmd+=" --echodiff=NONE"
			PreFreeSurfer_cmd+=" --t1samplespacing=NONE"
			PreFreeSurfer_cmd+=" --t2samplespacing=NONE"
			PreFreeSurfer_cmd+=" --avgrdcmethod=NONE"
			PreFreeSurfer_cmd+=" --topupconfig=NONE"
			PreFreeSurfer_cmd+=" --fmapmag=${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${MAG_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}"
			PreFreeSurfer_cmd+=" --fmapphase=${g_working_dir}/${g_subject}/unprocessed/${TESLA_SPEC}/${FIRST_T1W_FILE_NAME_BASE}/${g_subject}_${TESLA_SPEC}_${PHASE_FIELDMAP_NAME}${COMPRESSED_NIFTI_EXTENSION}"
			PreFreeSurfer_cmd+=" --unwarpdir=z"
		fi
	elif [[ ("${g_fieldmap_type}" == "SE") || ("${g_fieldmap_type}" == "SpinEcho") ]] ; then
		# add parameters for SpinEcho fieldmap usage
		echo "SpinEcho fieldmaps UNHANDLED YET"
		exit 1 
	else
		echo "ERROR: Unrecognized g_fieldmap_type: ${g_fieldmap_type}"
		exit 1
	fi

	echo ""
	echo "PreFreeSurfer_cmd: ${PreFreeSurfer_cmd}"
	echo ""

	pushd ${g_working_dir}
	${PreFreeSurfer_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Run FreeSurferPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	    ${current_step} "Run the FreeSurferPipeline.sh script" ${step_percent}

 	# Run FreeSurferPipeline.sh script
 	FreeSurfer_cmd=""
	FreeSurfer_cmd+="${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh"
	FreeSurfer_cmd+=" --subject=${g_subject}"
	FreeSurfer_cmd+=" --subjectDIR=${g_working_dir}/${g_subject}/T1w"
	FreeSurfer_cmd+=" --t1=${g_working_dir}/${g_subject}/T1w/T1w_acpc_dc_restore.nii.gz"
	FreeSurfer_cmd+=" --t1brain=${g_working_dir}/${g_subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz"
	FreeSurfer_cmd+=" --t2=${g_working_dir}/${g_subject}/T1w/T2w_acpc_dc_restore.nii.gz"

	if [ ! -z "${g_seed}" ]; then
		FreeSurfer_cmd+=" --seed=${g_seed}"
	fi

	echo ""
	echo "FreeSurfer_cmd: ${FreeSurfer_cmd}"
	echo ""
	
	pushd ${g_working_dir}
	${FreeSurfer_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Run PostFreeSurferPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the PostFreeSurferPipeline.sh script" ${step_percent}

 	# Run PostFreeSurferPipeline.sh script
 	PostFreeSurfer_cmd=""
	PostFreeSurfer_cmd+="${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh"
	PostFreeSurfer_cmd+=" --path=${g_working_dir}"
	PostFreeSurfer_cmd+=" --subject=${g_subject}"
	PostFreeSurfer_cmd+=" --surfatlasdir=${HCPPIPEDIR}/global/templates/standard_mesh_atlases/"
	PostFreeSurfer_cmd+=" --grayordinatesdir=${HCPPIPEDIR}/global/templates/91282_Greyordinates"
	PostFreeSurfer_cmd+=" --grayordinatesres=2"
	PostFreeSurfer_cmd+=" --hiresmesh=164"
	PostFreeSurfer_cmd+=" --lowresmesh=32"
	PostFreeSurfer_cmd+=" --subcortgraylabels=${HCPPIPEDIR}/global/config/FreeSurferSubcorticalLabelTableLut.txt"
	PostFreeSurfer_cmd+=" --freesurferlabels=${HCPPIPEDIR}/global/config/FreeSurferAllLut.txt"
	PostFreeSurfer_cmd+=" --refmyelinmaps=${HCPPIPEDIR}/global/templates/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
	PostFreeSurfer_cmd+=" --regname=MSMSulc"

	echo ""
	echo "PostFreeSurfer_cmd: ${PostFreeSurfer_cmd}"
	echo ""
	
	pushd ${g_working_dir}
	${PostFreeSurfer_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - GENERATE_SNAPSHOT
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "GENERATE_SNAPSHOT" ${step_percent}

	# use a sub-shell so that freesurfer53_setup.sh only affects the snap_montage_cmd 
	(
		snap_montage_cmd=""
		snap_montage_cmd+="xvfb_wrapper.sh ${NRG_PACKAGES}/tools/HCP/Freesurfer/freesurfer_includes/snap_montage_fs5.csh"
		snap_montage_cmd+=" ${g_subject}"
		snap_montage_cmd+=" ${g_working_dir}/${g_subject}/T1w"
		
		echo ""
		echo "snap_montage_cmd: ${snap_montage_cmd}"
		echo ""
		
		pushd ${g_working_dir}/${g_subject}
		source ${SETUP_SCRIPTS_HOME}/freesurfer53_setup.sh
		${snap_montage_cmd}
		if [ $? -ne 0 ]; then
			die 
		fi
		popd
	)

	if [ $? -ne 0 ]; then
		die
	fi

	# ----------------------------------------------------------------------------------------------
	# Step - CREATE_ASSESSOR
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "CREATE_ASSESSOR" ${step_percent}

 	# Generate XNAT XML from FreeSurfer stats files

	stats2xml_cmd=""
	stats2xml_cmd+="${NRG_PACKAGES}/tools/HCP/Freesurfer/freesurfer_includes/stats2xml_mrh.pl"
	stats2xml_cmd+=" -p ${g_project}"
	stats2xml_cmd+=" -x ${g_xnat_session_id}"
	stats2xml_cmd+=" -t Freesurfer"
	stats2xml_cmd+=" -d ${TESLA_SPEC}"
	stats2xml_cmd+=" -o ${g_working_dir}/${g_subject}/"
	stats2xml_cmd+=" ${g_working_dir}/${g_subject}/T1w/${g_subject}/stats"

	echo ""
	echo "stats2xml_cmd: ${stats2xml_cmd}"
	echo ""

	pushd ${g_working_dir}/${g_subject}
	${stats2xml_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Put generated FreeSurfer stats file in DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	    ${current_step} "Put generated FreeSurfer stats file in DB" ${step_percent}

	resource_uri="http://${g_server}/data/archive/projects/${g_project}/subjects/${g_subject}/experiments/${g_xnat_session_id}/assessors/${g_xnat_session_id}_freesurfer_${TESLA_SPEC}?allowDataDeletion=true&inbody=true"

	java_cmd="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
	java_cmd+=" -u ${g_user}"
	java_cmd+=" -p ${g_password}"
	java_cmd+=" -r ${resource_uri}"	
	java_cmd+=" -l ${g_working_dir}/${g_subject}/${g_xnat_session_id}_freesurfer5.xml"
	java_cmd+=" -m PUT"

	echo ""
	echo "java_cmd: ${java_cmd}"
	echo ""

	pushd ${g_working_dir}/${g_subject}
	${java_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Put snapshots in DB and remove local copies
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Put snapshots in DB and remove local copies" ${step_percent}

	db_resource="http://${g_server}/data/archive/projects/${g_project}/subjects/${g_subject}/experiments/${g_xnat_session_id}/assessors/${g_xnat_session_id}_freesurfer_${TESLA_SPEC}/resources/SNAPSHOTS"
	echo "db_resource: ${db_resource}"
	
	# Replace very first instance of HCP in working directory name with data.
	# So, for example, "/HCP/hcpdb/build_ssd/chpc/BUILD/HCP_Staging/..." becomes "/data/hcpdb/build_ssd/chpc/BUILD/HCP_Staging/..."
	# The reference= part of the PUT operation expects a reference to something that is local to the machine
	# running XNAT.
	local_resource="${g_working_dir}/${g_subject}/T1w/${g_subject}/snapshots"
	echo "local_resource: ${local_resource}"

	xnat_local_resource=${local_resource/HCP/data}
	echo "xnat_local_resource: ${xnat_local_resource}"

	resource_uri="${db_resource}/files?overwrite=true&replace=true&reference=${xnat_local_resource}"

	java_cmd="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
	java_cmd+=" -u ${g_user}"
	java_cmd+=" -p ${g_password}"
	java_cmd+=" -r ${resource_uri}"	
	java_cmd+=" -m PUT"

	echo ""
	echo "java_cmd: ${java_cmd}"
	echo ""
	
	pushd ${g_working_dir}/${g_subject}
	${java_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	rm_cmd="rm -r ${local_resource}"
	echo ""
	echo "rm_cmd: ${rm_cmd}"
	echo ""
	${rm_cmd}

	# ----------------------------------------------------------------------------------------------
	# Step - Show any newly created or modified files
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Show newly created or modified files" ${step_percent}
	
	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# ----------------------------------------------------------------------------------------------
	# Step - Remove any files that are not newly created or modified
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Remove files not newly created or modified" ${step_percent}
	
	echo "The following files are being removed"
	find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete 
	
	# ----------------------------------------------------------------------------------------------
	# Step - Complete Workflow
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
}

# Invoke the main function to get things started
main $@
