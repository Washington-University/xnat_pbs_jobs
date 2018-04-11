#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "Environment variable XNAT_PBS_JOBS must be set!"
	exit 1
fi

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
}

main()
{
	get_options $@

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_project}/StructuralPackagingHCP.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	echo "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/${g_subject}.StructuralPackagingHCP.XNAT_PBS_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -q HCPput" >> ${script_file_to_submit}
	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}
	echo "${XNAT_PBS_JOBS}/StructuralPreprocessingHCP/StructuralPackagingHCP.sh \\" >> ${script_file_to_submit}
	echo "  --user=\"${g_user}\" \\" >> ${script_file_to_submit}
	echo "  --password=\"${g_password}\" \\" >> ${script_file_to_submit}
	echo "  --server=\"${g_server}\" \\" >> ${script_file_to_submit}
	echo "  --project=\"${g_project}\" \\" >> ${script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
	echo "  --working-dir=\"${working_directory_name}\" " >> ${script_file_to_submit}

	chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	echo "submit_cmd: ${submit_cmd}"
		
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
