#!/bin/bash

ARCHIVE_ROOT="/HCP/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_3T"
PIPELINE_VERSION="v3.8.0"

usage() {
	echo "Usage information TBW"
}

get_options() {
    local arguments=($@)

    # initialize global output variables
    unset g_project
	unset g_subject
	unset g_details
	g_details="FALSE"

    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --help)
                usage
                exit 1
                ;;
            --project=*)
                g_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subject=*)
                g_subject=${argument/*=/""}
                index=$(( index + 1 ))
				;;
			--details)
				g_details="TRUE"
				index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                usage
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z ${g_project} ]; then
        echo "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z ${g_subject} ]; then
        echo "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ "${error_count}" -gt 0 ]; then
		usage
		exit 1
	fi
}

main() {

	get_options $@

	tmp_file="${g_project}.${g_subject}.tmp"

	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	subject_complete="TRUE"

	presentDir=`pwd`
	archiveDir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	#echo "archiveDir: ${archiveDir}"

	# does MSMAllReg resource exist
	msm_all_reg_resource_dir=${archiveDir}/RESOURCES/MSMAllReg

	if [ -d "${msm_all_reg_resource_dir}" ] ; then
		resource_exists="TRUE"
		resource_date=$(stat -c %y ${msm_all_reg_resource_dir})
		resource_date=${resource_date%%\.*}
	else
		resource_exists="FALSE"
		resource_date="N/A"
		subject_complete="FALSE"
	fi

	check_dir="${msm_all_reg_resource_dir}/MNINonLinear"
	files=""
	files+=" ${check_dir}/${g_subject}.ArealDistortion_MSMAll_InitalReg_2_d40_WRN.164k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.EdgeDistortion_MSMAll_InitalReg_2_d40_WRN.164k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_BC_MSMAll_InitalReg_2_d40_WRN.164k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.SphericalDistortion_MSMAll_InitalReg_2_d40_WRN.164k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.sulc_MSMAll_InitalReg_2_d40_WRN.164k_fs_LR.dscalar.nii"

	check_dir="${msm_all_reg_resource_dir}/MNINonLinear/fsaverage_LR32k"
	files+=" ${check_dir}/${g_subject}.BiasField_MSMSulc.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.EdgeDistortion_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMSulc.32k_fs_LR"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_MSMSulc.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_RSNs_d40_weights.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_Topography_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_Topography_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.individual_Topography_weights.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.L.atlas_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.atlasroi_inv.32k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.atlas_RSNs_d40.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.atlas_Topography.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.BiasField_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.BiasField_MSMSulc.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_MSMSulc.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_Topography_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_Topography_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_1.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_1_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_2.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_2_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_atlas_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_atlas_RSNs_d40.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_atlas_Topography.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.MSMSulc.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_BC_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_MSMSulc.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.R.atlas_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.atlasroi_inv.32k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.atlas_RSNs_d40.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.atlas_Topography.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.BiasField_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.BiasField_MSMSulc.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_MSMSulc.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_Topography_MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_Topography_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_1.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_1_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_2.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_2_weights.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_atlas_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_atlas_RSNs_d40.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_atlas_Topography.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_MyelinMap_BC.32k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.MSMAll_InitalReg_1_d40_WRN.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.MSMSulc.32k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.SphericalDistortion_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.sulc_MSMAll_InitalReg_2_d40_WRN.32k_fs_LR.dscalar.nii"

	check_dir="${msm_all_reg_resource_dir}/MNINonLinear/Native"
	files+=" ${check_dir}/${g_subject}.ArealDistortion_MSMAll_InitalReg_1_d40_WRN.native.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.ArealDistortion_MSMAll_InitalReg_2_d40_WRN.native.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.BiasField_MSMAll_InitalReg_2_d40_WRN.native.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.EdgeDistortion_MSMAll_InitalReg_2_d40_WRN.native.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.L.ArealDistortion_MSMAll_InitalReg_1_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.ArealDistortion_MSMAll_InitalReg_2_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.atlas_RSNs_d40.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.atlas_Topography.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.BiasField_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.BiasField_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.EdgeDistortion_MSMAll_InitalReg_2_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_RSNs_d40_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_Topography_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.individual_Topography_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_1_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_1_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_2_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.Modalities_2_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.MSMAll_InitalReg_1_d40_WRN_roi_inv.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.MSMAll_InitalReg_1_d40_WRN_roi.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.MSMSulc_roi_inv.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.MSMSulc_roi.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_individual_RSNs_d40_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_individual_Topography_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_MyelinMap_BC_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.norm_MyelinMap_BC_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.MSMAll_InitalReg_1_d40_WRN.native.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.MSMAll_InitalReg_2_d40_WRN.native.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.SphericalDistortion.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_BC_MSMAll_InitalReg_2_d40_WRN.native.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.R.ArealDistortion_MSMAll_InitalReg_1_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.ArealDistortion_MSMAll_InitalReg_2_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.atlas_RSNs_d40.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.atlas_Topography.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.BiasField_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.BiasField_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.EdgeDistortion_MSMAll_InitalReg_2_d40_WRN.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_RSNs_d40_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_Topography_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.individual_Topography_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_1_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_1_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_2_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.Modalities_2_weights.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.MSMAll_InitalReg_1_d40_WRN_roi_inv.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.MSMAll_InitalReg_1_d40_WRN_roi.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.MSMSulc_roi_inv.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.MSMSulc_roi.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_individual_RSNs_d40_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_individual_RSNs_d40_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_individual_Topography_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_MyelinMap_BC_MSMAll_InitalReg_1_d40_WRN.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.norm_MyelinMap_BC_MSMSulc.native.func.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.MSMAll_InitalReg_1_d40_WRN.native.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.MSMAll_InitalReg_2_d40_WRN.native.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.SphericalDistortion.native.shape.gii"
	files+=" ${check_dir}/${g_subject}.SphericalDistortion.native.dscalar.nii"

	check_dir="${msm_all_reg_resource_dir}/MNINonLinear/Results/rfMRI_REST"
	files+=" ${check_dir}/rfMRI_REST_Atlas_hp2000_clean_nobias_vn.dtseries.nii"

	all_files_exist="TRUE"
	for filename in ${files} ; do
			
		if [ ! -e "${filename}" ] ; then
			all_files_exist="FALSE"
			subject_complete="FALSE"

			if [ "${g_details}" = "TRUE" ]; then
				echo "Does not exist: ${filename}"
			fi
		fi
	done

	#echo -e "\tResource Exists: ${resource_exists}\tFiles Exist: ${all_files_exist}"
	echo -e "${g_subject}\t\t${g_project}\t${PIPELINE_VERSION}\tMSMAllReg\t${resource_exists}\t${resource_date}\t${all_files_exist}" >> ${tmp_file}

	if [ "${subject_complete}" = "TRUE" ]; then
		cat ${tmp_file} >> ${g_project}.complete.status
	else
		cat ${tmp_file} >> ${g_project}.incomplete.status
	fi
	cat ${tmp_file}
	rm -f ${tmp_file}
}

main $@
