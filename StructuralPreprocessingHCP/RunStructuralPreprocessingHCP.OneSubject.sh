#!/bin/bash

if [ -z "${XNAT_PBS_JOBS}" ]; then
	echo "ERROR: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=${HOME}/pipeline_tools/xnat_utilities
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
	unset g_seed
	unset g_brainsize
	unset g_node
	unset g_output_resource
	unset g_setup_script

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
			--seed=*)
				g_seed=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--brainsize=*)
				g_brainsize=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--node=*)
				g_node=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--output-resource=*)
				g_output_resource=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
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

	if [ ! -z "${g_seed}" ]; then
		echo "Random number generator seed for recon-all: ${g_seed}"
	fi

	if [ -z "${g_node}" ]; then
		echo "Node (--node=) required"
		exit 1
	fi

	if [ ! -z "${g_brainsize}" ]; then
		echo "brainsize: ${g_brainsize}"
	fi

	if [ -z "${g_output_resource}" ]; then
		g_output_resource="Structural_preproc"
	fi
	echo "output resource: ${g_output_resource}"

	if [ ! -z "${g_setup_script}" ]; then
		echo "setup script: ${g_setup_script}"
	fi
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

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/StructuralPreprocHCP.${g_subject}"

	if [ ! -z "${g_seed}" ]; then
		working_directory_name+=".Seed${g_seed}"
	fi

	if [ ! -z "${g_brainsize}" ]; then
		working_directory_name+=".Brainsize${g_brainsize}"
	fi

	working_directory_name+=".${current_seconds_since_epoch}"

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
	get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline StructuralPreprocessingHCP -Status Queued -JSESSION ${jsession}"
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
	script_file_to_submit=${working_directory_name}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=24:00:00,vmem=32000mb" >> ${script_file_to_submit}
	echo "#PBS -q dque" >> ${script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
	echo ""
	echo "${XNAT_PBS_JOBS}/StructuralPreprocessingHCP/StructuralPreprocessingHCP.XNAT.sh \\" >> ${script_file_to_submit}
	echo "  --user=\"${token_username}\" \\" >> ${script_file_to_submit}
	echo "  --password=\"${token_password}\" \\" >> ${script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit}

	if [ ! -z "${g_seed}" ]; then
		echo "  --seed=${g_seed} \\" >> ${script_file_to_submit}
	fi

	if [ ! -z "${g_brainsize}" ]; then
		echo "  --brainsize=${g_brainsize} \\" >> ${script_file_to_submit}
	fi

	if [ ! -z "${g_setup_script}" ]; then
		echo "  --setup-script=${g_setup_script} \\" >> ${script_file_to_submit}
	fi

	echo "  --xnat-session-id=${sessionID}" >> ${script_file_to_submit}

	chmod +x ${script_file_to_submit}

	standard_out_file=${working_directory_name}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stdout
	standard_err_file=${working_directory_name}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stderr

	echo "About to ssh to ${g_node} and execute ${script_file_to_submit}"
	ssh ${g_node} "source ${HOME}/.bash_profile; ${script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"

 	# Run job to put the results in the DB
 	put_script_file_to_submit=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
 	if [ -e "${put_script_file_to_submit}" ]; then
 		rm -f "${put_script_file_to_submit}"
 	fi
		
 	touch ${put_script_file_to_submit}
 	echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
 	echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
 	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
 	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}

 	echo ""
 	echo "${XNAT_PBS_JOBS}/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
 	echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
 	echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
 	echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
 	echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
 	echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
 	echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
 	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
	echo "  --resource-suffix=\"${g_output_resource}\" " >> ${put_script_file_to_submit}

	chmod +x ${put_script_file_to_submit}

	standard_out_file=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive_PUT.stdout
	standard_err_file=${XNAT_PBS_JOBS_LOG_DIR}/${g_subject}.StructuralPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive_PUT.stderr
	${put_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}

}

# Invoke the main function to get things started
main $@
