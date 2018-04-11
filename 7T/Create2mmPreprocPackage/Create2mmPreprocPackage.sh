#!/bin/bash

inform() 
{
	echo "Create2mmPreprocPackage.sh: ${1}"
}

# home directory for these XNAT PBS job scripts
if [ -z "${XNAT_PBS_JOBS}" ] ; then
	inform "XNAT_PBS_JOBS environment variable must be set!"
	exit 1
else
	inform "XNAT_PBS_JOBS: ${XNAT_PBS_JOBS}"
fi
	
source ${XNAT_PBS_JOBS}/GetHcpDataUtils/GetHcpDataUtils.sh

get_options()
{
	local arguments=($@)

	unset g_script_name
	unset g_archive_root
	unset g_tmp_dir
	unset g_subject
	unset g_three_t_project
	unset g_seven_t_project
	unset g_release_notes_template_file
	unset g_output_dir
	unset g_create_checksum
	unset g_create_contentlist
	unset g_overwrite
	unset g_ignore_missing_files
	
	g_script_name=`basename ${0}`

	# parse arguments
	local index=0
	local numArgs=${#arguments[@]}
	local argument

	while [ ${index} -lt ${numArgs} ]; do
		argument=${arguments[index]}

        case ${argument} in
            --archive-root=*)
				g_archive_root=${argument/*=/""}
                ;;
            --tmp-dir=*)
                g_tmp_dir=${argument/*=/""}
                ;;
            --subject=*)
            	g_subject=${argument/*=/""}
                ;;
            --three-t-project=*)
				g_three_t_project=${argument/*=/""}
                ;;
            --seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
                ;;
            --release-notes-template-file=*)
                g_release_notes_template_file=${argument/*=/""}
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
                ;;
            --create-checksum)
                g_create_checksum="YES"
                ;;
			--create-contentlist)
				g_create_contentlist="YES"
				;;
			--dont-overwrite)
				g_overwrite="NO"
				;;
			--overwrite)
				g_overwrite="YES"
				;;
			--ignore-missing-files)
				g_ignore_missing_files="YES"
				;;
			*)
                inform "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac

        index=$(( index + 1 ))

	done

    local error_count=0
    
    # check required parameters

    if [ -z "${g_archive_root}" ]; then
        inform "ERROR: --archive-root= required"
        error_count=$(( error_count + 1 ))
    else
        inform "archive root: ${g_archive_root}"
    fi

    if [ -z "${g_subject}" ]; then
        inform "ERROR: --subject= required"
        error_count=$(( error_count + 1 ))
    else
        inform "subject: ${g_subject}"
    fi

	if [ -z "${g_three_t_project}" ]; then
		inform "ERROR: --three-t-project= required"
		error_count=$(( error_count + 1 ))
	else
		inform "3T project: ${g_three_t_project}"
	fi

	if [ -z "${g_seven_t_project}" ]; then
		inform "ERROR: --seven-t-project= required"		
		error_count=$(( error_count + 1 ))
	else
		inform "7T project: ${g_seven_t_project}"
	fi

    if [ -z "${g_tmp_dir}" ]; then
        inform "ERROR: --tmp-dir= required"
        error_count=$(( error_count + 1 ))
    else
        inform "tmp dir: ${g_tmp_dir}"
    fi

    if [ -z "${g_release_notes_template_file}" ]; then
        inform "ERROR: --release-notes-template-file= required"
        error_count=$(( error_count + 1 ))
    else
        inform "release notes template file: ${g_release_notes_template_file}"
    fi

    if [ -z "${g_output_dir}" ]; then
        inform "ERROR: --output-dir= required"
        error_count=$(( error_count + 1 ))
    else
        inform "output dir: ${g_output_dir}"
    fi

    if [ -z "${g_create_checksum}" ]; then
        g_create_checksum="NO"
    fi
    inform "create checksum: ${g_create_checksum}"

	if [ -z "${g_create_contentlist}" ]; then
		g_create_contentlist="NO"
	fi
	inform "create contentlist: ${g_create_contentlist}"

	if [ -z "${g_overwrite}" ]; then
		g_overwrite="YES"
	fi
	inform "overwrite: ${g_overwrite}"
	
	if [ -z "${g_ignore_missing_files}" ]; then
		g_ignore_missing_files="NO"
	fi
	inform "ignore missing files: ${g_ignore_missing_files}"

    if [ ${error_count} -gt 0 ]; then
        inform "ERRORS DETECTED: EXITING"
        exit 1
    fi
}

main()
{
	# get command line options
	get_options $@

	# determine name of and create temporary directory for this script's work
	short_script_name=${g_script_name%.sh}
	secs_since_epoch=`date +%s%3N`
	script_tmp_dir="${g_tmp_dir}/${g_subject}.${short_script_name}.${secs_since_epoch}"
	${XNAT_PBS_JOBS}/shlib/try_mkdir ${script_tmp_dir}
	if [ $? -ne 0 ]; then
		exit 1
	fi
	
	# determine subject's 3T resources directory
	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"

	# determine subject's 7T resources directory
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"

	# start with a clean temporary directory for this subject
	rm -rf ${script_tmp_dir}/${g_subject}

	# build a standard CinaB style data directory
	${XNAT_PBS_JOBS}/7T/PackageUtils/build_standard_structure.sh \
					--archive-root="${g_archive_root}" \
					--dest-dir="${script_tmp_dir}" \
					--subject="${g_subject}" \
					--three-t-project="${g_three_t_project}" \
					--seven-t-project="${g_seven_t_project}"

	mv ${script_tmp_dir}/${g_subject} ${script_tmp_dir}/${g_subject}_full

	for modality in MOVIE REST RET ; do 

		inform ""
		inform " Determine Package Name and Path"
		inform ""
		new_package_dir="${g_output_dir}/${g_subject}/preproc"
		new_package_name="${g_subject}_7T_${modality}_2mm_preproc.zip"
		new_package_path="${new_package_dir}/${new_package_name}"

		if [ -e "${new_package_path}" ] ; then
			if [ "${g_overwrite}" = "NO" ]; then
				inform "Package: ${new_package_path} exists and I've been told not to overwrite."
				inform "So, I'm moving on without creating that package."
				continue
			fi
		fi
		
		# if we get here, then we want to create the package
		rm -rf ${script_tmp_dir}/${g_subject}

		mkdir -p ${script_tmp_dir}/${g_subject}

		file_list=""

		scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*fMRI*${modality}*_preproc`
		for scan_dir in ${scan_dirs} ; do
			short_scan_dir=${scan_dir##*/}
			scan=${short_scan_dir%_preproc}
			
			parsing_str=${scan_dir##*/}
			
			prefix=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "prefix: ${prefix}"
			
			scan=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "scan: ${scan}"
			
			pe_dir=${parsing_str%%_*}
			parsing_str=${parsing_str#*_}
			inform "pe_dir: ${pe_dir}"
			
			short_name=${prefix}_${scan}_${pe_dir}
			inform "short_name: ${short_name}"
			
			long_name=${prefix}_${scan}_7T_${pe_dir}
			inform "long_name: ${long_name}"
			
			fMRIName=${long_name}
			
			file_list+=" MNINonLinear/Results/${fMRIName}/brainmask_fs.1.60.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_AbsoluteRMS_mean.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_AbsoluteRMS.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_Regressors_dt.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_Regressors.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_RelativeRMS_mean.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/Movement_RelativeRMS.txt "
			file_list+=" MNINonLinear/Results/${fMRIName}/RibbonVolumeToSurfaceMapping/goodvoxels.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_Atlas.dtseries.nii "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_Atlas_MSMAll.dtseries.nii "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_dropouts.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_Jacobian.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_PhaseOne_gdc_dc.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_PhaseTwo_gdc_dc.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_SBRef.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_sebased_bias.nii.gz "
			file_list+=" MNINonLinear/Results/${fMRIName}/${fMRIName}_sebased_reference.nii.gz "
		done
	
		inform ""
		inform "Copying listed files to directory for zipping"
		inform ""
		for file in ${file_list} ; do
			inform "file: ${file}"
			to_dir=${script_tmp_dir}/${g_subject}/${file}
			to_dir=${to_dir%/*}
			inform "to_dir: ${to_dir}"
			mkdir -p ${to_dir}
			from_file=${script_tmp_dir}/${g_subject}_full/${file}
			to_file=${script_tmp_dir}/${g_subject}/${file}
			inform "from_file = ${from_file}"
			inform "  to_file = ${to_file}"
			if [ -e "${from_file}" ]; then
				# cp -aLv ${from_file} ${to_file}
				ln -s ${from_file} ${to_file}
			else
				inform "FILE ${from_file} DOES NOT EXIST!"
				if [ "${g_ignore_missing_files}" = "YES" ]; then
					inform "Ignoring missing file as instructed"
				else
					inform "ABORTING BECAUSE OF MISSING FILE"
					exit 1
				fi
			fi
		done # All listed files copied loop
		
		inform ""
		inform " Create Release Notes"
		inform ""
		release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/${g_subject}_7T_${modality}_2mm_preproc.txt
		
		mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
		touch ${release_notes_file}
		echo `date` >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		cat ${g_release_notes_template_file} >> ${release_notes_file}
		echo "" >> ${release_notes_file}
		
		inform ""
		inform " Create Package"
		inform ""
		
		# start with a clean slate
		rm -rf ${new_package_path}
		rm -rf ${new_package_path}.md5
		mkdir -p ${new_package_dir}

		# go create the zip file
		pushd ${script_tmp_dir}
		zip_cmd="zip -r ${new_package_path} ${g_subject}"
		inform "zip_cmd: ${zip_cmd}"
		${zip_cmd}

		# make sure it's readable
		chmod u=rw,g=rw,o=r ${new_package_path}

		# create the checksum file if requested
		if [ "${g_create_checksum}" = "YES" ]; then
			${XNAT_PBS_JOBS}/PackageUtils/create_checksum.sh \
							--package-dir="${new_package_dir}" \
							--package-name="${new_package_name}"
		fi

		# create contentlist file if requested
		if [ "${g_create_contentlist}" = "YES" ]; then
			${XNAT_PBS_JOBS}/PackageUtils/build_content_list.sh \
							--package-dir="${new_package_dir}" \
							--package-name="${new_package_name}"
		fi
		
		popd

	done

	inform ""
	inform " Remove temporary directory"
	inform ""
	
	rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@

