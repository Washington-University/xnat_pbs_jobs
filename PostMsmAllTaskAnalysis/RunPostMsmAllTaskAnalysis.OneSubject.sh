#!/bin/bash

# This pipeline's name
PIPELINE_NAME="PostMsmAllTaskAnalysis"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "RunPostMsmAllTaskAnalysis.OneSubject.sh: ${msg}"
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

# root directory for HCP data
HCP_DATA_ROOT="/HCP"
inform "HCP_DATA_ROOT: ${HCP_DATA_ROOT}"

# main build directory
BUILD_HOME="${HCP_DATA_ROOT}/hcpdb/build_ssd/chpc/BUILD"
inform "BUILD_HOME: ${BUILD_HOME}"

# set up to run Python
inform "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh

# Database Resource names and suffixes
inform "Defining Database Resource Names and Suffixes"
source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/ResourceNamesAndSuffixes.sh

# root directory of the XNAT database archive
DATABASE_ARCHIVE_ROOT="/HCP/hcpdb/archive"
inform "DATABASE_ARCHIVE_ROOT: ${DATABASE_ARCHIVE_ROOT}"

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
	unset g_node
	unset g_clean_output_resource_first

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
			--node=*)
				g_node=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--do-not-clean-first)
				g_clean_output_resource_first="FALSE"
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
		g_server="${XNAT_PBS_JOBS_XNAT_SERVER}"
	fi
	inform "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_500"
	fi
    inform "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	inform "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_3T
	fi
	inform "Connectome DB Session: ${g_session}"

	if [ -z "${g_node}" ]; then
		inform "Node (--node=) required"
		exit 1
	fi

	if [ -z "${g_clean_output_resource_first}" ]; then
		g_clean_output_resource_first="TRUE"
	fi
	inform "clean output resource first: ${g_clean_output_resource_first}"
}

main()
{
	get_options $@

	# Determine what task scans are available for the subject
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES
	
	task_scan_names=""
	task_scan_dirs=`ls -d tfMRI_*_preproc`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_preproc}
		scan_name=${scan_name%%_LR}
		scan_name=${scan_name%%_RL}
		scan_name=${scan_name##tfMRI_}
		task_scan_names=${task_scan_names//$scan_name/}
		task_scan_names+=" ${scan_name}"
	done

	popd

	inform "Task scans available for subject: ${task_scan_names}"

	# Submit jobs for each task

	for task in ${task_scan_names} ; do

		inform "--------------------------------------------------"
		inform "Submitting jobs for task: ${task}"
		inform "--------------------------------------------------"

		output_resource_name="tfMRI_${task}_${PIPELINE_NAME}"
		inform "output_resource_name: ${output_resource_name}"

		# Get token user id and password
		inform "Getting token user id and password"
		get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user}"
		get_token_cmd+=" --password=${g_password}"
		new_tokens=`${get_token_cmd}`
		token_username=${new_tokens% *}
		token_password=${new_tokens#* }
		inform "token_username: ${token_username}"
		inform "token_password: ${token_password}"
	
		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		working_directory_name="${BUILD_HOME}/${g_project}/PostMsmAllTaskAnalysis_${current_seconds_since_epoch}_${g_subject}_${task}"

		# Make the working directory
		inform "Making working directory: ${working_directory_name}"
		mkdir -p ${working_directory_name}

		# Get JSESSION ID
		inform "Getting JSESSION ID"
		jsession=`curl -u ${g_user}:${g_password} https://${XNAT_PBS_JOBS_XNAT_SERVER}/data/JSESSION`
		inform "jsession: ${jsession}"

		# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
		inform "Getting XNAT Session ID"
		get_session_id_cmd=""
		get_session_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py "
		get_session_id_cmd+="--server=${XNAT_PBS_JOBS_XNAT_SERVER} "
		get_session_id_cmd+="--username=${g_user} "
		get_session_id_cmd+="--project=${g_project} "
		get_session_id_cmd+="--subject=${g_subject} "
		get_session_id_cmd+="--session=${g_session} "
		get_session_id_cmd+=" --password=${g_password}"

		sessionID=`${get_session_id_cmd}`
		inform "XNAT session ID: ${sessionID}"

		# Get XNAT Workflow ID
		server="https://${XNAT_PBS_JOBS_XNAT_SERVER}/"
		inform "Getting XNAT workflow ID for this job from server: ${server}"
		get_workflow_id_cmd=""
		get_workflow_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py "
		get_workflow_id_cmd+="-User ${g_user} "
		get_workflow_id_cmd+="-Server ${server} "
		get_workflow_id_cmd+="-ExperimentID ${sessionID} "
		get_workflow_id_cmd+="-ProjectID ${g_project} "
		get_workflow_id_cmd+="-Pipeline PostMsmAllTaskAnalysis_${task} "
		get_workflow_id_cmd+="-Status Queued "
		get_workflow_id_cmd+="-JSESSION ${jsession} "
		get_workflow_id_cmd+=" -Password ${g_password}"
		
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
			inform "Deleting resource: ${output_resource_name} for:"
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
				--resource=${output_resource_name} \
				--force
		fi

		# Submit job to actually do the work
		script_file_to_submit=${working_directory_name}/${g_subject}.${task}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "${HOME}/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/PostMsmAllTaskAnalysis.XNAT.sh \\" >> ${script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
		echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit}
		echo "  --task=\"${task}\" " >> ${script_file_to_submit}

		chmod +x ${script_file_to_submit}

		standard_out_file=${working_directory_name}/${g_subject}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${task}.${current_seconds_since_epoch}.interactive.stdout
		standard_err_file=${working_directory_name}/${g_subject}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${task}.${current_seconds_since_epoch}.interactive.stderr

		inform "About to ssh to ${g_node} and execute ${script_file_to_submit}"
		ssh ${g_node} "source ${HOME}/.bash_profile; ${script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"

		# Submit job to put the results in the DB
		put_script_file_to_submit=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.${task}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
		if [ -e "${put_script_file_to_submit}" ]; then
			rm -f "${put_script_file_to_submit}"
		fi
		
		touch ${put_script_file_to_submit}
		echo "${HOME}/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
		echo "  --resource-suffix=\"${output_resource_name}\" \\" >> ${put_script_file_to_submit} 
		echo "  --reason=\"${PIPELINE_NAME}\" " >> ${put_script_file_to_submit}
	
		chmod +x ${put_script_file_to_submit}

		standard_out_file=${working_directory_name}/${g_subject}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${task}.${current_seconds_since_epoch}.interactive_PUT.stdout
		standard_err_file=${working_directory_name}/${g_subject}.PostMsmAllTaskAnalysis.${g_project}.${g_session}.${task}.${current_seconds_since_epoch}.interactive_PUT.stderr
		${put_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}

	done
}

# Invoke the main function to get things started
main $@
