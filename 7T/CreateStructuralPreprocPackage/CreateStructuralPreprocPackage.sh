#!/bin/bash

inform() 
{
	echo "CreateStructuralPreprocPackage.sh: ${1}"
}

# home directory for pipeline tools
PIPELINE_TOOLS_HOME=${HOME}/pipeline_tools
inform "PIPELINE_TOOLS_HOME: ${PIPELINE_TOOLS_HOME}"

# home directory for these XNAT PBS job scripts
XNAT_PBS_JOBS_HOME=${PIPELINE_TOOLS_HOME}/xnat_pbs_jobs
inform "XNAT_PBS_JOBS_HOME: ${XNAT_PBS_JOBS_HOME}"

source ${XNAT_PBS_JOBS_HOME}/GetHcpDataUtils/GetHcpDataUtils.sh

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
                index=$(( index + 1 ))
                ;;
            --tmp-dir=*)
                g_tmp_dir=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
            	g_subject=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --three-t-project=*)
				g_three_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --seven-t-project=*)
				g_seven_t_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --release-notes-template-file=*)
                g_release_notes_template_file=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --output-dir=*)
                g_output_dir=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --create-checksum)
                g_create_checksum="YES"
                index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
	done

    local error_count=0
    
    # check required parameters

    echo "script name: ${g_script_name}"

    if [ -z "${g_archive_root}" ]; then
        echo "ERROR: --archive-root= required"
        error_count=$(( error_count + 1 ))
    else
        echo "archive root: ${g_archive_root}"
    fi

    if [ -z "${g_subject}" ]; then
        echo "ERROR: --subject= required"
        error_count=$(( error_count + 1 ))
    else
        echo "subject: ${g_subject}"
    fi

	if [ -z "${g_three_t_project}" ]; then
		echo "ERROR: --three-t-project= required"
		error_count=$(( error_count + 1 ))
	else
		echo "3T project: ${g_three_t_project}"
	fi

	if [ -z "${g_seven_t_project}" ]; then
		echo "ERROR: --seven-t-project= required"		
		error_count=$(( error_count + 1 ))
	else
		echo "7T project: ${g_seven_t_project}"
	fi

    if [ -z "${g_tmp_dir}" ]; then
        echo "ERROR: --tmp-dir= required"
        error_count=$(( error_count + 1 ))
    else
        echo "tmp dir: ${g_tmp_dir}"
    fi

    if [ -z "${g_release_notes_template_file}" ]; then
        echo "ERROR: --release-notes-template-file= required"
        error_count=$(( error_count + 1 ))
    else
        echo "release notes template file: ${g_release_notes_template_file}"
    fi

    if [ -z "${g_output_dir}" ]; then
        echo "ERROR: --output-dir= required"
        error_count=$(( error_count + 1 ))
    else
        echo "output dir: ${g_output_dir}"
    fi

    if [ -z "${g_create_checksum}" ]; then
        g_create_checksum="NO"
    fi
    echo "create checksum: ${g_create_checksum}"

    if [ ${error_count} -gt 0 ]; then
        echo "ERRORS DETECTED: EXITING"
        exit 1
    fi
}

build_standard_structure()
{
	# DeDriftAndResample HighRes
	link_hcp_resampled_and_dedrifted_highres_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}" 

	# DeDriftAndResample
	link_hcp_resampled_and_dedrifted_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}" 

	# PostFix data

	# FIX processed data
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*_FIX`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_FIX}
		link_hcp_fix_proc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}" 
	done

	# Functional preproc
	scan_dirs=`ls -1d ${g_subject_7T_resources_dir}/*fMRI*preproc`
	for scan_dir in ${scan_dirs} ; do
		short_scan_dir=${scan_dir##*/}
		scan=${short_scan_dir%_preproc}
		link_hcp_func_preproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${scan}" "${script_tmp_dir}" 
	done

	# Supplemental struc preproc	
	link_hcp_supplemental_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}" 

	# Structurally preproc
	link_hcp_struct_preproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}"

	# unproc

	link_hcp_struct_unproc_data "${g_archive_root}" "${g_three_t_project}" "${g_subject}" "${g_subject}_3T" "${script_tmp_dir}"
	link_hcp_7T_resting_state_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"
	link_hcp_7T_diffusion_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"
	link_hcp_7T_task_unproc_data "${g_archive_root}" "${g_seven_t_project}" "${g_subject}" "${g_subject}_7T" "${script_tmp_dir}"

	# remove db archive artifacts

	pushd ${script_tmp_dir}
	find . -name "*job.sh*" -delete
	find . -name "*catalog.xml" -delete
	find . -name "*Provenance.xml" -delete
	find . -name "*matlab.log" -delete
	find . -name "StructuralHCP.err" -delete
	find . -name "StructuralHCP.log" -delete
	popd
}

