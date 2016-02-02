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
#   - get prerequisite data for the Strucutral Preprocessing pipeline 
#   - run the scripts
main()
{
	get_options $@

	source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
	source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

	# Set up step counters
	total_steps=12
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

	# ----------------------------------------------------------------------------------------------
	# Step - Run the GenericfMRIVolumeProcessingPipeline.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the GenericfMRIVolumeProcessingPipeline.sh script" ${step_percent}

 	# Run GenericfMRIVolumeProcessingPipeline.sh script
 	volume_cmd=""
 	volume_cmd+="${HCPPIPEDIR}/fMRIVolume/GenericfMRIVolumeProcessingPipeline.sh"
 	volume_cmd+=" --path=${g_working_dir}"
 	volume_cmd+=" --subject=${g_subject}"
 	volume_cmd+=" --fmriname=${g_scan}"
	volume_cmd+=" --fmritcs=${g_working_dir}/${g_subject}/unprocessed/3T/${g_subject}_3T_${g_scan}.nii.gz"
	volume_cmd+=" --fmriscout=${g_working_dir}/${g_subject}/unprocessed/3T/${g_subject}_3T_${g_scan}_SBRef.nii.gz"
	volume_cmd+=" --SEPhaseNeg=${g_working_dir}/${g_subject}/unprocessed/3T/${g_subject}_3T_SpinEchoFieldMap_LR.nii.gz"
	volume_cmd+=" --SEPhasePos=${g_working_dir}/${g_subject}/unprocessed/3T/${g_subject}_3T_SpinEchoFieldMap_RL.nii.gz"
	volume_cmd+=" --echospacing=0.000580002668012"  # need to get this from DB
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
	popd

	if [ $? -ne 0 ]; then
		die 
	fi

	# # ----------------------------------------------------------------------------------------------
	# # Step - Run FreeSurferPipeline.sh script
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	#     ${current_step} "Run the FreeSurferPipeline.sh script" ${step_percent}

 	# # Run FreeSurferPipeline.sh script
 	# FreeSurfer_cmd=""
	# FreeSurfer_cmd+="${HCPPIPEDIR}/FreeSurfer/FreeSurferPipeline.sh"
	# FreeSurfer_cmd+=" --subject=${g_subject}"
	# FreeSurfer_cmd+=" --subjectDIR=${g_working_dir}/${g_subject}/T1w"
	# FreeSurfer_cmd+=" --t1=${g_working_dir}/${g_subject}/T1w/T1w_acpc_dc_restore.nii.gz"
	# FreeSurfer_cmd+=" --t1brain=${g_working_dir}/${g_subject}/T1w/T1w_acpc_dc_restore_brain.nii.gz"
	# FreeSurfer_cmd+=" --t2=${g_working_dir}/${g_subject}/T1w/T2w_acpc_dc_restore.nii.gz"

	# if [ ! -z "${g_seed}" ]; then
	# 	FreeSurfer_cmd+=" --seed=${g_seed}"
	# fi

	# echo ""
	# echo "FreeSurfer_cmd: ${FreeSurfer_cmd}"
	# echo ""
	
	# pushd ${g_working_dir}
	# ${FreeSurfer_cmd}
	# popd

	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# # ----------------------------------------------------------------------------------------------
	# # Step - Run PostFreeSurferPipeline.sh script
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "Run the PostFreeSurferPipeline.sh script" ${step_percent}

 	# # Run PostFreeSurferPipeline.sh script
 	# PostFreeSurfer_cmd=""
	# PostFreeSurfer_cmd+="${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline.sh"
	# PostFreeSurfer_cmd+=" --path=${g_working_dir}"
	# PostFreeSurfer_cmd+=" --subject=${g_subject}"
	# PostFreeSurfer_cmd+=" --surfatlasdir=${HCPPIPEDIR}/global/templates/standard_mesh_atlases/"
	# PostFreeSurfer_cmd+=" --grayordinatesdir=${HCPPIPEDIR}/global/templates/91282_Greyordinates"
	# PostFreeSurfer_cmd+=" --grayordinatesres=2"
	# PostFreeSurfer_cmd+=" --hiresmesh=164"
	# PostFreeSurfer_cmd+=" --lowresmesh=32"
	# PostFreeSurfer_cmd+=" --subcortgraylabels=${HCPPIPEDIR}/global/config/FreeSurferSubcorticalLabelTableLut.txt"
	# PostFreeSurfer_cmd+=" --freesurferlabels=${HCPPIPEDIR}/global/config/FreeSurferAllLut.txt"
	# PostFreeSurfer_cmd+=" --refmyelinmaps=${HCPPIPEDIR}/global/templates/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
	# PostFreeSurfer_cmd+=" --regname=MSMSulc"

	# echo ""
	# echo "PostFreeSurfer_cmd: ${PostFreeSurfer_cmd}"
	# echo ""
	
	# pushd ${g_working_dir}
	# ${PostFreeSurfer_cmd}
	# popd

	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# # ----------------------------------------------------------------------------------------------
	# # Step - GENERATE_SNAPSHOT
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "GENERATE_SNAPSHOT" ${step_percent}

	# pushd ${g_working_dir}/${g_subject}

	# snap_montage_cmd=""
	# snap_montage_cmd+="source ${SCRIPTS_HOME}/freesurfer53_setup.sh; xvfb_wrapper.sh ${NRG_PACKAGES}/tools/HCP/Freesurfer/freesurfer_includes/snap_montage_fs5.csh"
	# snap_montage_cmd+=" ${g_subject}"
	# snap_montage_cmd+=" ${g_working_dir}/${g_subject}/T1w"

	# echo ""
	# echo "snap_montage_cmd: ${snap_montage_cmd}"
	# echo ""

	# ${snap_montage_cmd}
	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# popd

	# # ----------------------------------------------------------------------------------------------
	# # Step - CREATE_ASSESSOR
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "CREATE_ASSESSOR" ${step_percent}

 	# # Generate XNAT XML from FreeSurfer stats files
	# pushd ${g_working_dir}/${g_subject}
	# stats2xml_cmd=""
	# stats2xml_cmd+="${NRG_PACKAGES}/tools/HCP/Freesurfer/freesurfer_includes/stats2xml_mrh.pl"
	# stats2xml_cmd+=" -p ${g_project}"
	# stats2xml_cmd+=" -x ${g_xnat_session_id}"
	# stats2xml_cmd+=" -t Freesurfer"
	# stats2xml_cmd+=" -d ${TESLA_SPEC}"
	# stats2xml_cmd+=" -o ${g_working_dir}/${g_subject}/"
	# stats2xml_cmd+=" ${g_working_dir}/${g_subject}/T1w/${g_subject}/stats"

	# echo ""
	# echo "stats2xml_cmd: ${stats2xml_cmd}"
	# echo ""

	# ${stats2xml_cmd}
	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# popd

	# # ----------------------------------------------------------------------------------------------
	# # Step - Put generated FreeSurfer stats file in DB
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	#     ${current_step} "Put generated FreeSurfer stats file in DB" ${step_percent}

	# pushd ${g_working_dir}/${g_subject}

	# resource_uri="http://${g_server}/data/archive/projects/${g_project}/subjects/${g_subject}/experiments/${g_session}/assessors/${g_xnat_session_id}_freesurfer_${TESLA_SPEC}?allowDataDeletion=true&inbody=true"

	# java_cmd+="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
	# java_cmd+=" -u ${g_user}"
	# java_cmd+=" -p ${g_password}"
	# java_cmd+=" -r ${resource_uri}"	
	# java_cmd+=" -l ${g_working_dir}/${g_subject}/${g_session}_freesurfer5.xml"
	# java_cmd+=" -m PUT"

	# echo ""
	# echo "java_cmd: ${java_cmd}"
	# echo ""

	# ${java_cmd}
	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# popd

	# # ----------------------------------------------------------------------------------------------
	# # Step - Put snapshots in DB and remove local copies
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "Put snapshots in DB and remove local copies" ${step_percent}

	# pushd ${g_working_dir}/${g_subject}

	# resource_uri="http://${g_server}/data/archive/projects/${g_project}/subjects/${g_subject}/experiments/${g_session}/assessors/${g_xnat_session_id}_freesurfer_${TESLA_SPEC}/resources/SNAPSHOTS/files?overwrite=true&replace=true&reference=${g_working_dir}/T1w/${g_subject}/snapshots"

	# java_cmd+="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
	# java_cmd+=" -u ${g_user}"
	# java_cmd+=" -p ${g_password}"
	# java_cmd+=" -r ${resource_uri}"	
	# java_cmd+=" -m PUT"

	# echo ""
	# echo "java_cmd: ${java_cmd}"
	# echo ""

	# ${java_cmd}
	# if [ $? -ne 0 ]; then
	# 	die 
	# fi

	# popd

	# rm_cmd="rm -r ${g_working_dir}/T1w/${g_subject}/snapshots"
	# echo ""
	# echo "rm_cmd: ${rm_cmd}"
	# echo ""
	# ${rm_cmd}

	# ----------------------------------------------------------------------------------------------
	# Step - Show any newly created or modified files
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Show newly created or modified files" ${step_percent}
	
	echo "Newly created/modified files:"
	find ${g_working_dir}/${g_subject} -type f -newer ${start_time_file}
	
	# # ----------------------------------------------------------------------------------------------
	# # Step - Remove any files that are not newly created or modified
	# # ----------------------------------------------------------------------------------------------
	# current_step=$(( current_step + 1 ))
	# step_percent=$(( (current_step * 100) / total_steps ))

	# xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
	# 	${current_step} "Remove files not newly created or modified" ${step_percent}
	
	# echo "The following files are being removed"
	# find ${g_working_dir}/${g_subject} -not -newer ${start_time_file} -print -delete || die 
	
	# ----------------------------------------------------------------------------------------------
	# Step - Complete Workflow
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_complete ${g_server} ${g_user} ${g_password} ${g_workflow_id}
}

# Invoke the main function to get things started
main $@
