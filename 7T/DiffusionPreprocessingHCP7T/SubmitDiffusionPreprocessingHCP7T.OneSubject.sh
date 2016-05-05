#!/bin/bash

# This pipeline's name 
PIPELINE_NAME="DiffusionPreprocessingHCP7T"
DEFAULT_OUTPUT_RESOURCE_NAME="Diffusion_preproc"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "SubmitDiffusionPreprocessingHCP7T.OneSubject.sh: ${msg}"
}

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${HOME}/pipeline_tools/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
inform "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=${HOME}/pipeline_tools/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# Root directory for HCP data
HCP_DATA_ROOT="/HCP"
inform "HCP_DATA_ROOT: ${HCP_DATA_ROOT}"

# main build directory
BUILD_HOME="${HCP_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD"
inform "BUILD_HOME: ${BUILD_HOME}"

# set up to run Python
inform "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="${HCP_DATA_ROOT}/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

UNPROCESSED_SUFFIX="unproc"

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
	unset g_phase_encoding_dirs
	unset g_structural_reference_project
	unset g_structural_reference_session
	unset g_put_server
	unset g_clean_output_resource_first
	unset g_setup_script
	unset g_output_resource

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
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
			--phase-encoding-dirs=*)
				g_phase_encoding_dirs=${argument/*=/""}
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
			--put-server=*)
				g_put_server=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--do-not-clean-first)
				g_clean_output_resource_first="FALSE"
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--output-resource=*)
				g_output_resource=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	# set defaults and prompt for some unspecified parameters
	if [ -z "${g_user}" ]; then
		printf "Enter Connectome DB Username: "
		read g_user
	fi

	if [ -z "${g_password}" ]; then
		stty -echo
		printf "Enter Connectome DB Password: "
		read g_password
		echo ""
		stty echo
	fi

	if [ -z "${g_server}" ]; then
		g_server="db.humanconnectome.org"
	fi
	inform "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_Staging_7T"
	fi
    inform "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	inform "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_7T
	fi
	inform "Connectome DB Session: ${g_session}"

	if [ -z "${g_structural_reference_project}" ]; then
		inform "ERROR: --structural-reference-project= required"
		exit 1
	else
		inform "Connectome DB Structural Reference Project: ${g_structural_reference_project}"
	fi

	if [ -z "${g_structural_reference_session}" ]; then
		g_structural_reference_session=${g_subject}_3T
	fi
	inform "Connectome DB Structural Reference Session: ${g_structural_reference_session}"

	if [ -z "${g_put_server}" ]; then
		g_put_server="db.humanconnectome.org"
	fi
	inform "PUT server: ${g_put_server}"

	if [ -z "${g_clean_output_resource_first}" ]; then
		g_clean_output_resource_first="TRUE"
	fi
	inform "clean output resource first: ${g_clean_output_resource_first}"

	if [ -z "${g_setup_script}" ]; then
		inform "ERROR: set up script (--setup-script=) required"
		exit 1
	else
		inform "set up script: ${g_setup_script}"
	fi

	if [ -z "${g_phase_encoding_dirs}" ]; then
		inform "ERROR: phase encoding dir specifier (--phase-encoding-dirs=) required"
		exit 1
	else
		if [ "${g_phase_encoding_dirs}" != "RLLR" ] ; then
			if [ "${g_phase_encoding_dirs}" != "PAAP" ] ; then
				inform "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dirs}"
				exit 1
			fi
		fi
	fi

	if [ -z "${g_output_resource}" ]; then
		g_output_resource="${DEFAULT_OUTPUT_RESOURCE_NAME}"
	fi
	inform "output resource: ${g_output_resource}"
}

main()
{
	get_options $@

	# Get token user id and password
	inform "Getting token user id and password"
	get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user} --password=${g_password}"
	new_tokens=`${get_token_cmd}`
	token_username=${new_tokens% *}
	token_password=${new_tokens#* }
	inform "token_username: ${token_username}"
	inform "token_password: ${token_password}"

	# make sure working directories don't have the same name based on the 
	# same start time by sleeping a few seconds
	sleep 5s

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/${PIPELINE_NAME}.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	inform "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Get JSESSION ID
	inform "Getting JSESSION ID"
	jsession=`curl -u ${g_user}:${g_password} https://db.humanconnectome.org/data/JSESSION`
	inform "jsession: ${jsession}"

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
	inform "Getting XNAT Session ID"
	get_session_id_cmd=""
	get_session_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py "
	get_session_id_cmd+=" --server=db.humanconnectome.org "
	get_session_id_cmd+=" --username=${g_user} "
	get_session_id_cmd+=" --project=${g_project} "
	get_session_id_cmd+=" --subject=${g_subject} "
	get_session_id_cmd+=" --session=${g_session} "
	get_session_id_cmd+=" --password=${g_password} " 
	
	sessionID=`${get_session_id_cmd}`
	inform "XNAT session ID: ${sessionID}"

	# Get XNAT Workflow ID
	server="https://db.humanconnectome.org/"
	inform "Getting XNAT workflow ID for this job from server: ${server}"
	get_workflow_id_cmd=""
	get_workflow_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py"
	get_workflow_id_cmd+=" -User ${g_user} "
	get_workflow_id_cmd+=" -Server ${server} "
	get_workflow_id_cmd+=" -ExperimentID ${sessionID} "
	get_workflow_id_cmd+=" -ProjectID ${g_project} "
	get_workflow_id_cmd+=" -Pipeline ${PIPELINE_NAME} "
	get_workflow_id_cmd+=" -Status Queued "
	get_workflow_id_cmd+=" -JSESSION ${jsession} "
	get_workflow_id_cmd+=" -Password ${g_password} "
			
	workflowID=`${get_workflow_id_cmd}`
	if [ $? -ne 0 ]; then
		inform "Fetching workflow failed. Aborting"
		inform "workflowID: ${workflowID}"
		exit 1
	elif [[ ${workflowID} == HTTP* ]]; then
		inform "Fetching workflow failed. Aborting"
		inform "worflowID: ${workflowID}"
		exit 1
	fi
	inform "XNAT workflow ID: ${workflowID}"

	# Clean the output resource (unless told not to)
	if [ "${g_clean_output_resource_first}" = "TRUE" ] ; then
		inform "Deleting resource: ${output_resource} for:"
		inform "  project: ${g_project}"
		inform "  subject: ${g_subject}"
		inform "  session: ${g_session}"

		${HOME}/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/DeleteResource.sh \
			--user=${g_user} \
			--password=${g_password} \
			--server=${g_server} \
			--project=${g_project} \
			--subject=${g_subject} \
			--session=${g_session} \
			--resource=${g_output_resource} \
			--force
	fi

	# Submit job to do PreEddy work
	pre_eddy_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}_PreEddy.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${pre_eddy_script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${pre_eddy_script_file_to_submit}

	echo "#PBS -l nodes=1:ppn=1,walltime=10:00:00,vmem=16000mb" >> ${pre_eddy_script_file_to_submit}
 	echo "#PBS -o ${working_directory_name}" >> ${pre_eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${pre_eddy_script_file_to_submit}
	echo "" >> ${pre_eddy_script_file_to_submit}
	echo "${XNAT_PBS_JOBS_HOME}/7T/DiffusionPreprocessingHCP7T/DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh \\" >> ${pre_eddy_script_file_to_submit}
#	echo "  --user=\"${token_username}\" \\" >> ${pre_eddy_script_file_to_submit}
#	echo "  --password=\"${token_password}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${pre_eddy_script_file_to_submit}
#
	echo "  --server=\"${g_server}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --structural-reference-project=\"${g_structural_reference_project}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --structural-reference-session=\"${g_structural_reference_session}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${pre_eddy_script_file_to_submit} 
	echo "  --setup-script=${g_setup_script} \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --phase-encoding-dirs=\"${g_phase_encoding_dirs}\" " >> ${pre_eddy_script_file_to_submit}

	chmod +x ${pre_eddy_script_file_to_submit}

	submit_cmd="qsub ${pre_eddy_script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"			

	pre_eddy_jobno=`${submit_cmd}`
	inform "pre_eddy_jobno: ${pre_eddy_jobno}"

	if [ -z "${pre_eddy_jobno}" ] ; then
		inform "ERROR SUBMITTING PRE-EDDY JOB - ABORTING"
		exit 1
	fi

	# Submit job to do Eddy work
	eddy_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}_Eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${eddy_script_file_to_submit}" ]; then
		rm -f "${eddy_script_file_to_submit}"
	fi

	touch ${eddy_script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=3:gpus=1,walltime=16:00:00" >> ${eddy_script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${eddy_script_file_to_submit}
	echo "" >> ${eddy_script_file_to_submit}
	echo "${XNAT_PBS_JOBS_HOME}/7T/DiffusionPreprocessingHCP7T/DiffusionPreprocessingHCP7T_Eddy.XNAT.sh \\" >> ${eddy_script_file_to_submit}
#	echo "  --user=\"${token_username}\" \\" >> ${eddy_script_file_to_submit}
#	echo "  --password=\"${token_password}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${eddy_script_file_to_submit}
#
	echo "  --server=\"${g_server}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --setup-script=${g_setup_script} \\" >> ${eddy_script_file_to_submit}

	chmod +x ${eddy_script_file_to_submit}

	submit_cmd="qsub -W depend=afterok:${pre_eddy_jobno} ${eddy_script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"

	eddy_jobno=`${submit_cmd}`
	inform "eddy_jobno: ${eddy_jobno}"

	if [ -z "${eddy_jobno}" ] ; then
		inform "ERROR SUBMITTING EDDY JOB - ABORTING"
		exit 1
	fi

	# Submit job to do PostEddy work
	post_eddy_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}_PostEddy.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${post_eddy_script_file_to_submit}" ]; then
		rm -f "${post_eddy_script_file_to_submit}"
	fi

	touch ${post_eddy_script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=03:00:00,vmem=20000mb" >> ${post_eddy_script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${post_eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${post_eddy_script_file_to_submit}
	echo "" >> ${post_eddy_script_file_to_submit}
	echo "${XNAT_PBS_JOBS_HOME}/7T/DiffusionPreprocessingHCP7T/DiffusionPreprocessingHCP7T_PostEddy.XNAT.sh \\" >> ${eddy_script_file_to_submit}
#	echo "  --user=\"${token_username}\" \\" >> ${post_eddy_script_file_to_submit}
#	echo "  --password=\"${token_password}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${post_eddy_script_file_to_submit}
#
	echo "  --server=\"${g_server}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --setup-script=${g_setup_script} \\" >> ${post_eddy_script_file_to_submit}
	
	chmod +x ${post_eddy_script_file_to_submit}

	submit_cmd="qsub -W depend=afterok:${eddy_jobno} ${post_eddy_script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"

	post_eddy_jobno=`${submit_cmd}`
	inform "post_eddy_jobno: ${post_eddy_jobno}"

	if [ -z "${post_eddy_jobno}" ] ; then
		inform "ERROR SUBMITTING POST-EDDY JOB - ABORTING"
		exit 1
	fi

	# Submit job to put the results in the DB
	put_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
 	if [ -e "${put_script_file_to_submit}" ]; then
 		rm -f "${put_script_file_to_submit}"
 	fi

 	touch ${put_script_file_to_submit}
 	echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
 	echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
 	echo "#PBS -o ${LOG_DIR}" >> ${put_script_file_to_submit}
 	echo "#PBS -e ${LOG_DIR}" >> ${put_script_file_to_submit}
 	echo "" >> ${put_script_file_to_submit}
	echo "${XNAT_PBS_JOBS_HOME}/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
# 	echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
# 	echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
 	echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
 	echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
#
	echo "  --server=\"${g_put_server}\" \\" >> ${put_script_file_to_submit}
 	echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
 	echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
 	echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
 	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
	echo "  --resource-suffix=\"${g_output_resource}\" \\" >> ${put_script_file_to_submit}
	echo "  --reason=\"${PIPELINE_NAME}\" " >> ${put_script_file_to_submit}

	chmod +x ${put_script_file_to_submit}

	put_submit_cmd="qsub -W depend=afterok:${post_eddy_jobno} ${put_script_file_to_submit}"
	inform "put_submit_cmd: ${put_submit_cmd}"
		
	put_job_no=`${put_submit_cmd}`
	inform "put_job_no: ${put_job_no}"
}

# Invoke the main function to get things started
main $@

