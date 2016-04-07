#!/bin/bash

# This pipeline's name
PIPELINE_NAME="DiffusionPreprocessingHCP"

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
	unset g_phase_encoding_dir
	unset g_suppress_put
	unset g_node
	unset g_gpu_node
	unset g_cuda_device_number

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
			--phase-encoding-dir=*)
				g_phase_encoding_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--suppress-put*)
				g_suppress_put="TRUE"
				index=$(( index + 1 ))
				;;
			--node=*)
				g_node=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--gpu-node=*)
				g_gpu_node=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--cuda-device_number=*)
				g_cuda_device_number=${argument/*=/""}
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
		g_server="db.humanconnectome.org"
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

	if [ -z "${g_phase_encoding_dir}" ]; then
		echo "ERROR: phase encoding dir specifier (--phase-encoding-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		if [ "${g_phase_encoding_dir}" != "RLLR" ] ; then
			if [ "${g_phase_encoding_dir}" != "PAAP" ] ; then
				echo "ERROR: Unrecognized phase encoding dir specifier: ${g_phase_encoding_dir}"
				exit 1
			fi
		fi
	fi

	if [ -z "${g_suppress_put}" ]; then
		g_suppress_put="FALSE"
	fi
	echo "Suppress PUT: ${g_suppress_put}"

	if [ -z "${g_node}" ]; then
		echo "Node (--node=) required"
		exit 1
	fi

	if [ -z "${g_gpu_node}" ]; then
		echo "GPU Node (--gpu-node=) required"
		exit 1
	fi

	if [ -z "${g_cuda_device_number}" ]; then
		g_cuda_device_number="0"
	fi
	echo "CUDA Device Number: ${g_cuda_device_number}"
}

main()
{
	get_options $@

	# Get token user id and password
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	echo "Getting token user id and password"
	get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user} --password=${g_password}"
	new_tokens=`${get_token_cmd}`
	token_username=${new_tokens% *}
	token_password=${new_tokens#* }
	echo "token_username: ${token_username}"
	echo "token_password: ${token_password}"

	unset pre_eddy_jobno

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/DiffusionHCP.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	echo "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Get JSESSION ID
	echo "Getting JSESSION ID"
	jsession=`curl -u ${g_user}:${g_password} https://db.humanconnectome.org/data/JSESSION`
	echo "jsession: ${jsession}"

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
	echo "Getting XNAT Session ID"
	get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=db.humanconnectome.org --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	#echo "get_session_id_cmd: ${get_session_id_cmd}"
	sessionID=`${get_session_id_cmd}`
	echo "XNAT session ID: ${sessionID}"

	# Get XNAT Workflow ID
	server="https://db.humanconnectome.org/"
	echo "Getting XNAT workflow ID for this job from server: ${server}"
	get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline ${PIPELINE_NAME} -Status Queued -JSESSION ${jsession}"
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

	# Submit job to do PreEddy work
	pre_eddy_script_file_to_submit=${working_directory_name}/${g_subject}.DiffusionPreprocHCP_PreEddy.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${pre_eddy_script_file_to_submit}" ]; then
		rm -f "${pre_eddy_script_file_to_submit}"
	fi

	touch ${pre_eddy_script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=10:00:00,vmem=16000mb" >> ${pre_eddy_script_file_to_submit}
	#echo "#PBS -q dque" >> ${pre_eddy_script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${pre_eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${pre_eddy_script_file_to_submit}
	echo "" >> ${pre_eddy_script_file_to_submit}
	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/DiffusionPreprocessingHCP_PreEddy.XNAT.sh \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --user=\"${token_username}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --password=\"${token_password}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${pre_eddy_script_file_to_submit}
	echo "  --phase-encoding-dir=\"${g_phase_encoding_dir}\" " >> ${pre_eddy_script_file_to_submit}

	chmod +x ${pre_eddy_script_file_to_submit}

	standard_out_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.pre_eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stdout
	standard_err_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.pre_eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stderr

	echo "About to ssh to ${g_node} and execute ${pre_eddy_script_file_to_submit}"
	ssh ${g_node} "source ${HOME}/.bash_profile; ${pre_eddy_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"

	# Submit job to do Eddy work
	eddy_script_file_to_submit=${working_directory_name}/${g_subject}.DiffusionPreprocHCP_Eddy.${g_project}.${g_subject}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${eddy_script_file_to_submit}" ]; then
		rm -f "${eddy_script_file_to_submit}"
	fi

	touch ${eddy_script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=3:gpus=1,walltime=16:00:00" >> ${eddy_script_file_to_submit}
	#echo "#PBS -q dque_gpu" >> ${eddy_script_file_to_submit}
	#echo "#PBS -q dque" >> ${eddy_script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${eddy_script_file_to_submit}
	echo "" >> ${eddy_script_file_to_submit}
	echo "export CUDA_VISIBLE_DEVICES=${g_cuda_device_number}" >> ${eddy_script_file_to_submit}
	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/DiffusionPreprocessingHCP_Eddy.XNAT.sh \\" >> ${eddy_script_file_to_submit}
	echo "  --user=\"${token_username}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --password=\"${token_password}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" " >> ${eddy_script_file_to_submit}

	chmod +x ${eddy_script_file_to_submit}

	standard_out_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stdout
	standard_err_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stderr

	echo "About to ssh to ${g_gpu_node} and execute ${eddy_script_file_to_submit}"
	ssh ${g_gpu_node} "source ${HOME}/.bash_profile; ${eddy_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"

	# Submit job to do PostEddy work
	post_eddy_script_file_to_submit=${working_directory_name}/${g_subject}.DiffusionPreprocHCP_PostEddy.${g_project}.${g_subject}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh

	if [ -e "${post_eddy_script_file_to_submit}" ]; then
		rm -f "${post_eddy_script_file_to_submit}"
	fi

	touch ${post_eddy_script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=03:00:00,vmem=20000mb" >> ${post_eddy_script_file_to_submit}
	#echo "#PBS -q dque" >> ${post_eddy_script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${post_eddy_script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${post_eddy_script_file_to_submit}
	echo "" >> ${post_eddy_script_file_to_submit}
	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/DiffusionPreprocessingHCP_PostEddy.XNAT.sh \\" >> ${post_eddy_script_file_to_submit}
	echo "  --user=\"${token_username}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --password=\"${token_password}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${post_eddy_script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${post_eddy_script_file_to_submit}

	chmod +x ${post_eddy_script_file_to_submit}

	standard_out_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.post_eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stdout
	standard_err_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.post_eddy.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive.stderr
	
	echo "About to ssh to ${g_node} and execute ${post_eddy_script_file_to_submit}"
	ssh ${g_node} "source ${HOME}/.bash_profile; ${post_eddy_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}"
   
	# Submit job to put the results in the DB
	put_script_file_to_submit=${LOG_DIR}/${g_subject}.DiffusionPreprocHCP.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
 	if [ -e "${put_script_file_to_submit}" ]; then
 		rm -f "${put_script_file_to_submit}"
 	fi

 	touch ${put_script_file_to_submit}
 	echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
 	echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
 	echo "#PBS -o ${LOG_DIR}" >> ${put_script_file_to_submit}
 	echo "#PBS -e ${LOG_DIR}" >> ${put_script_file_to_submit}
 	echo "" >> ${put_script_file_to_submit}
 	echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
 	echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
 	echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
 	echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
 	echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
 	echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
 	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
	echo "  --resource-suffix=\"Diffusion_preproc\" " >> ${put_script_file_to_submit}

	chmod +x ${put_script_file_to_submit}

	standard_out_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive_PUT.stdout
	standard_err_file=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.interactive_PUT.stderr
	${put_script_file_to_submit} > ${standard_out_file} 2>${standard_err_file}

}

# Invoke the main function to get things started
main $@
