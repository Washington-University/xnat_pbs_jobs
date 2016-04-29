#!/bin/bash

PIPELINE_NAME="AddResolutionHCP7T"
SCRIPT_NAME="AddResolutionHCP7T.XNAT.sh"

# echo message with script name as a prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

inform "Job started on `hostname` at `date`"

# home directory for scripts to be sourced to set up the environment
SETUP_SCRIPTS_HOME=${HOME}/SCRIPTS
inform "SETUP_SCRIPTS_HOME: ${SCRIPTS_HOME}"

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for XNAT related utilities
XNAT_UTILS_HOME=${PIPELINE_TOOLS_HOME}/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# Root directory for HCP database, packages, etc
HCP_ROOT="/HCP"
inform "HCP_ROOT: ${HCP_ROOT}"

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="${HCP_ROOT}/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

# source function libraries
source ${XNAT_UTILS_HOME}/xnat_workflow_utilities.sh
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

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
 	unset g_workflow_id
	unset g_project
	unset g_subject
	unset g_session
	unset g_working_dir
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
  			--workflow-id=*)
  				g_workflow_id=${argument/*=/""}
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
 				inform "ERROR: unrecognized option: ${argument}"
 				inform ""
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

  	if [ -z "${g_workflow_id}" ]; then
  		inform "ERROR: workflow ID (--workflow-id=) required"
  		error_count=$(( error_count + 1 ))
  	else
  		inform "g_workflow_id: ${g_workflow_id}"
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

	if [ -z "${g_working_dir}" ]; then
 		inform "ERROR: working directory (--working-dir=) required"
 		error_count=$(( error_count + 1 ))
 	else
 		inform "g_working_dir: ${g_working_dir}"
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

# Main processing
#   Carry out the necessary steps
main()
{
	get_options $@

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

 	# Set up step counters
 	total_steps=8 
 	current_step=0

 	# Set up to run Python
 	inform "Setting up to run Python"
 	source ${SETUP_SCRIPTS_HOME}/epd-python_setup.sh

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
	# Step - Set up to run PostFreeSurferPipeline_1res.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Set up to run PostFreeSurferPipeline_1res.sh script" ${step_percent}

	# Source setup script to set up environment for running the script
	inform "Sourcing ${g_setup_script} to set up environment"
	source ${g_setup_script}
	
	# ----------------------------------------------------------------------------------------------
	# Step - Run the PostFreeSurferPipeline_1res.sh script
	# ----------------------------------------------------------------------------------------------
	current_step=$(( current_step + 1 ))
	step_percent=$(( (current_step * 100) / total_steps ))

	xnat_workflow_update ${g_server} ${g_user} ${g_password} ${g_workflow_id} \
		${current_step} "Run the PostFreeSurferPipeline_1res.sh script" ${step_percent}

	SurfaceAtlasDir="${HCPPIPEDIR_Templates}/standard_mesh_atlases"
	GrayordinatesSpaceDIR="${HCPPIPEDIR_Templates}/170494_Greyordinates"
	GrayordinatesResolutions="1.60" #Usually 2mm, if multiple delimit with @, must already exist in templates dir
	HighResMesh="164" #Usually 164k vertices
	LowResMeshes="59" #Usually 32k vertices, if multiple delimit with @, must already exist in templates dir
	SubcorticalGrayLabels="${HCPPIPEDIR_Config}/FreeSurferSubcorticalLabelTableLut.txt"
	FreeSurferLabels="${HCPPIPEDIR_Config}/FreeSurferAllLut.txt"
	ReferenceMyelinMaps="${HCPPIPEDIR_Templates}/standard_mesh_atlases/Conte69.MyelinMap_BC.164k_fs_LR.dscalar.nii"
	RegName="MSMSulc" 

 	# Run the script
	cmd=""
	cmd+="${HCPPIPEDIR}/PostFreeSurfer/PostFreeSurferPipeline_1res.sh"
 	cmd+=" --path=${g_working_dir}"
 	cmd+=" --subject=${g_subject}"
	cmd+=" --surfatlasdir=${SurfaceAtlasDir}"
	cmd+=" --grayordinatesdir=${GrayordinatesSpaceDIR}"
	cmd+=" --grayordinatesres=${GrayordinatesResolutions}"
	cmd+=" --hiresmesh=${HighResMesh}"
	cmd+=" --lowresmesh=${LowResMeshes}"
	cmd+=" --subcortgraylabels=${SubcorticalGrayLabels}"
	cmd+=" --freesurferlabels=${FreeSurferLabels}"
	cmd+=" --refmyelinmaps=${ReferenceMyelinMaps}"
    cmd+=" --regname=${RegName}"

	inform ""
	inform "cmd: ${cmd}"
	inform ""

	pushd ${g_working_dir}
	${cmd}
	if [ $? -ne 0 ]; then
		die
	fi
	popd

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