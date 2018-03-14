#!/bin/bash

inform() 
{
	echo "CreateStructuralPreprocPackage.sh: ${1}"
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

	inform ""
	inform " Determine Package Name and Path"
	inform ""
	new_package_dir="${g_output_dir}/${g_subject}/preproc"
	new_package_name="${g_subject}_3T_Structural_1.6mm_preproc.zip"
	new_package_path="${new_package_dir}/${new_package_name}"

	if [ -e "${new_package_path}" ] ; then
		if [ "${g_overwrite}" = "NO" ]; then
			inform "Package: ${new_package_path} exists and I've been told not to overwrite."
			inform "So, I'm moving on without creating that package."
			exit
		fi
	fi

	# if we get here, then we want to create the package
	mkdir -p ${script_tmp_dir}/${g_subject}

	file_list=""
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.1.6mm_MSMAll.59k_fs_LR.wb.spec "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.59k_fs_LR.wb.spec "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.aparc.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.aparc.a2009s.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_FS.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_MSMSulc.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.BA.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.BiasField_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.corrThickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.corrThickness.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.curvature_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.curvature.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.EdgeDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.aparc.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.aparc.a2009s.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.ArealDistortion_FS.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.atlasroi.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.BA.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.corrThickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.curvature.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.flat.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.midthickness.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.MyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.MyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.pial.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.SmoothedMyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.SmoothedMyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.sphere.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.sulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.thickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.white.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_BC.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.aparc.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.aparc.a2009s.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.ArealDistortion_FS.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.atlasroi.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.BA.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.corrThickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.curvature.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.flat.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.midthickness.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.MyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.MyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.pial.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.SmoothedMyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.SmoothedMyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.sphere.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.sulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.thickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.white.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap_BC.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SphericalDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.sulc_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.sulc.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.thickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.thickness.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/ROIs/Atlas_ROIs.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/Atlas_wmparc.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/ROIs.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/wmparc.1.60.nii.gz "
	file_list+=" MNINonLinear/T1w_restore.1.60.nii.gz "
	file_list+=" MNINonLinear/T2w_restore.1.60.nii.gz "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.1.6mm_MSMAll.59k_fs_LR.wb.spec "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.59k_fs_LR.wb.spec "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.pial.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.white.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.midthickness_1.6mm_MSMAll_va.59k_fs_LR.dscalar.nii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.midthickness_1.6mm_MSMAll_va_norm.59k_fs_LR.dscalar.nii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.pial.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.white.59k_fs_LR.surf.gii "

	inform ""
	inform "Copying listed files to directory for zipping"
	inform ""
	for file in ${file_list} ; do
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
	done

	inform ""
	inform " Create Release Notes"
	inform ""
	release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/${g_subject}_3T_Structural_1.6mm_preproc.txt

	mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
	touch ${release_notes_file}
	echo "${g_subject}_3T_Structural_1.6mm_preproc.zip" >> ${release_notes_file}
	echo "" >> ${release_notes_file}
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

	inform ""
	inform " Remove temporary directory"
	inform ""
	
	rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@

