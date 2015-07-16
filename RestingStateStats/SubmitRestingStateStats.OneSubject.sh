#!/bin/bash

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
	unset g_scans
	unset g_notify

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
			--scans=*)
				g_scans=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--notify=*)
				g_notify_email=${argument/*=/""}
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

	if [ -z "${g_scans}" ]; then
		g_scans="rfMRI_REST1_LR rfMRI_REST1_RL rfMRI_REST2_LR rfMRI_REST2_RL"
	fi
	echo "Connectome DB Scans: ${g_scans}"

	if [ -z "${g_notify_email}" ]; then
		g_notify_email="tbbrown@wustl.edu"
	fi
}

main()
{
	get_options $@

	XNAT_UTILS_HOME=/home/HCPpipeline/pipeline_tools/xnat_utilities

	# Get token user id and password
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	echo "Getting token user id and password"
	get_token_cmd="${XNAT_UTILS_HOME}/xnat_get_tokens --server=${g_server} --username=${g_user}"
	echo "get_token_cmd: ${get_token_cmd}"
	get_token_cmd+=" --password=${g_password}"
	new_tokens=`${get_token_cmd}`
	token_username=${new_tokens% *}
	token_password=${new_tokens#* }
	echo "token_username: ${token_username}"
	echo "token_password: ${token_password}"

	for scan in ${g_scans} ; do

		# make sure working directories don't have the same name based on the 
		# same start time by sleeping a few seconds
		sleep 5s

		current_seconds_since_epoch=`date +%s`
		working_directory_name="/HCP/hcpdb/build_ssd/chpc/BUILD/${g_project}/${current_seconds_since_epoch}_${g_subject}"

		# Make the working directory
		echo "Making working directory: ${working_directory_name}"
		mkdir -p ${working_directory_name}


		# Get JSESSION ID
		jsession=`curl -u ${g_user}:${g_password} https://db.humanconnectome.org/data/JSESSION`
		echo "jsession: ${jsession}"

		# Submit job to actually do the work
		script_file_to_submit=${working_directory_name}/${g_subject}.RestingStateStats.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_job.sh
		if [ -e "${script_file_to_submit}" ]; then
			rm -f "${script_file_to_submit}"
		fi

		touch ${script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=10:00:00,vmem=16000mb" >> ${script_file_to_submit}
		echo "#PBS -q dque" >> ${script_file_to_submit}
		echo "#PBS -o ${working_directory_name}" >> ${script_file_to_submit}
		echo "#PBS -e ${working_directory_name}" >> ${script_file_to_submit}
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
		echo "  --jsession=\"${jsession}\" \\" >> ${script_file_to_submit}
		echo "  --notify=tbbrown@wustl.edu"  >> ${script_file_to_submit}
		
		processing_job_no=`qsub ${script_file_to_submit}`
		echo "processing_job_no: ${processing_job_no}"

		# Submit job to put the results in the DB
		put_script_file_to_submit=${working_directory_name}/${g_subject}.RestingStateStats.${g_project}.${g_session}.${current_seconds_since_epoch}.XNAT_PBS_PUT_job.sh
		if [ -e "${put_script_file_to_submit}" ]; then
			rm -f "${put_script_file_to_submit}"
		fi
		
		db_working_dir=${working_directory_name/HCP/data}
		echo "db_working_dir: ${db_working_dir}"

		touch ${put_script_file_to_submit}
		echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${put_script_file_to_submit}
		echo "#PBS -q HCPput" >> ${put_script_file_to_submit}
		echo "#PBS -o ${working_directory_name}" >> ${put_script_file_to_submit}
		echo "#PBS -e ${working_directory_name}" >> ${put_script_file_to_submit}
		echo ""
		echo "/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/RestingStateStats.XNAT_PUT.sh \\" >> ${put_script_file_to_submit}
		echo "  --user=\"${token_username}\" \\" >> ${put_script_file_to_submit}
		echo "  --password=\"${token_password}\" \\" >> ${put_script_file_to_submit}
		echo "  --server=\"${g_server}\" \\" >> ${put_script_file_to_submit}
		echo "  --project=\"${g_project}\" \\" >> ${put_script_file_to_submit}
		echo "  --subject=\"${g_subject}\" \\" >> ${put_script_file_to_submit}
		echo "  --session=\"${g_session}\" \\" >> ${put_script_file_to_submit}
		echo "  --scan=\"${scan}\" \\" >> ${put_script_file_to_submit}
		echo "  --push-dir=\"${db_working_dir}\" \\" >> ${put_script_file_to_submit}
		echo "  --notify=tbbrown@wustl.edu"  >> ${put_script_file_to_submit}

		qsub -W depend=afterok:${processing_job_no} ${put_script_file_to_submit}
	done
}

# Invoke the main function to get things started
main $@