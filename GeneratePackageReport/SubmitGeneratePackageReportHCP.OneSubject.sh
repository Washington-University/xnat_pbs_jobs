#!/bin/bash

SCRIPT_NAME="SubmitGeneratePackageReportHCP.OneSubject.sh"

if [ "${COMPUTE}" = "CHPC" ] ; then
	HCP_ROOT="/HCP"
elif [ "${COMPUTE}" = "NRG" ] ; then
	HCP_ROOT="/data"
elif [ "${COMPUTE}" = "" ] ; then
	HCP_ROOT="/data"
else
	echo "${SCRIPT_NAME}: unhandled value for COMPUTE environment variable"
	echo "${SCRIPT_NAME}: '${COMPUTE}' is currently not supported"
	echo "${SCRIPT_NAME}: exiting with non-zero status"
	exit 1
fi

if [ ! -d "${HCP_ROOT}" ] ; then
	echo "${SCRIPT_NAME}: Expected HCP_ROOT: ${HCP_ROOT} does not exist"
	echo "${SCRIPT_NAME}: as a directory."
	echo "${SCRIPT_NAME}: Exiting with non-zero status."
	exit 1
fi

# main build directory
BUILD_HOME="${HCP_ROOT}/hcpdb/build_ssd/chpc/BUILD"
echo "BUILD_HOME: ${BUILD_HOME}"

get_options() 
{
	local arguments=($@)

	# initialize global output variables
	unset g_subject
	unset g_archive_project
	unset g_package_project

	# parse arguments
	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--archive-project=*)
				g_archive_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--package-project=*)
				g_package_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done

	if [ -z "${g_subject}" ]; then
		printf "ERROR: --subject= REQUIRED"
		exit 1
	fi
	echo "g_subject: ${g_subject}"

	if [ -z "${g_archive_project}" ]; then
		printf "ERROR: --archive-project= REQUIRED"
		exit 1
	fi
	echo "g_archive_project: ${g_archive_project}"

	if [ -z "${g_package_project}" ]; then
		printf "ERROR: --package-project= REQUIRED"
		exit 1
	fi
	echo "g_package_project: ${g_package_project}"
}

main()
{
	get_options $@

	current_seconds_since_epoch=`date +%s`
	working_directory_name="${BUILD_HOME}/${g_package_project}/GeneratePackageReportHCP.${g_subject}.${current_seconds_since_epoch}"

	# Make the working directory
	echo "Making working directory: ${working_directory_name}"
	mkdir -p ${working_directory_name}

	# Submit job to actually do the work
	script_file_to_submit=${working_directory_name}/S${g_subject}.GeneratePackageReportHCP.XNAT_job.sh
	if [ -e "${script_file_to_submit}" ]; then
		rm -f "${script_file_to_submit}"
	fi

	results_dir="${HOME}/pipeline_tools/xnat_pbs_jobs/GeneratePackageReport/Package_${g_package_project}.Archive_${g_archive_project}"

	touch ${script_file_to_submit}
	echo "#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4000mb" >> ${script_file_to_submit}
	echo "#PBS -q HCPput" >> ${script_file_to_submit}
	echo "#PBS -o ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "#PBS -e ${XNAT_PBS_JOBS_LOG_DIR}" >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}

	echo "${HOME}/pipeline_tools/xnat_pbs_jobs/GeneratePackageReport/GeneratePackageReportHCP.sh \\" >> ${script_file_to_submit}
	echo "  --subject=\"${g_subject}\" \\" >> ${script_file_to_submit}
	echo "  --package-project=${g_package_project} \\" >> ${script_file_to_submit}
	echo "  --archive-project=${g_archive_project} \\" >> ${script_file_to_submit}
	echo "  --package-root=\"${HCP_ROOT}/hcpdb/packages/live\" \\" >> ${script_file_to_submit}
	echo "  > ${working_directory_name}/PackageReport.${g_subject}.tsv " >> ${script_file_to_submit}
	echo "" >> ${script_file_to_submit}

	echo "mkdir -p ${results_dir}" >> ${script_file_to_submit}
	echo "mv ${working_directory_name}/PackageReport.${g_subject}.tsv ${results_dir}" >> ${script_file_to_submit}
	echo "rm -rf ${working_directory_name}" >> ${script_file_to_submit}

	chmod +x ${script_file_to_submit}

	submit_cmd="qsub ${script_file_to_submit}"
	echo "submit_cmd: ${submit_cmd}"
		
	${submit_cmd}
}

# Invoke the main function to get things started
main $@
