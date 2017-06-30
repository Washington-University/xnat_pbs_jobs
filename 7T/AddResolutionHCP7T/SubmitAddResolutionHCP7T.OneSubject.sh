#!/bin/bash

# This pipeline's name
PIPELINE_NAME="AddResolutionHCP7T"
SCRIPT_NAME="SubmitAddResoultionHCP7T.OneSubject.sh"
DEFAULT_RESOURCE_NAME="Structural_preproc_supplemental"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=${HOME}/pipeline
inform "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

# home directory for XNAT utilities
XNAT_UTILS_HOME=${HOME}/pipeline_tools/xnat_utilities
inform "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

# Root directory for HCP data
HCP_ROOT="/HCP"
inform "HCP_ROOT: ${HCP_ROOT}"

# main build directory
BUILD_HOME="${HCP_ROOT}/hcpdb/build_ssd/chpc/BUILD"
inform "BUILD_HOME: ${BUILD_HOME}"

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
	unset g_output_resource
	unset g_setup_script
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
			--output-resource=*)
				g_output_resource=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--setup-script=*)
				g_setup_script=${argument/*=/""}
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
		g_project="HCP_Staging"
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

	if [ -z "${g_output_resource}" ]; then
		g_output_resource="${DEFAULT_RESOURCE_NAME}"
	fi
	inform "output resource: ${g_output_resource}"

	if [ -z "${g_clean_output_resource_first}" ]; then
		g_clean_output_resource_first="TRUE"
	fi
	inform "clean output resource first: ${g_clean_output_resource_first}"

	if [ -z "${g_setup_script}" ]; then
		inform "ERROR: set up script (--setup-script=) required"
		exit 1
	else
		inform "setup script: ${g_setup_script}"
	fi
}

main()
{
	get_options $@

	inform "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/AddResolutionHCP7T.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	inform "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Get JSESSION ID
	inform "Getting JSESSION ID"
	curl_cmd="curl -u ${g_user}:${g_password} https://${XNAT_PBS_JOBS_XNAT_SERVER}/data/JSESSION"
	jsession=`${curl_cmd}`
	inform "jsession: ${jsession}"

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
	inform "Getting XNAT Session ID"
	get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=${g_server} --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	sessionID=`${get_session_id_cmd}`
	inform "XNAT session ID: ${sessionID}"

	# Get XNAT Workflow ID
	server="https://${XNAT_PBS_JOBS_XNAT_SERVER}/"
	inform "Getting XNAT workflow ID for this job from server: ${server}"
	get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline ${PIPELINE_NAME} -Status Queued -JSESSION ${jsession}"
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
		inform "Deleting resource: ${g_output_resource} for:"
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

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/${g_subject}.AddResolutionHCP7T.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	chmod 700 ${script_file_to_submit}

	echo "#PBS -l nodes=1:ppn=1,walltime=1:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
	echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}
	echo "${HOME}/pipeline_tools/xnat_pbs_jobs/7T/AddResolutionHCP7T/AddResolutionHCP7T.XNAT.sh \\" >> ${script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
	echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit} 
	echo "  --xnat-session-id=${sessionID} \\" >> ${script_file_to_submit}
	echo "  --setup-script=${g_setup_script}" >> ${script_file_to_submit}

	#chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"

	processing_job_no=`${submit_cmd}`
	inform "processing_job_no: ${processing_job_no}"

	# Submit job to put the results in the DB
	put_script_file_to_submit=${working_directory_name}/${g_subject}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
	if [ -e "${put_script_file_to_submit}" ]; then
		rm -f "${put_script_file_to_submit}"
	fi

	touch ${put_script_file_to_submit}
	chmod 700 ${put_script_file_to_submit}

	echo "#PBS -l nodes=1:ppn=1,walltime=2:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
	echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
	echo "" >> ${put_script_file_to_submit}
	echo "${HOME}/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
	echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
	echo "  --resource-suffix=\"${g_output_resource}\" " >> ${put_script_file_to_submit}

	#chmod +x ${put_script_file_to_submit}

	submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
	inform "submit_cmd: ${submit_cmd}"
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
