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

# Subject files directory
if [ -z "${SUBJECT_FILES_DIR}" ]; then
    echo "Environment variable SUBJECT_FILES_DIR must be set!"
    exit 1
else
	echo "SUBJECT_FILES_DIR: ${SUBJECT_FILES_DIR}"
fi

printf "Connectome DB Username: "
read user

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

printf "Start Shadow Number (1-8): "
read start_shadow_number

project="HCP_500"
subject_file_name="${SUBJECT_FILES_DIR}/${project}.RestingStateStats.subjects"
echo "Retrieving subject list from: ${subject_file_name}"
subject_list_from_file=( $( cat ${subject_file_name} ) )
subjects="`echo "${subject_list_from_file[@]}"`"

max_shadow_number=8

shadow_number=${start_shadow_number}
unset put_job_no

echo "Setting up to run Python"
source ${SCRIPTS_HOME}/epd-python_setup.sh


scans="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"

subject_count=0

for subject in ${subjects} ; do

	session=${subject}_3T

	if [[ ${subject} != \#* ]]; then

		subject_count=$(( subject_count + 1 ))
		echo "subject_count: ${subject_count}"

		if [ "${subject_count}" -gt 2 ]; then
			echo "resetting subject_count"
			subject_count=1
			echo "subject_count: ${subject_count}"
			echo "unsetting put_job_no"
			unset put_job_no
			echo "put_job_no: ${put_job_no}"
		fi

		server="db-shadow${shadow_number}.nrg.mir:8080"

		echo "Getting token user id and password"
		get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${server} --username=${user}"
		get_token_cmd+=" --password=${password}"

		new_tokens=`${get_token_cmd}`
		token_username=${new_tokens% *}
		token_password=${new_tokens#* }
		echo "token_username: ${token_username}"
		echo "token_password: ${token_password}"

		echo ""
        echo "--------------------------------------------------------------------------------"
        echo " Submitting RestingStateStats job for subject: ${subject}"
        echo " Using server: ${server}"
        echo "--------------------------------------------------------------------------------"
		
		for scan in ${scans} ; do

			# make sure working directories don't have the same name based on the
			# same start time by sleeping a few seconds
			sleep 5s

			current_seconds_since_epoch=`date +%s`
			working_directory_name="${BUILD_HOME}/${project}/${current_seconds_since_epoch}_${subject}"

	        # Make the working directory
			echo "Making working directory: ${working_directory_name}"
			mkdir -p ${working_directory_name}

			# Get JSESSION ID
			echo "Getting JSESSION ID"
			jsession=`curl -u ${token_username}:${token_password} https://db.humanconnectome.org/data/JSESSION`
			echo "jsession: ${jsession}"

			# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
			echo "Getting XNAT Session ID"
			get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=db.humanconnectome.org --username=${token_username} --password=${token_password} --project=${project} --subject=${subject} --session=${session}"
			#echo "get_session_id_cmd: ${get_session_id_cmd}"
			sessionID=`${get_session_id_cmd}`
			echo "XNAT session ID: ${sessionID}"

			# Get XNAT Workflow ID
			echo "Getting XNAT workflow ID for this job"
			get_workflow_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py -User ${token_username} -Server https://db.humanconnectome.org/ -ExperimentID ${sessionID} -ProjectID ${project} -Pipeline RestingStateStats -Status Queued -JSESSION ${jsession}"
			get_workflow_id_cmd+=" -Password ${token_password}"

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
			script_file_to_submit=${working_directory_name}/${subject}.RestingStateStats.${project}.${session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
			if [ -e "${script_file_to_submit}" ]; then
				rm -f "${script_file_to_submit}"
			fi

			touch ${script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=24:00:00,vmem=16000mb" >> ${script_file_to_submit}
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
			echo "  --server=\"${server}\" \\" >> ${script_file_to_submit}
			echo "  --project=\"${project}\" \\" >> ${script_file_to_submit}
			echo "  --subject=\"${subject}\" \\" >> ${script_file_to_submit}
			echo "  --session=\"${session}\" \\" >> ${script_file_to_submit}
			echo "  --session-id=\"${sessionID}\" \\" >> ${script_file_to_submit}
			echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
			echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
			echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit}
			echo "  --jsession=\"${jsession}\" " >> ${script_file_to_submit}

			if [ -z "${put_job_no}" ]; then
				submit_cmd="qsub ${script_file_to_submit}"
			else
				submit_cmd="qsub -W depend=afterok:${put_job_no} ${script_file_to_submit}"
			fi
			echo "submit_cmd: ${submit_cmd}"

			processing_job_no=`${submit_cmd}`
			echo "processing_job_no: ${processing_job_no}"

			# Submit job to put the results in the DB
			put_script_file_to_submit=${working_directory_name}/${subject}.RestingStateStats.${project}.${session}.${scan}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
			if [ -e "${put_script_file_to_submit}" ]; then
				rm -f "${put_script_file_to_submit}"
			fi

			touch ${put_script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
			echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
			echo "#PBS -o ${LOG_DIR}" >> ${put_script_file_to_submit}
			echo "#PBS -e ${LOG_DIR}" >> ${put_script_file_to_submit}

			if [ -n "${g_notify}" ]; then
				echo "#PBS -M ${g_notify}" >> ${put_script_file_to_submit}
				echo "#PBS -m abe" >> ${put_script_file_to_submit}
			fi
			echo ""
			echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
			echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
			echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
			echo "  --server=\"${server}\" \\" >> ${put_script_file_to_submit}
			echo "  --project=\"${project}\" \\" >> ${put_script_file_to_submit}
			echo "  --subject=\"${subject}\" \\" >> ${put_script_file_to_submit}
			echo "  --session=\"${session}\" \\" >> ${put_script_file_to_submit}
			echo "  --scan=\"${scan}\" \\" >> ${put_script_file_to_submit}
			echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
			echo "  --resource-suffix=\"RSS\" " >> ${put_script_file_to_submit}

			submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
			echo "submit_cmd: ${submit_cmd}"
			put_job_no=`${submit_cmd}`
			echo "put_job_no: ${put_job_no}"
			
		done

		shadow_number=$((shadow_number + 1))

        if [ "${shadow_number}" -gt "${max_shadow_number}" ]; then
            shadow_number=${start_shadow_number}
        fi

	fi

done