main()
{
	# get command line options
	get_options $@

	# determine name of and create temporary directory for this script's work
	short_script_name=${g_script_name%.sh}
	secs_since_epoch=`date +%s%3N`
	script_tmp_dir="${g_tmp_dir}/${g_subject}.${short_script_name}.${secs_since_epoch}"
	mkdir -p ${script_tmp_dir}

	# determine subject's 3T resources directory
	g_subject_3T_resources_dir="${g_archive_root}/${g_three_t_project}/arc001/${g_subject}_3T/RESOURCES"

	# determine subject's 7T resources directory
	g_subject_7T_resources_dir="${g_archive_root}/${g_seven_t_project}/arc001/${g_subject}_7T/RESOURCES"

	# start with a clean temporary directory for this subject
	rm -rf ${script_tmp_dir}/${g_subject}

	build_standard_structure

	mv ${script_tmp_dir}/${g_subject} ${script_tmp_dir}/${g_subject}_full

	mkdir -p ${script_tmp_dir}/${g_subject}

	file_list=""
	file_list+=" MNINonLinear/ROIs/Atlas_ROIs.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/Atlas_wmparc.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/wmparc.1.60.nii.gz "
	file_list+=" MNINonLinear/ROIs/ROIs.1.60.nii.gz "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.midthickness.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.MyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.aparc.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.atlasroi.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.corrThickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.thickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.pial.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.SmoothedMyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.ArealDistortion_FS.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.BA.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.white.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.59k_fs_LR.wb.spec "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.sphere.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.sulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.SmoothedMyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.flat.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_MSMSulc.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.SmoothedMyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SphericalDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.ArealDistortion_FS.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.thickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.thickness.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.BA.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.atlasroi.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.EdgeDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.aparc.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_BC.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.aparc.a2009s.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.sulc_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.curvature_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.MyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.1.6mm_MSMAll.59k_fs_LR.wb.spec "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.BA.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.SmoothedMyelinMap_BC.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.corrThickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.aparc.a2009s.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.curvature.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.thickness_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.pial.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.sphere.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.white.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.flat.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.curvature.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.MyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.SmoothedMyelinMap_BC.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.BiasField_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.sulc.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.midthickness.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.MyelinMap.59k_fs_LR.func.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.R.aparc.a2009s.59k_fs_LR.label.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.curvature.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.ArealDistortion_FS.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.aparc.59k_fs_LR.dlabel.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.MyelinMap_BC_1.6mm_MSMAll.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.corrThickness.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.sulc.59k_fs_LR.dscalar.nii "
	file_list+=" MNINonLinear/fsaverage_LR59k/${g_subject}.L.corrThickness.59k_fs_LR.shape.gii "
	file_list+=" MNINonLinear/T1w_restore.1.60.nii.gz "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.1.6mm_MSMAll.59k_fs_LR.wb.spec "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.59k_fs_LR.wb.spec "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.very_inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.white.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.white_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.pial.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.pial_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.inflated.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.midthickness_1.6mm_MSMAll_va.59k_fs_LR.dscalar.nii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.inflated_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness_1.6mm_MSMAll.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.midthickness_1.6mm_MSMAll_va_norm.59k_fs_LR.dscalar.nii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.white.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.midthickness_1.6mm_MSMAll_va.59k_fs_LR.shape.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.R.midthickness.59k_fs_LR.surf.gii "
	file_list+=" T1w/fsaverage_LR59k/${g_subject}.L.pial.59k_fs_LR.surf.gii "

	for file in ${file_list} ; do
		to_dir=${script_tmp_dir}/${g_subject}/${file}
		to_dir=${to_dir%/*}
		echo "to_dir: ${to_dir}"
		mkdir -p ${to_dir}
		cp -aLv ${script_tmp_dir}/${g_subject}_full/${file} ${script_tmp_dir}/${g_subject}/${file}
	done

	echo ""
	echo " Create Release Notes"
	echo ""
	release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/Structural_preproc.txt

	mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
	touch ${release_notes_file}
	echo "${g_subject}_7T_Structural_preproc.zip" >> ${release_notes_file}
	echo "" >> ${release_notes_file}
	echo `date` >> ${release_notes_file}
	echo "" >> ${release_notes_file}
	cat ${g_release_notes_template_file} >> ${release_notes_file}
	echo "" >> ${release_notes_file}

	echo ""
	echo " Create Package"
	echo ""
	
	new_package_dir="${g_output_dir}/${g_subject}/preproc"
	new_package_name="${g_subject}_7T_Structural_preproc.zip"
	new_package_path="${new_package_dir}/${new_package_name}"

	# start with a clean slate
	rm -rf ${new_package_path}
	rm -rf ${new_package_path}.md5
	mkdir -p ${new_package_dir}

	# go create the zip file
	pushd ${script_tmp_dir}
	zip_cmd="zip -r ${new_package_path} ${g_subject}"
	echo "zip_cmd: ${zip_cmd}"
	${zip_cmd}

	# make sure it's readable
	chmod u=rw,g=rw,o=r ${new_package_path}

	# create the checksum file if requested
	if [ "${g_create_checksum}" = "YES" ]; then
		echo ""
		echo " Create MD5 Checksum"
		echo ""

		pushd ${new_package_dir}
		md5sum ${new_package_name} > ${new_package_name}.md5
		chmod u=rw,g=rw,o=r ${new_package_name}.md5
		popd
	fi

	popd

	echo ""
	echo " Remove temporary directory"
	echo ""
	
	rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@

