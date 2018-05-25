#!/bin/bash

inform()
{
	local msg=${1}
	echo "DiffusionPackagingHCP7T.sh: ${msg}"
}

usage()
{
	inform "usage: TBW"
}

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_ref_project
	unset g_subject
	unset g_working_dir
	unset g_destination_root

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
			--ref-project=*)
				g_ref_project=${argument#*=}
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
			--dest-root=*)
				g_destination_root=${argument#*=}
				index=$(( index + 1 ))
				;;
			*)
				usage
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	local error_count=0

	if [ -z "${g_project}" ]; then
		inform "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_ref_project}" ]; then
		inform "ERROR: ref-project (--ref-project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_ref_project: ${g_ref_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_working_dir}" ]; then
		inform "ERROR: working directory (--working-dir=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_working_dir: ${g_working_dir}"
	fi

	if [ -z "${g_destination_root}" ]; then
		inform "ERROR: destination root (--dest-root=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_destination_root: ${g_destination_root}"
	fi

	if [ ${error_count} -gt 0 ]; then
		inform "For usage information, use --help"
		exit 1
	fi
}

source ${XNAT_PBS_JOBS}/shlib/utils.shlib

main()
{
	get_options $@

	inform "Setting up to run Python 3"
	set_g_python_environment
	source activate ${g_python_environment}

	inform "Getting CinaB-Style data"
	${XNAT_PBS_JOBS}/lib/hcp/hcp7t/get_cinab_style_data.py --project=${g_project} --ref-project=${g_ref_project} --subject=${g_subject} --study-dir=${g_working_dir}
	
	inform "Creating package build directory"
	package_build_dir=${g_working_dir}/package_build_dir
	mkdir -p ${package_build_dir}
	inform "Package build directory: ${package_build_dir}"

	inform "Copying files into package build directory"
	mkdir -p ${package_build_dir}/${g_subject}/T1w
	cp -auvL ${g_working_dir}/${g_subject}/T1w/T1w_acpc_dc_restore_1.05.nii.gz    ${package_build_dir}/${g_subject}/T1w

	mkdir -p ${package_build_dir}/${g_subject}/T1w/Diffusion_7T
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/data.nii.gz              ${package_build_dir}/${g_subject}/T1w/Diffusion_7T
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/bvecs                    ${package_build_dir}/${g_subject}/T1w/Diffusion_7T
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/bvals                    ${package_build_dir}/${g_subject}/T1w/Diffusion_7T
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/nodif_brain_mask.nii.gz  ${package_build_dir}/${g_subject}/T1w/Diffusion_7T
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/grad_dev.nii.gz          ${package_build_dir}/${g_subject}/T1w/Diffusion_7T

	mkdir -p ${package_build_dir}/${g_subject}/T1w/Diffusion_7T/eddylogs 
	cp -auvL ${g_working_dir}/${g_subject}/T1w/Diffusion_7T/eddylogs/*               ${package_build_dir}/${g_subject}/T1w/Diffusion_7T/eddylogs

	mkdir -p ${package_build_dir}/${g_subject}/release-notes
	cp -vL   ${XNAT_PBS_JOBS}/7T/DiffusionPreprocessingHCP7T/ReleaseNotes.txt        ${package_build_dir}/${g_subject}/release-notes

	inform "Creating package file"
	package_file_name=${g_working_dir}/${g_subject}_7T_Diffusion_preproc.zip
	inform "Package file name: ${package_file_name}"

	pushd ${package_build_dir}
	zip -r --verbose ${package_file_name} ${g_subject}
	popd

	inform "Creating checksum file"
	checksum_file_name=${package_file_name}.md5

	md5sum ${package_file_name} > ${checksum_file_name}
	chmod u=rw,g=rw,o=r ${checksum_file_name}

	inform "Moving package and checksum to destination"
	destination_dir=${g_destination_root}/${g_subject}/preproc

	inform "Destination: ${destination_dir}"
	if [ -f "${destination_dir}" ]; then
		# ${destination_dir} exists as a _regular_ file (not a directory or device file)
		# So it needs to be removed so a directory can be created.
		rm -f ${destination_dir}
	fi

	mkdir -p ${destination_dir}

	mv --verbose ${package_file_name}  ${destination_dir}
	mv --verbose ${checksum_file_name} ${destination_dir}

	rm -rf ${g_working_dir}
}

# Invoke the main function to get things started
main $@
