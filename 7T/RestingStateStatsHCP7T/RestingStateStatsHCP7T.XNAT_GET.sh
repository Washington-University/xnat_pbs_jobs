#!/bin/bash

SCRIPT_NAME="RestingStateStatsHCP7T.XNAT_GET.sh"

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

usage()
{
	cat << EOF

Get data from the XNAT archive necessary to run the HCP RestingStateStats.sh pipeline script
for an HCP 7T subject.

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --project=<project>     : XNAT project (e.g. HCP_Staging_7T)
   --subject=<subject>     : XNAT subject ID within project (e.g. 102311)
   --structural-reference-project=<structural reference project>
                           : XNAT project (e.g. HCP_500) containing the 3T structural
                             data for this 7T subject
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_structural_reference_project
	unset g_subject
	unset g_working_dir

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
			--project=*)
				g_project=${argument#*=}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument#*=}
				index=$(( index + 1 ))
				;;
			--structural-reference-project=*)
				g_structural_reference_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--working-dir=*)
				g_working_dir=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option ${argument}"
				exit 1
				;;		
		esac

	done

	local error_msgs=""

	# check required parameters
	if [ -z "${g_project}" ]; then
		error_msgs+="\nERROR: project (--project=) required"
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		error_msgs+="\nERROR: subject (--subject=) required"
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_structural_reference_project}" ]; then
		error_msgs+="\nERROR: structural reference project (--structural-reference-project=) required"
	else
		inform "g_structural_reference_project: ${g_structural_reference_project}"
	fi

	if [ -z "${g_working_dir}" ]; then
		error_msgs+="\nERROR: working directory (--working-dir=) required"
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	# check required environment variables
	if [ -z "${XNAT_PBS_JOBS}" ]; then
		error_msgs+="\nERROR: XNAT_PBS_JOBS environment variable must be set"
	else
		inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
	fi

	if [ ! -z "${error_msgs}" ]; then
		usage
		echo -e ${error_msgs}
		exit 1
	fi
}

main()
{
	inform "Job started on `hostname` at `date`"

	inform "----- Platform Information: Begin -----"
	uname -a
	inform "----- Platform Information: End -----"

	get_options $@

	# Link CinaB-style data
	inform "Activating Python 3"
	source activate python3 2>&1

	inform "Getting CinaB-Style data"
	${XNAT_PBS_JOBS}/lib/hcp/hcp7t/get_cinab_style_data.py \
		--project=${g_project} \
		--ref-project=${g_structural_reference_project} \
		--subject=${g_subject} \
		--phase=ICAFIX \
		--study-dir=${g_working_dir} 
}

# Invoke the main to get things started
main $@
