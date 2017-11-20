#!/bin/bash

SCRIPT_NAME="RunPostFix.OneSubject.sh"
HCP_ROOT="/HCP"

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=${HOME}/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# main build directory
BUILD_HOME="${HCP_ROOT}/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

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
	unset g_node

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
			--scan=*)
				g_scan=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--node=*)
				g_node=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
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
	echo "Connectome DB Server: ${g_server}"

	if [ -z "${g_project}" ]; then
		g_project="HCP_500"
	fi
    echo "Connectome DB Project: ${g_project}"

	if [ -z "${g_subject}" ]; then
		printf "Enter Connectome DB Subject: "
		read g_subject
	fi
	echo "Connectome DB Subject: ${g_subject}"

	if [ -z "${g_session}" ]; then
		g_session=${g_subject}_3T
	fi
	echo "Connectome DB Session: ${g_session}"

	if [ -z "${g_scan}" ]; then
		g_scan="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"
	fi
	echo "Connectome DB Scans: ${g_scan}"

	if [ -z "${g_node}" ]; then
		echo "Node (--node=) required"
		exit 1
	fi
}

main()
{
	get_options $@

	# Get token user id and password
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	for scan in ${g_scan} ; do

		echo "Getting token user id and password"
		get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user}"
		get_token_cmd+=" --password=${g_password}"
		new_tokens=`${get_token_cmd}`
		token_username=${new_tokens% *}
		token_password=${new_tokens#* }
		echo "token_username: ${token_username}"
		echo "token_password: ${token_password}"

		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		working_directory_name="${BUILD_HOME}/${g_project}/PostFix.${g_subject}.${scan}.${current_seconds_since_epoch}"

		# Make the working directory
		echo "Making working directory: ${working_directory_name}"
		mkdir -p ${working_directory_name}

		# Get JSESSION ID
		echo "Getting JSESSION ID"
		jsession=`curl -u ${g_user}:${g_password} https://${XNAT_PBS_JOBS_XNAT_SERVER}/data/JSESSION`
		echo "jsession: ${jsession}"

		# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
		echo "Getting XNAT Session ID"
		get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=${XNAT_PBS_JOBS_XNAT_SERVER} --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
		sessionID=`${get_session_id_cmd}`
		echo "XNAT session ID: ${sessionID}"

		# Get XNAT Workflow ID
		server="https://${XNAT_PBS_JOBS_XNAT_SERVER}/"
		echo "Getting XNAT workflow ID for this job from server: ${server}"
		get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline PostFix -Status Queued -JSESSION ${jsession}"
		get_workflow_id_cmd+=" -Password ${g_password}"

		workflowID=`${get_workflow_id_cmd}`
		if [ $? -ne 0 ]; then
			echo "Fetching workflow failed. Aborting"
			echo "workflowID: ${workflowID}"
			exit 1
		elif [[ ${workflowID} == HTTP* ]]; then
			echo "Fetching workflow failed. Aborting"
			echo "worflowID: ${workflowID}"
			exit 1
		fi
		echo "XNAT workflow ID: ${workflowID}"

		# Submit job to actually do the work
		script_file_to_submit=${working_directory_name}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "${HOME}/pipeline_tools/xnat_pbs_jobs/PostFixHCP/PostFix.XNAT.sh \\" >> ${script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
		echo "  --workflow-id=\"${workflowID}\" " >> ${script_file_to_submit}

		chmod +x ${script_file_to_submit}

		standard_out_file=${working_directory_name}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.interactive.stdout
		standard_err_file=${working_directory_name}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.interactive.stderr

		echo "About to ssh to ${g_node} and execute ${script_file_to_submit}"
		ssh ${g_node} "source ${HOME}/.bash_profile; ${script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"

		# Submit job to put the results in the DB
		put_script_file_to_submit=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
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
 		echo "  --scan=\"${scan}\" \\" >> ${put_script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
		echo "  --resource-suffix=\"PostFix\" " >> ${put_script_file_to_submit} 

		chmod +x ${put_script_file_to_submit}

		standard_out_file=${working_directory_name}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.interactive_PUT.stdout
		standard_err_file=${working_directory_name}/${g_subject}.PostFix.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.interactive_PUT.stderr
		${put_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}
		
	done
}

# Invoke the main function to get things started
main $@
