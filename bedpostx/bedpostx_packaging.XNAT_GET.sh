#!/bin/bash

SCRIPT_NAME="bedpostx_packaging.XNAT_GET.sh"

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

source ${XNAT_PBS_JOBS}/shlib/utils.shlib

usage() 
{
	cat <<EOF

Get data from the XNAT archive necessary to create HCP bedpostx package
for an HCP 3T subject.

Usage: ${SCRIPT_NAME} PARAMETER..."

PARAMETERs are [ ] = optional; < > = user supplied value
  [--help]                 : show usage information and exit with non-zero return code
   --project=<project>     : XNAT project (e.g. HCP_500, HCP_900, HCP_Staging, ...)
   --subject=<subject>     : XNAT subject ID within project (e.g. 100307)
   --working-dir=<dir>     : Working directory in which to place retrieved data
                             and in which to produce results

EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
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
	source activate ${g_python_environment} 2>&1

	inform "Getting CinaB-Style 3T data"
	${XNAT_PBS_JOBS}/lib/hcp/hcp3t/get_cinab_style_data.py \
		--project=${g_project} \
		--subject=${g_subject} \
		--phase=DIFFUSION_BEDPOSTX \
		--study-dir=${g_working_dir}

	# Remove extraneous logs and XNAT files
	rm ${g_working_dir}/${g_subject}/${g_subject}.bedpostx.*
	rm ${g_working_dir}/${g_subject}/bedpostx.starttime
	rm ${g_working_dir}/${g_subject}/Diffusion_bedpostx_catalog.xml

	inform "Job complete on `hostname` at `date`"
}

# Invoke the main to get things started
main $@
