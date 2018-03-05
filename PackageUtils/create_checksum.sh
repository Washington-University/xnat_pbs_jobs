#!/bin/bash

g_script_name=$(basename ${0})

inform()
{
	local msg=${1}
	echo "${g_script_name}: ${msg}"
}

error()
{
	local msg=${1}
	inform "ERROR: ${msg}"
}
	
abort()
{
	local msg=${1}
	inform "ABORTING: ${msg}"
	exit 1
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	abort "XNAT_PBS_JOBS ENVIRONMENT VARIABLE MUST BE DEFINED"
else
	inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
fi

get_options()
{
	local arguments=($@)

	unset g_package_dir
	unset g_package_name

	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--package-dir=*)
				g_package_dir=${argument/*=/""}
				;;
			--package-name=*)
				g_package_name=${argument/*=/""}
				;;
			*)
				abort "Unrecognized Option: ${argument}"
				;;
		esac

		index=$(( index + 1 ))
	done

	local error_count=0

	# check required parameters

	if [ -z "${g_package_dir}" ]; then
		error "--package-dir= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "package dir: ${g_package_dir}"
	fi

	if [ -z "${g_package_name}" ]; then
		error "--package-name= REQUIRED"
		error_count=$(( error_count + 1 ))
	else
		inform "package name: ${g_package_name}"
	fi

	if [ ${error_count} -gt 0 ]; then
		abort "ERRORS DETECTED: EXITING"
	fi
}

main()
{
	# get command line options
	get_options $@

	inform "Creating MD5 Checksum"

	pushd ${g_package_dir}
	md5sum ${g_package_name} > ${g_package_name}.md5
	chmod u=rw,g=rw,o=r ${g_package_name}.md5
	popd
}

# Invoke the main function to get things started
main $@
