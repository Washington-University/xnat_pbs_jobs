#!/bin/bash

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# main build directory
BUILD_HOME="/HCP/hcpdb/build_ssd/chpc/BUILD"
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
	unset g_notify
	unset g_serial

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
			--notify=*)
				g_notify=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--serial)
				g_serial="TRUE"
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

	echo "Notification Email: ${g_notify}"

	echo "Serial Submission: ${g_serial}"
}

main()
{
	get_options $@

	# Get token user id and password
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	echo "Getting token user id and password"
	get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user}"
	#echo "get_token_cmd: ${get_token_cmd}"
	get_token_cmd+=" --password=${g_password}"
	new_tokens=`${get_token_cmd}`
	token_username=${new_tokens% *}
	token_password=${new_tokens#* }
	echo "token_username: ${token_username}"
	echo "token_password: ${token_password}"

	unset depend_on_job

	for scan in ${g_scan} ; do

		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		working_directory_name="${BUILD_HOME}/${g_project}/RestingStateStats.${g_subject}.${current_seconds_since_epoch}"

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
		#echo "get_session_id_cmd: ${get_session_id_cmd}"
		sessionID=`${get_session_id_cmd}`
		echo "XNAT session ID: ${sessionID}"

		# Get XNAT Workflow ID
		server="https://${XNAT_PBS_JOBS_XNAT_SERVER}/"
		echo "Getting XNAT workflow ID for this job from server: ${server}"
		get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline RestingStateStats -Status Queued -JSESSION ${jsession}"
		#echo "get_workflow_id_cmd: ${get_workflow_id_cmd}"
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
		script_file_to_submit=${working_directory_name}/${g_subject}.RestingStateStats.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=8:00:00,vmem=32000mb" >> ${script_file_to_submit}
		echo "#PBS -q dque" >> ${script_file_to_submit}
		echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
		echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
		if [ -n "${g_notify}" ]; then
			echo "#PBS -M ${g_notify}" >> ${script_file_to_submit}
			echo "#PBS -m abe" >> ${script_file_to_submit}
		fi
		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/RestingStateStats.XNAT.sh \\" >> ${script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
		echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit}

		if [ -z "${depend_on_job}" ]; then
			submit_cmd="qsub ${script_file_to_submit}"
		else
			submit_cmd="qsub -W depend=afterok:${depend_on_job} ${script_file_to_submit}"
		fi
		echo "submit_cmd: ${submit_cmd}"
		
		processing_job_no=`${submit_cmd}`
		echo "processing_job_no: ${processing_job_no}"

		# Submit job to put the results in the DB
		put_script_file_to_submit=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.RestingStateStats.${g_project}.${g_session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
		if [ -e "${put_script_file_to_submit}" ]; then
			rm -f "${put_script_file_to_submit}"
		fi
		
		touch ${put_script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
		echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
		echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
		echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}

		if [ -n "${g_notify}" ]; then
			echo "#PBS -M ${g_notify}" >> ${put_script_file_to_submit}
			echo "#PBS -m abe" >> ${put_script_file_to_submit}
		fi
		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${put_script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
		echo "  --resource-suffix=\"RSS\" " >> ${put_script_file_to_submit} 

		submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
		echo "submit_cmd: ${submit_cmd}"
		if [ "${g_serial}" = "TRUE" ]; then
			depend_on_job=`${submit_cmd}`
		else
			${submit_cmd}
		fi

	done
}

# Invoke the main function to get things started
main $@
