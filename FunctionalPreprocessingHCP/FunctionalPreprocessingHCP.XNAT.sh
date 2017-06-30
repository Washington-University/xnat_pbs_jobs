#!/bin/bash

#~ND~FORMAT~MARKDOWN~
#~ND~START~
#
# # FunctionalPreprocessingHCP.XNAT.sh
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

# Show script usage information
usage()
{
	echo ""
	echo "TBW"
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
	unset g_scan
	unset g_working_dir
	unset g_workflow_id
	unset g_xnat_session_id
#	unset g_create_fsfs_server

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
			--xnat-session-id=*)
				g_xnat_session_id=${argument/*=/""}
				index=$(( index + 1 ))
				;;
#			--create-fsfs-server=*)
#				g_create_fsfs_server=${argument/*=/""}
#				index=$(( index + 1 ))
#				;;
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

	if [ -z "${g_scan}" ] ; then
		echo "ERROR: --scan= required"
		error_count=$(( error_count + 1 ))
	fi
	
	if [ -z "${g_xnat_session_id}" ] ; then
		echo "ERROR: --xnat-session-id= required"
		error_count=$(( error_count + 1 ))
	fi
	echo "g_xnat_session_id: ${g_xnat_session_id}"

#	if [ -z "${g_create_fsfs_server}" ]; then
#		echo "ERROR: server to use for creating FSFs (--create-fsfs-server=) required (should be a shadow server)"
#		error_count=$(( error_count + 1 ))
#	else
#		echo "g_create_fsfs_server: ${g_create_fsfs_server}"
#	fi

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
#   - get prerequisite data for the Strucutral Preprocessing pipeline 
#   - run the scripts
main()
{
	get_options $@

	echo "----- Platform Information: Begin -----"
	uname -a
	echo "----- Platform Information: End -----"

	source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
	source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

	# Set up step counters
	total_steps=11
	current_step=0

	# Set up to run Python
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

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

	start_time_file="${g_working_dir}/FunctionalPreprocessingHCP.starttime"
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
	# Step - Set up to run GenericfMRIVolumeProcessingPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up to run GenericfMRIVolumeProcessingPipeline.sh script" ${step_percent}

	# Source setup script to setup environment for running the script
	source ${SCRIPTS_HOME}/SetUpHCPPipeline_FunctionalPreprocessingHCP.sh

	# get the echo spacing value
	local resource=${g_scan}_unproc
	local file=${g_session}_${g_scan}.nii.gz
	local item="parameters/echoSpacing"
	get_echo_spacing_cmd="get_scan_data ${resource} ${file} ${item}"
	echo_spacing=`${get_echo_spacing_cmd}`

	echo "echo_spacing: ${echo_spacing}"

	# ----------------------------------------------------------------------------------------------
	# Step - Run the GenericfMRIVolumeProcessingPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the GenericfMRIVolumeProcessingPipeline.sh script" ${step_percent}

 	volume_cmd=""
 	volume_cmd+="${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh"
 	volume_cmd+=" --path=${g_working_dir}"
 	volume_cmd+=" --subject=${g_subject}"
 	volume_cmd+=" --fmriname=${g_scan}"
	volume_cmd+=" --fmritcs=${g_working_dir}/${g_subject}/unprocessed/3T/${g_scan}/${g_subject}_3T_${g_scan}.nii.gz"
	volume_cmd+=" --fmriscout=${g_working_dir}/${g_subject}/unprocessed/3T/${g_scan}/${g_subject}_3T_${g_scan}_SBRef.nii.gz"
	volume_cmd+=" --SEPhaseNeg=${g_working_dir}/${g_subject}/unprocessed/3T/${g_scan}/${g_subject}_3T_SpinEchoFieldMap_LR.nii.gz"
	volume_cmd+=" --SEPhasePos=${g_working_dir}/${g_subject}/unprocessed/3T/${g_scan}/${g_subject}_3T_SpinEchoFieldMap_RL.nii.gz"
	volume_cmd+=" --echospacing=${echo_spacing}"
	volume_cmd+=" --echodiff=NONE"
	volume_cmd+=" --unwarpdir=-x"
	volume_cmd+=" --fmrires=2"
	volume_cmd+=" --dcmethod=TOPUP"
	volume_cmd+=" --gdcoeffs=${HCPPIPEDIR}/global/config/coeff_SC72C_Skyra.grad"
	volume_cmd+=" --topupconfig=${HCPPIPEDIR}/global/config/b02b0.cnf"

	echo ""
	echo "volume_cmd: ${volume_cmd}"
	echo ""

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
 	surface_cmd+=" --fmriname=${g_scan}"
	surface_cmd+=" --lowresmesh=32"
	surface_cmd+=" --fmrires=2"
	surface_cmd+=" --smoothingFWHM=2"
	surface_cmd+=" --grayordinatesres=2"
	surface_cmd+=" --regname=MSMSulc"

	echo ""
	echo "surface_cmd: ${surface_cmd}"
	echo ""
	
	pushd ${g_working_dir}
	${surface_cmd} 
	if [ $? -ne 0 ]; then
	 	die 
	fi
	popd

	# # ----------------------------------------------------------------------------------------------
	# # Step - Create FSFs if appropriate
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "Create FSFs if appropriate" ${step_percent}

	# if [[ ${g_scan} == tfMRI* ]] ; then

	# 	# remove any existing FSF CSV file
	# 	fsf_csv_file=${g_working_dir}/${g_subject}/fsf/csv/${g_subject}_hcpxpackage.csv
	# 	if [ -e "${fsf_csv_file}" ] ; then
	# 		rm ${fsf_csv_file}
	# 	fi

	# 	# remove any existing FSF files
	# 	fsf_files=`ls -1 ${g_working_dir}/${g_subject}/fsf/FSFs/${g_subject}/*.fsf`
	# 	for fsf_file in ${fsf_files} ; do
	# 		rm ${fsf_file}
	# 	done

	# 	host_without_port=${g_create_fsfs_server%:*}

	# 	scan_without_dir=${g_scan%_LR}
	# 	scan_without_dir=${scan_without_dir%_RL}

	# 	export PATH="${HOME}/bin:${PATH}" # make sure ${HOME}/bin/dos2unix and ${HOME}/bin/unix2dos can be found
	# 	echo "PATH: ${PATH}"
	
	# 	local create_fsfs_cmd=""
	# 	create_fsfs_cmd+="${NRG_PACKAGES}/tools/HCP/FSF/callCreateFSFs.sh"
	# 	create_fsfs_cmd+=" --host ${host_without_port}"
	# 	create_fsfs_cmd+=" --user ${g_user}"
	# 	create_fsfs_cmd+=" --pw ${g_password}"
	# 	create_fsfs_cmd+=" --buildDir ${g_working_dir}/${g_subject}/"
	# 	create_fsfs_cmd+=" --project ${g_project}"
	# 	create_fsfs_cmd+=" --subject ${g_subject}"
	# 	create_fsfs_cmd+=" --series ${scan_without_dir}"

	# 	echo "create_fsfs_cmd: ${create_fsfs_cmd}"
	# 	${create_fsfs_cmd}
 	# 	if [ $? -ne 0 ]; then
 	# 		die 
 	# 	fi

	# 	# Copy created FSFs
	# 	echo "Copying created FSFs"
		
	# 	# Level 1
	# 	from_file="${g_working_dir}/${g_subject}/fsf/FSFs/${g_subject}/${g_scan}_hp200_s4_level1.fsf"
	# 	to_dir="${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/"
	# 	cp --verbose ${from_file} ${to_dir}

	# else
	# 	echo "Not a tfMRI scan, not creating FSF files" 

	# fi

	# ----------------------------------------------------------------------------------------------
	# Step - Get EVs if appropriate
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Get EVs if appropriate" ${step_percent}

	if [[ ${g_scan} == tfMRI* ]] ; then
		
		from_dir=${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES/${g_scan}_unproc/LINKED_DATA/EPRIME/EVs
		echo "from_dir: ${from_dir}"

		to_dir=${g_working_dir}/${g_subject}/MNINonLinear/Results/${g_scan}/EVs
		echo "to_dir: ${to_dir}"
		
		mkdir -p ${to_dir}
		cp --verbose --remove-destination ${from_dir}/* ${to_dir}

	fi

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
