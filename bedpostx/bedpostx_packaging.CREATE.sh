#!/bin/bash
set -e

SCRIPT_NAME="bedpostx_packaging.CREATE.sh"

inform()
{
	local msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

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
   --release-notes-template=<template-file>
                           : File containing template text for the release notes
                             to be included in the created package
   --create-checksum       : if specified, an MD5 checksum of the package file will 
                             be created
   --output-dir=<dir>      : directory in which to create package and checksum files
EOF
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_working_dir
	unset g_release_notes_template
	unset g_create_checksum
	unset g_output_dir

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
			--release-notes-template=*)
				g_release_notes_template=${argument#*=}
				index=$(( index + 1 ))
				;;
			--create-checksum)
				g_create_checksum="YES"
				index=$(( index + 1 ))
				;;
			--output-dir=*)
				g_output_dir=${argument#*=}
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

	if [ -z "${g_release_notes_template}" ]; then
		error_msgs+="\nERROR: release notes template file (--release-notes-template=) required"
	else
		inform "g_release_notes_template: ${g_release_notes_template}"
	fi
	
	if [ -z "${g_output_dir}" ]; then
		error_msgs+="\nERROR: output directory (--output-dir=) required"
	else
		inform "g_output_dir: ${g_output_dir}"
	fi

	if [ -z "${g_create_checksum}" ]; then
		g_create_checksum="NO"
	fi
	inform "g_create_checksum: ${g_create_checksum}"

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

	package_file_name=${g_subject}_bedpostx.zip
	package_file_fullpath=${g_output_dir}/${package_file_name}
	checksum_file_name=${package_file_name}.md5
	checksum_file_fullpath=${g_output_dir}/${checksum_file_name}
	release_notes_dir=${g_working_dir}/${g_subject}/release-notes
	release_notes_file_name=bedpostx.txt
	release_notes_file_fullpath=${release_notes_dir}/${release_notes_file_name}

	# Create a release notes file in place with the files to be zipped	
	inform "Create Release Notes"
	mkdir -p ${release_notes_dir}
	touch ${release_notes_file_fullpath}

	echo "${g_subject}_bedpostx.zip" >> ${release_notes_file_fullpath}
	echo "" >> ${release_notes_file_fullpath}
	echo `date` >> ${release_notes_file_fullpath}
	echo "" >> ${release_notes_file_fullpath}
	cat ${g_release_notes_template} >> ${release_notes_file_fullpath}
	echo "" >> ${release_notes_file_fullpath}

	# Make sure the output directory exists
	mkdir -p ${g_output_dir}

	# Create the package (zip file)
	rm -rf ${package_file_fullpath}
	rm -rf ${checksum_file_fullpath}
	
	pushd ${g_working_dir}
	zip_cmd="zip -r ${package_file_fullpath} ${g_subject}"
	echo "zip_cmd: ${zip_cmd}"
	${zip_cmd}

	# make sure it's readable
	chmod u=rw,g=rw,o=r ${package_file_fullpath}

	# Create the checksum file if requested
	if [ "${g_create_checksum}" = "YES" ]; then
		echo "Create MD5 Checksum"
		md5sum ${package_file_name} > ${checksum_file_name}
		chmod u=rw,g=rw,o=r ${checksum_file_name}
	fi

	popd

	inform "Job complete on `hostname` at `date`"
}

# Invoke the main to get things started
main $@
