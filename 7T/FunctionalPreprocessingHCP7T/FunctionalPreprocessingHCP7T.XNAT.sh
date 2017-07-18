#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # FunctionalPreprocessingHCP7T.XNAT.sh
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
# TBW
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

PIPELINE_NAME="FunctionalPreprocessingHCP7T"
SCRIPT_NAME="FunctionalPreprocessingHCP7T.XNAT.sh"

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

POSITIVE_PHASE_ENCODING_DIRECTION="PA"
NEGATIVE_PHASE_ENCODING_DIRECTION="AP"

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
		inform "ERROR: workflow ID (--workflow-id=) required"
		error_count=$(( error_count + 1 ))
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
#   - get prerequisite data
#   - run the scripts
main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
	source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

	# Set up step counters
	total_steps=12
	current_step=0

	# Set up to run Python
	inform "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	xnat_workflow_show ${g_server} ${g_user} ${g_password} ${g_workflow_id}

	# ----------------------------------------------------------------------------------------------
	# Step - Link Supplemental Structurally preprocessed data from DB 
	#      - the higher resolution greyordinates space
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Supplemental Structurally preprocessed data from DB" ${step_percent}

	link_hcp_supplemental_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
	# Step - Link Structurally preprocessed data from DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link Structurally preprocessed data from DB" ${step_percent}

	link_hcp_struct_preproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
 	# Step - Link unprocessed data from DB
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Link unprocessed data from DB" ${step_percent}

	link_hcp_struct_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_structural_reference_project}" "${g_subject}" "${g_structural_reference_session}" "${g_working_dir}"
	link_hcp_7T_resting_state_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_7T_diffusion_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"
	link_hcp_7T_task_unproc_data "${DATABASE_ARCHIVE_ROOT}" "${g_project}" "${g_subject}" "${g_session}" "${g_working_dir}"

	# ----------------------------------------------------------------------------------------------
	# Step - Create a start_time file
	# ----------------------------------------------------------------------------------------------
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

	# ----------------------------------------------------------------------------------------------
	# Step - Set up environment to run scripts
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up environment to run scripts" ${step_percent}

	# Source setup script to setup environment for running the script
	#source ${SCRIPTS_HOME}/SetUpHCPPipeline_7T_FunctionalPreprocessing.sh
	inform "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}

	# get the echo spacing value
	inform "Get echo spacing"
	local resource=${g_scan}_unproc
	local file=${g_session}_${g_scan}.nii.gz
	local item="parameters/echoSpacing"
	get_echo_spacing_cmd="get_scan_data ${resource} ${file} ${item}"
	echo_spacing=`${get_echo_spacing_cmd}`

	inform "echo_spacing: ${echo_spacing}"

	# determine fMRI name
	inform "Determine fMRI name"
	phase_encoding_dir="${g_scan##*_}"
	inform "phase_encoding_dir: ${phase_encoding_dir}"

	base_fmriname="${g_scan%_*}"
	inform "base_fmriname: ${base_fmriname}"

	fmriname="${base_fmriname}_7T_${phase_encoding_dir}"
	inform "fmriname: ${fmriname}"

	# ----------------------------------------------------------------------------------------------
	# Step - Run the GenericfMRIVolumeProcessingPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the GenericfMRIVolumeProcessingPipeline.sh script" ${step_percent}

	unwarp_dir_spec=""
	if [ "${phase_encoding_dir}" = "${NEGATIVE_PHASE_ENCODING_DIRECTION}" ] ; then
		# AP
		unwarp_dir_spec="-y"
	elif [ "${phase_encoding_dir}" = "${POSITIVE_PHASE_ENCODING_DIRECTION}" ] ; then
		# PA
		unwarp_dir_spec="y"
	else
		inform "Unrecognized phase_encoding_dir: ${phase_encoding_dir}"
		inform "Aborting"
		exit 1
	fi
	
 	volume_cmd=""
 	volume_cmd+="${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh"
 	volume_cmd+=" --path=${g_working_dir}"
 	volume_cmd+=" --subject=${g_subject}"
 	volume_cmd+=" --fmriname=${fmriname}"
	volume_cmd+=" --fmritcs=${g_working_dir}/${g_subject}/unprocessed/7T/${g_scan}/${g_subject}_7T_${g_scan}.nii.gz"
	volume_cmd+=" --fmriscout=${g_working_dir}/${g_subject}/unprocessed/7T/${g_scan}/${g_subject}_7T_${g_scan}_SBRef.nii.gz"
	volume_cmd+=" --SEPhaseNeg=${g_working_dir}/${g_subject}/unprocessed/7T/${g_scan}/${g_subject}_7T_SpinEchoFieldMap_${NEGATIVE_PHASE_ENCODING_DIRECTION}.nii.gz"
	volume_cmd+=" --SEPhasePos=${g_working_dir}/${g_subject}/unprocessed/7T/${g_scan}/${g_subject}_7T_SpinEchoFieldMap_${POSITIVE_PHASE_ENCODING_DIRECTION}.nii.gz"
	volume_cmd+=" --echospacing=${echo_spacing}"
	volume_cmd+=" --echodiff=NONE"
	volume_cmd+=" --unwarpdir=${unwarp_dir_spec}"
	volume_cmd+=" --fmrires=1.60"
	volume_cmd+=" --dcmethod=TOPUP"
	volume_cmd+=" --gdcoeffs=${HCPPIPEDIR}/global/config/trunc.CMRR_7TAS_coeff_SC72CD.grad"
	volume_cmd+=" --topupconfig=${HCPPIPEDIR}/global/config/b02b0.cnf"
	volume_cmd+=" --fmapmag=NONE"
	volume_cmd+=" --fmapphase=NONE"
	volume_cmd+=" --fmapgeneralelectric=NONE"
	volume_cmd+=" --dof=12"
	volume_cmd+=" --biascorrection=SEBASED"
	volume_cmd+=" --usejacobian=TRUE"

	inform ""
	inform "volume_cmd: ${volume_cmd}"
	inform ""

	pushd ${g_working_dir}
	${volume_cmd}
	if [ $? -ne 0 ]; then
		die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Run the GenericfMRISurfaceProcessingPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the GenericfMRISurfaceProcessingPipeline.sh script" ${step_percent}

 	surface_cmd=""
	surface_cmd+="${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline.sh"
	surface_cmd+=" --path=${g_working_dir}"
	surface_cmd+=" --subject=${g_subject}"
 	surface_cmd+=" --fmriname=${fmriname}"
	surface_cmd+=" --lowresmesh=32"
	surface_cmd+=" --fmrires=1.60"
	surface_cmd+=" --smoothingFWHM=2"
	surface_cmd+=" --grayordinatesres=2"
	surface_cmd+=" --regname=MSMSulc"

	inform ""
	inform "surface_cmd: ${surface_cmd}"
	inform ""
	
	pushd ${g_working_dir}
	${surface_cmd} 
	if [ $? -ne 0 ]; then
	 	die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Run the GenericfMRISurfaceProcessingPipeline_1res.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the GenericfMRISurfaceProcessingPipeline_1res.sh script" ${step_percent}

	LowResMesh="59"
	FinalfMRIResolution="1.60"
	SmoothingFWHM="1.60"
	GrayordinatesResolution="1.60"
	RegName="MSMSulc"

 	surface_cmd2=""
	surface_cmd2+="${HCPPIPEDIR}/fMRISurface/GenericfMRISurfaceProcessingPipeline_1res.sh"
	surface_cmd2+=" --path=${g_working_dir}"
	surface_cmd2+=" --subject=${g_subject}"
 	surface_cmd2+=" --fmriname=${fmriname}"
	surface_cmd2+=" --lowresmesh=${LowResMesh}"
	surface_cmd2+=" --fmrires=${FinalfMRIResolution}"
	surface_cmd2+=" --smoothingFWHM=${SmoothingFWHM}"
	surface_cmd2+=" --grayordinatesres=${GrayordinatesResolution}"
	surface_cmd2+=" --regname=${RegName}"

	inform ""
	inform "surface_cmd2: ${surface_cmd2}"
	inform ""
	
	pushd ${g_working_dir}
	${surface_cmd2} 
	if [ $? -ne 0 ]; then
	 	die 
	fi
	popd

	# ----------------------------------------------------------------------------------------------
	# Step - Get LINKED_DATA if appropriate
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Get LINKED_DATA if appropriate" ${step_percent}

	if [[ ${g_scan} == tfMRI* ]] ; then
		
		from_dir=${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${g_scan}_unproc/LINKED_DATA
		inform "from_dir: ${from_dir}"

		to_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${fmriname}/LINKED_DATA
		inform "to_dir: ${to_dir}"
		
		mkdir -p ${to_dir}
		cp --verbose --recursive ${from_dir}/* ${to_dir}

	fi

	# ----------------------------------------------------------------------------------------------
	# Step - Show any newly created or modified files
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Show newly created or modified files" ${step_percent}
	
	inform "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# ----------------------------------------------------------------------------------------------
	# Step - Remove any files that are not newly created or modified
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))
	
	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Remove files not newly created or modified" ${step_percent}
	
	inform "The following files are being removed"
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
