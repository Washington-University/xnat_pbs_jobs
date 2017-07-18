#!/bin/bash

# This pipeline's name 
PIPELINE_NAME="FunctionalPreprocessingHCP7T"

# echo a message with the script name as a prefix
inform()
{
	local msg=${1}
	echo "SubmitFunctionalPreprocessingHCP7T.OneSubject.sh: ${msg}"
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

TASK_FMRI_PREFIX="tfMRI"
RESTING_STATE_FMRI_PREFIX="rfMRI"

POSITVE_PHASE_ENCODING_DIRECTION="PA"
NEGATIVE_PHASE_ENCODING_DIRECTION="AP"

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
	unset g_structural_reference_project
	unset g_structural_reference_session
	unset g_put_server
	unset g_clean_output_resource_first
	unset g_setup_script
	unset g_scan
	unset g_incomplete_only
	unset g_queue
	unset g_build_home
	unset g_build_project_dir
	unset g_output_resource_suffix

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
			--scan=*)
				g_scan=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--incomplete-only)
				g_incomplete_only="TRUE"
				index=$(( index + 1 ))
				;;
			--queue=*)
				g_queue=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--build-home=*)
				g_build_home=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--build-project-dir=*)
				g_build_project_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--output-resource-suffix=*)
				g_output_resource_suffix=${argument/*=/""}
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
		g_put_server="${XNAT_PBS_JOBS_XNAT_SERVER}"
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

	if [ -z "${g_incomplete_only}" ]; then
		g_incomplete_only="FALSE"
	fi
	inform "run incomplete scans only: ${g_incomplete_only}"

	if [ ! -z "${g_queue}" ]; then
		inform "submit to queue: ${g_queue}"
	fi

	if [ -z "${g_build_home}" ]; then
		g_build_home="${BUILD_HOME}"
	fi
	inform "build home: ${g_build_home}"

	if [ -z "${g_build_project_dir}" ]; then
		g_build_project_dir="${g_project}"
	fi
	inform "build project dir: ${g_build_project_dir}"

	if [ ! -z "${g_output_resource_suffix}" ]; then
		inform "output resource suffix: ${g_output_resource_suffix}"
	fi
}

main()
{
	get_options $@

	# Determine what resting state scans are available for the subject
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES

	resting_state_scan_names=""
	resting_state_scan_dirs=`ls -d ${RESTING_STATE_FMRI_PREFIX}_*_${UNPROCESSED_SUFFIX}`
	for resting_state_scan_dir in ${resting_state_scan_dirs} ; do
		scan_name=${resting_state_scan_dir%%_${UNPROCESSED_SUFFIX}}
		scan_name=${scan_name##${RESTING_STATE_FMRI_PREFIX}_}
		resting_state_scan_names=${resting_state_scan_names//$scan_name/}
		resting_state_scan_names+=" ${scan_name}"
	done
	
	popd
	
	inform "Resting state scans available for subject: ${resting_state_scan_names}"
	
	# NOTE: Since the resting state scans are not taken in pairs of phase encoding 
	#       directions, the values in resting_state_scan_names will include the
	#       phase encoding directions.
	
	# Determine what task scans are available for the subject
	pushd ${DATABASE_ARCHIVE_ROOT}/${g_project}/arc001/${g_session}/RESOURCES
	
	task_scan_names=""
	task_scan_dirs=`ls -d ${TASK_FMRI_PREFIX}_*_${UNPROCESSED_SUFFIX}`
	for task_scan_dir in ${task_scan_dirs} ; do
		scan_name=${task_scan_dir%%_${UNPROCESSED_SUFFIX}}
		scan_name=${scan_name##${TASK_FMRI_PREFIX}_}
		task_scan_names=${task_scan_names//$scan_name/}
		task_scan_names+=" ${scan_name}"
	done
	
	popd
	
	inform "Task scans available for subject: ${task_scan_names}"
	
	# NOTE: Since the task scans are not taken in pairs of phase encoding
	#       directions, the values in task_scan_names will include the 
	#       phase encoding directions.


	if [ -z "${g_scan}" ] ; then
		# user did not specify a particular scan, so do 'em all
		scan_list="${resting_state_scan_names} ${task_scan_names}"

	else
		# user specified a particular scan e.g. REST1_PA, REST2_AP, MOVIE1_AP, RETCON_PA, etc.
		scan_list="${g_scan}"
	fi

	# Submit jobs
		
	for scan_name in ${scan_list} ; do
			
		inform "scan_name: ${scan_name}"
		
		if [ "${g_incomplete_only}" = "TRUE" ]; then
			./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=${g_project} --subject=${g_subject} --scan=${scan_name} --quiet
			if [ $? -eq 0 ]; then
				# already complete, so should not run
				should_run="FALSE"
			else
				# not already complete, so should run
				should_run="TRUE"
			fi
		else
			# run whether already complete or not
			should_run="TRUE"
		fi

		if [ "${should_run}" = "FALSE" ]; then
			continue
		fi

		resting_match_check=${resting_state_scan_names#*${scan_name}}
		task_match_check=${task_scan_names#*${scan_name}}
		
		if [ "${resting_match_check}" != "${resting_state_scan_names}" ] ; then
			inform "${scan_name} is a resting state scan"
			prefix="${RESTING_STATE_FMRI_PREFIX}"
		elif [ "${task_match_check}" != "${task_scan_names}" ] ; then
			inform "${scan_name} is a task scan"
			prefix="${TASK_FMRI_PREFIX}"
		else
			inform "Unable to determine whether ${scan_name} is a resting state or task scan"
			inform "ABORTING"
			exit 1
		fi
		
		# ------------------------------------------------------
		#  Submit jobs 
		# ------------------------------------------------------

		scan="${prefix}_${scan_name}"
		output_resource=${scan}_preproc

		if [ ! -z "${g_output_resource_suffix}" ]; then
			output_resource+="_${g_output_resource_suffix}"
		fi

		inform "--------------------------------------------------"
		inform "Submitting jobs for scan: ${scan}"
		inform "--------------------------------------------------"

		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		#working_directory_name="${BUILD_HOME}/${g_project}/${PIPELINE_NAME}.${g_subject}.${scan}.${current_seconds_since_epoch}"
		working_directory_name="${g_build_home}/${g_build_project_dir}/${PIPELINE_NAME}.${g_subject}.${scan}.${current_seconds_since_epoch}"

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
		get_workflow_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/workflow.py"
		get_workflow_id_cmd+=" -User ${g_user}"
		get_workflow_id_cmd+=" -Server ${server}"
		get_workflow_id_cmd+=" -ExperimentID ${sessionID}"
		get_workflow_id_cmd+=" -ProjectID ${g_project}"
		get_workflow_id_cmd+=" -Pipeline ${PIPELINE_NAME}_${scan}"
		get_workflow_id_cmd+=" -Status Queued"
		get_workflow_id_cmd+=" -JSESSION ${jsession}"
		get_workflow_id_cmd+=" -Password ${g_password}"
			
		workflowID=`${get_workflow_id_cmd}`
		if [ $? -ne 0 ]; then
			inform "Fetching workflow failed. Aborting"
			inform "workflowID: ${workflowID}"
			exit 1
		elif [[ ${workflowID} == HTTP* ]]; then
			inform "Fetching workflow failed. Aborting"
			inform "workflowID: ${workflowID}"
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
				--resource=${output_resource} \
				--force
		fi

		# Submit job to actually do the work
		script_file_to_submit=${working_directory_name}/${g_subject}.${scan}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		chmod 700 ${script_file_to_submit}

		if [[ ${scan} == *REST* ]] ; then
			#echo "#PBS -l nodes=1:ppn=1,walltime=24:00:00,mem=32000mb,vmem=50000mb" >> ${script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=48:00:00,mem=40000mb,vmem=64000mb" >> ${script_file_to_submit}
		elif [[ ${scan} == *MOVIE* ]]; then
			#echo "#PBS -l nodes=1:ppn=1,walltime=24:00:00,mem=32000mb,vmem=50000mb" >> ${script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=48:00:00,mem=40000mb,vmem=64000mb" >> ${script_file_to_submit}
		elif [[ ${scan} == *RET* ]]; then
			#echo "#PBS -l nodes=1:ppn=1,walltime=12:00:00,vmem=8000mb" >> ${script_file_to_submit}
			echo "#PBS -l nodes=1:ppn=1,walltime=24:00:00,vmem=8000mb" >> ${script_file_to_submit}
		else
			echo "#PBS -l nodes=1:ppn=1,walltime=36:00:00,vmem=30000mb" >> ${script_file_to_submit}
		fi

		echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
		echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}

		if [ ! -z "${g_queue}" ]; then
			echo "#PBS -q ${g_queue}" >> ${script_file_to_submit}
		fi

		cp --verbose \
		   ${XNAT_PBS_JOBS_HOME}/7T/FunctionalPreprocessingHCP7T/FunctionalPreprocessingHCP7T.XNAT.sh \
		   ${working_directory_name}
		
		echo "" >> ${script_file_to_submit}
		echo "${working_directory_name}/FunctionalPreprocessingHCP7T.XNAT.sh \\" >> ${script_file_to_submit}
		echo "  --user=\"${g_user}\" \\" >> ${script_file_to_submit}
		echo "  --password=\"${g_password}\" \\" >> ${script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${script_file_to_submit}
		echo "  --structural-reference-project=\"${g_structural_reference_project}\" \\" >> ${script_file_to_submit}
		echo "  --structural-reference-session=\"${g_structural_reference_session}\" \\" >> ${script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${script_file_to_submit}
		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${script_file_to_submit}
		echo "  --workflow-id=\"${workflowID}\" \\" >> ${script_file_to_submit} 
		echo "  --xnat-session-id=${sessionID} \\" >> ${script_file_to_submit}
		echo "  --setup-script=${g_setup_script}" >> ${script_file_to_submit}
		
		submit_cmd="qsub ${script_file_to_submit}"
		inform "submit_cmd: ${submit_cmd}"			

		processing_job_no=`${submit_cmd}`
		inform "processing_job_no: ${processing_job_no}"

		if [ -z "${processing_job_no}" ] ; then
			inform "ERROR SUBMITTING PROCESSING JOB - ABORTING"
			exit 1
		fi

		# Submit job to put the results in the DB
 		put_script_file_to_submit=${working_directory_name}/${g_subject}.${scan}.${PIPELINE_NAME}.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
 		if [ -e "${put_script_file_to_submit}" ]; then
 			rm -f "${put_script_file_to_submit}"
 		fi

 		touch ${put_script_file_to_submit}
		chmod 700 ${put_script_file_to_submit}

 		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
 		echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
 		echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
 		echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${put_script_file_to_submit}
 		echo "" >> ${put_script_file_to_submit}
		echo "${XNAT_PBS_JOBS_HOME}/WorkingDirPut/XNAT_working_dir_put.sh \\" >> ${put_script_file_to_submit}
 		echo "  --user=\"${g_user}\" \\" >> ${put_script_file_to_submit}
 		echo "  --password=\"${g_password}\" \\" >> ${put_script_file_to_submit}
		echo "  --server=\"${g_put_server}\" \\" >> ${put_script_file_to_submit}
 		echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
 		echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
 		echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
 		echo "  --working-dir=\"${working_directory_name}\" \\" >> ${put_script_file_to_submit}
		echo "  --resource-suffix=\"${output_resource}\" \\" >> ${put_script_file_to_submit}
		echo "  --reason=\"${scan}_${PIPELINE_NAME}\" " >> ${put_script_file_to_submit}

		put_submit_cmd="qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}"
		inform "put_submit_cmd: ${put_submit_cmd}"
		
		put_job_no=`${put_submit_cmd}`
		inform "put_job_no: ${put_job_no}"

	done
}

# Invoke the main function to get things started
main $@

