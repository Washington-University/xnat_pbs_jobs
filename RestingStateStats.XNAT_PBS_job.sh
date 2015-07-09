#!/bin/bash
set -e

echo "Job started on `hostname` at `date`"

SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS
echo "SCRIPTS_HOME: ${SCRIPTS_HOME}"

PIPELINE_TOOLS=/home/HCPpipeline/pipeline_tools
echo "PIPELINE_TOOLS: ${PIPELINE_TOOLS}"

XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities
echo "XNAT_UTILS_HOME: ${XNAT_UTILS_HOME}"

XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline
echo "XNAT_PIPELINE_HOME: ${XNAT_PIPELINE_HOME}"

usage()
{
    echo ""
    echo "Usage TBW"
    echo ""
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_host
	unset g_project
	unset g_subject
	unset g_session
	unset g_scan
	unset g_working_dir
	unset g_jsession

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
			--host=*)
				g_host=${argument/*=/""}
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
			--jsession=*)
				g_jsession=${argument/*=/""}
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

	if [ -z "${g_host}" ]; then
		echo "ERROR: host (--host=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_host: ${g_host}"
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

	if [ -z "${g_scan}" ]; then
		echo "ERROR: scan (--scan=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_scan: ${g_scan}"
	fi

	if [ -z "${g_working_dir}" ]; then
		echo "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_jsession}" ]; then
		echo "ERROR: jsession (--jsession=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_jsession: ${g_jsession}"
	fi

	if [ ${error_count} -gt 0 ]; then
		echo "For usage information, use --help"
		exit 1
	fi
}

show_xnat_workflow()
{
	local workflow_id=${1}
	
	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		show
}

update_xnat_workflow()
{
	local workflow_id=${1}
	local step_id=${2}
	local step_desc=${3}
	local percent_complete=${4}

	echo "update_xnat_workflow - workflow_id: ${workflow_id}"
	echo "update_xnat_workflow - step_id: ${step_id}"
	echo "update_xnat_workflow - set_desc: ${step_desc}"
	echo "update_xnat_workflow - percent_complete: ${percent_complete}"

	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		update \
		--step-id="${step_id}" \
		--step-description="${step_desc}" \
		--percent-complete="${percent_complete}"
}

complete_xnat_workflow()
{
	local workflow_id=${1}

	${XNAT_UTILS_HOME}/xnat_workflow_info \
		--username="${g_user}" \
		--password="${g_password}" \
		--workflow-id="${workflow_id}" \
		complete
}

main()
{
	get_options $@

	xnat_data_client_cmd="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
	xnat_rest_client_cmd="java -Xmx2048m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-rest-client-1.6.2-SNAPSHOT.jar"

	# Set up to run Python
	echo "Setting up to run Python"
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	# Get XNAT Session ID (subject session)
	echo "Getting XNAT Session ID"
	sessionID=`python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=${g_host} --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}`
	echo "XNAT session ID: ${sessionID}"

	# Get XNAT Workflow ID
	server="https://${g_host}/"
	echo "Getting XNAT workflow ID for this job from server: ${server}"
	workflowID=`python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${g_user} -Password ${g_password} -Server ${server} -ExperimentID ${sessionID} -ProjectID ${g_project} -Pipeline RestingStateStats -Status Queued -JSESSION ${g_jsession}`
	if [ $? -ne 0 ]; then
		echo "Fetching workflow failed. Aborting"
		exit 1
	fi
	echo "XNAT workflow ID: ${workflowID}"
	show_xnat_workflow ${workflowID}
	
	# Step 1 - Get structurally preprocessed data from DB
	update_xnat_workflow ${workflowID} 1 "Get structurally preprocessed data from DB" 10

	struct_preproc_uri="https://${g_host}"
	struct_preproc_uri+="/REST/projects/${g_project}"
	struct_preproc_uri+="/subjects/${g_subject}"
	struct_preproc_uri+="/experiments/${sessionID}"
	struct_preproc_uri+="/resources/Structural_preproc"
	struct_preproc_uri+="/files?format=zip"

	retrieval_cmd="${xnat_data_client_cmd} "
	retrieval_cmd+="-s ${g_jsession} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-r ${struct_preproc_uri} "
	retrieval_cmd+="-o ${g_subject}_Structural_preproc.zip"

	pushd ${g_working_dir}

	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd}

	unzip ${g_subject}_Structural_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/Structural_preproc/files/* ${g_subject}
	rm -rf ${g_session}
	rm ${g_subject}_Structural_preproc.zip

	popd

	# Step 2 - Get functionally preprocessed data from DB
	update_xnat_workflow ${workflowID} 2 "Get functionally preprocessed data from DB" 20

	rest_client_host="https://${g_host}"

	func_preproc_uri="REST/projects/${g_project}"
	func_preproc_uri+="/subjects/${g_subject}"
	func_preproc_uri+="/experiments/${sessionID}"
	func_preproc_uri+="/resources/${g_scan}_preproc"
	func_preproc_uri+="/files?format=zip"

	retrieval_cmd="${xnat_rest_client_cmd} "
	retrieval_cmd+="-host ${rest_client_host} "
    #retrieval_cmd+="-user_session ${g_jsession} "
	retrieval_cmd+="-u ${g_user} "
	retrieval_cmd+="-p ${g_password} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-remote ${func_preproc_uri}"

	pushd ${g_working_dir}

	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd} > ${g_subject}_${g_scan}_Functional_preproc.zip

	unzip ${g_subject}_${g_scan}_Functional_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/${g_scan}_preproc/files/* ${g_subject}
	rm -rf ${g_session}
	rm ${g_subject}_${g_scan}_Functional_preproc.zip

	popd

	# Step 3 - Get FIX processed data from DB
	update_xnat_workflow ${workflowID} 3 "Get FIX processed data from DB" 30

	rest_client_host="https://${g_host}"

	fix_proc_uri="REST/projects/${g_project}"
	fix_proc_uri+="/subjects/${g_subject}"
	fix_proc_uri+="/experiments/${sessionID}"
	fix_proc_uri+="/resources/${g_scan}_FIX"
	fix_proc_uri+="/files?format=zip"

	retrieval_cmd="${xnat_rest_client_cmd} "
	retrieval_cmd+="-host ${rest_client_host} "
	#retrieval_cmd+="-user_session ${g_jsession} "
	retrieval_cmd+="-u ${g_user} "
	retrieval_cmd+="-p ${g_password} "
	retrieval_cmd+="-m GET "
	retrieval_cmd+="-remote ${fix_proc_uri}"

	pushd ${g_working_dir}
	echo "retrieval_cmd: ${retrieval_cmd}"
	${retrieval_cmd} > ${g_subject}_${g_scan}_FIX_preproc.zip

	unzip ${g_subject}_${g_scan}_FIX_preproc.zip
	mkdir -p ${g_subject}
	rsync -auv ${g_session}/resources/${g_scan}_FIX/files/* ${g_subject}
	rm -rf ${g_session}
	rm ${g_subject}_${g_scan}_FIX_preproc.zip

	popd 

	# Step 4 - Create a start_time file
	update_xnat_workflow ${workflowID} 4 "Create a start_time file" 40

	start_time_file="${g_working_dir}/RestingStateStats.starttime"
	if [ -e "${start_time_file}" ]; then
		echo "Removing old ${start_time_file}"
		rm -f ${start_time_file}
	fi

	echo "Creating start time file: ${start_time_file}"
	touch ${start_time_file}
	ls -l ${start_time_file}

	# Step 5 - Sleep for 1 minute to make sure any files created or modified
	#          by the RestingStateStats.sh script are created at least 1 
	#          minute after the start_time file
	update_xnat_workflow ${workflowID} 5 "Sleep for 1 minute" 50
	sleep 1m

	# Step 6 - Run RestingStateStats.sh script
	update_xnat_workflow ${workflowID} 6 "Run RestingStateStats.sh script" 60

	# Source setup script to setup environment
	source ${SCRIPTS_HOME}/SetUpHCPPipeline_MSM_All.sh

	# Run RestingStateStats.sh script
	${PIPELINE_TOOLS}/Pipelines_MSM_All/RestingStateStats/RestingStateStats.sh \
		--path=${g_working_dir} \
		--subject=${g_subject} \
		--fmri-name=${g_scan} \
		--high-pass=2000 \
		--low-res-mesh=32 \
		--final-fmri-res=2 \
		--brain-ordinates-res=2 \
		--smoothing-fwhm=2 \
		--output-proc-string="_hp2000_clean"

	# Step 7 - Show any newly created or modified files
	update_xnat_workflow ${workflowID} 7 "Show newly created/modified files" 70

	echo "Newly created/modified files:"
	find ${g_working_dir} -type f -newer ${start_time_file}

	# Step 8 - Remove any files that are not newly created or modified
	update_xnat_workflow ${workflowID} 8 "Remove files not newly created or modified" 80

	echo "NOT Newly created/modified files:"
	find ${g_working_dir} -type f not -newer ${start_time_file} #-delete 

	# include removal of any empty directories
	find ${g_working_dir} -type d -empty -delete

	# Step 9 - Push new data back into DB
	update_xnat_workflow ${workflowID} 9 "Push new data back into DB" 90

	resting_state_stats_uri="https://${g_host}"
	resting_state_stats_uri+="/REST/projects/${g_project}"
	resting_state_stats_uri+="/subjects/${g_subject}"
	resting_state_stats_uri+="/experiments/${sessionID}"
	resting_state_stats_uri+="/resources/${g_scan}_RSS"
	resting_state_stats_uri+="/files"
	resting_state_stats_uri+="?overwrite=true"
	resting_state_stats_uri+="&replace=true"
	resting_state_stats_uri+="&event_reason=RestingStateStatsPipeline"
	resting_state_stats_uri+="&reference=${g_working_dir}"

	push_data_cmd="${xnat_data_client_cmd} "
	push_data_cmd="-u ${g_user} "
	push_data_cmd="-p ${g_password} "
	push_data_cmd="-m PUT "
	push_data_cmd="-remote ${resting_state_stats_uri}"
	
	echo "push_data_cmd: ${push_data_cmd}"
	echo "NOT EXECUTED YET"
	#${push_data_cmd}

	# Step 10 - Cleanup?


	# Step 11 - Complete Workflow
	complete_xnat_workflow ${workflowID}

	# Step 12 - Send email notification?
		

}

main $@