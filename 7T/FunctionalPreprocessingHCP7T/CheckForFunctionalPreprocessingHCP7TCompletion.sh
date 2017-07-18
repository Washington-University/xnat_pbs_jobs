#!/bin/bash

inform()
{
	local msg=${1}
	echo "CheckForFunctionalPreprocessingHCP7TCompletion.sh: ${msg}"
}

check_file_exists() 
{
	local filename=${1}
	if [ ! -e "${filename}" ]; then
		g_all_files_exist="FALSE"
		g_subject_complete="FALSE"
		if [ "${g_details}" = "TRUE" ]; then
			echo "File does not exist: ${filename}"
		fi
	fi
}

if [ "${COMPUTE}" = "NRG" ] ; then
	HCP_DATA_ROOT="/data"
elif [ "${COMPUTE}" = "CHPC" ] ; then
	HCP_DATA_ROOT="/HCP"
else
	inform "COMPUTE environment '${COMPUTE}' is current not supported"
	inform "Exiting with non-zero status (Unsuccessful execution)"
	exit 1
fi

ARCHIVE_ROOT="${HCP_DATA_ROOT}/hcpdb/archive"
ARCHIVE_PROJ_SUBDIR="arc001"
TESLA_SPEC="_7T"

FULL_SCANS_LIST=""
FULL_SCANS_LIST+=" REST1_PA "
FULL_SCANS_LIST+=" REST2_AP "
FULL_SCANS_LIST+=" REST3_PA "
FULL_SCANS_LIST+=" REST4_AP "
FULL_SCANS_LIST+=" MOVIE1_AP "
FULL_SCANS_LIST+=" MOVIE2_PA "
FULL_SCANS_LIST+=" MOVIE3_PA "
FULL_SCANS_LIST+=" MOVIE4_AP "
FULL_SCANS_LIST+=" RETBAR1_AP "
FULL_SCANS_LIST+=" RETBAR2_PA "
FULL_SCANS_LIST+=" RETCCW_AP "
FULL_SCANS_LIST+=" RETCON_PA "
FULL_SCANS_LIST+=" RETCW_PA "
FULL_SCANS_LIST+=" RETEXP_AP "

RESTING_PREFIX="rfMRI_"
TASK_PREFIX="tfMRI_"

UNPROC_SUFFIX="_unproc"
PREPROC_SUFFIX="_preproc"

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_project
	unset g_subject
	unset g_details
	g_details="FALSE"
	unset g_scans
	g_report_level="NORMAL"
	unset g_post_patch
	g_post_patch="FALSE"

    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
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
			--scan=*)
				g_scans+=" "
				g_scans+=${argument/*=/""}
				g_scans+=" "
				index=$(( index + 1 ))
                ;;
			--quiet)
				g_report_level="QUIET"
				index=$(( index + 1 ))
                ;;
			--verbose)
				g_report_level="VERBOSE"
				index=$(( index + 1 ))
                ;;
			--post-patch)
				g_post_patch="TRUE"
				index=$(( index + 1 ))
                ;;
            *)
                inform "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z "${g_project}" ]; then
        inform "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z "${g_subject}" ]; then
        inform "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ -z "${g_scans}" ]; then
		g_scans=${FULL_SCANS_LIST}
	fi

	if [ "${error_count}" -gt 0 ]; then
		exit 1
	fi
}

verbose_msg()
{
	local msg=${1}
	if [ "${g_report_level}" = "VERBOSE" ] ; then
		msg="VERBOSE: ${msg}"
		inform "${msg}"
	fi
}

main()
{
	get_options $@

	start_dir=${PWD}

	tmp_file=${start_dir}/${g_project}.${g_subject}.tmp
	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	g_subject_complete="TRUE"

	archive_dir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	resources_dir="${archive_dir}/RESOURCES"

	for scan in ${g_scans} ; do

		verbose_msg "scan: ${scan}"

		resting_state_scan="FALSE"
		if [[ ${scan} == *REST* ]]; then
			resting_state_scan="TRUE"
		fi
		verbose_msg "resting_state_scan: ${resting_state_scan}"

		movie_scan="FALSE"
		if [[ ${scan} == *MOVIE* ]]; then
			movie_scan="TRUE"
		fi
		verbose_msg "movie_scan: ${movie_scan}"

		retinotopy_scan="FALSE"
		if [[ ${scan} == *RET* ]]; then
			retinotopy_scan="TRUE"
		fi
		verbose_msg "retinotopy_scan: ${retinotopy_scan}"

		if [ "${resting_state_scan}" = "TRUE" ] ; then
			prefix=${RESTING_PREFIX}
		else
			prefix=${TASK_PREFIX}
		fi

		unproc_resource_dir=${resources_dir}/${prefix}${scan}${UNPROC_SUFFIX}
		short_preproc_resource_dir=${prefix}${scan}${PREPROC_SUFFIX}
		preproc_resource_dir=${resources_dir}/${short_preproc_resource_dir}
		
		scan_without_pe_dir=${scan%_*}
		verbose_msg "scan_without_pe_dir: ${scan_without_pe_dir}"
		pe_dir=${scan#*_}
		verbose_msg "pe_dir: ${pe_dir}"

		# Does unprocessed resource for this scan exist?
		if [ -d "${unproc_resource_dir}" ] ; then
			verbose_msg "Unprocessed resource directory for this scan does exist"

			# Does preprocessed resource for this scan exist?
			if [ -d "${preproc_resource_dir}" ] ; then
				verbose_msg "Preprocessed resource exists, i've got some checking to do"
				preproc_resource_exists="TRUE"

				preproc_resource_date=$(stat -c %y ${preproc_resource_dir})
				preproc_resource_date=${preproc_resource_date%%\.*}

				# Do the expected files exist
				g_all_files_exist="TRUE"

				check_dir=${preproc_resource_dir}   # rfMRI_REST1_PA_preproc
				check_dir=${check_dir}/MNINonLinear # rfMRI_REST1_PA_preproc/MNINonLinear
				check_dir=${check_dir}/Results      # rfMRI_REST1_PA_preproc/MNINonLinear/Results
				check_dir=${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir} # rfMRI_REST1_7T_preproc/MNINonLinear/Results/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/RibbonVolumeToSurfaceMapping # rfMRI_REST1_7T_preproc/MNINonLinear/Results/rfMRI_REST1_7T_PA/RibbonVolumeToSurfaceMapping
				verbose_msg "1. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/cov.nii.gz"
				check_file_exists "${check_dir}/cov_norm_modulate.nii.gz"
				check_file_exists "${check_dir}/cov_norm_modulate_ribbon.nii.gz"
				check_file_exists "${check_dir}/cov_ribbon.nii.gz"
				check_file_exists "${check_dir}/cov_ribbon_norm.nii.gz"
				check_file_exists "${check_dir}/cov_ribbon_norm_s5.nii.gz"
				check_file_exists "${check_dir}/goodvoxels.nii.gz"
				check_file_exists "${check_dir}/L.cov.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.cov.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.cov_all.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.cov_all.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.cov_all.native.func.gii"
				check_file_exists "${check_dir}/L.cov.native.func.gii"
				check_file_exists "${check_dir}/L.goodvoxels.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.goodvoxels.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.goodvoxels.native.func.gii"
				check_file_exists "${check_dir}/L.mean.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.mean.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.mean_all.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.mean_all.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/L.mean_all.native.func.gii"
				check_file_exists "${check_dir}/L.mean.native.func.gii"
				check_file_exists "${check_dir}/mask.nii.gz"
				check_file_exists "${check_dir}/mean.nii.gz"
				check_file_exists "${check_dir}/R.cov.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.cov.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.cov_all.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.cov_all.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.cov_all.native.func.gii"
				check_file_exists "${check_dir}/R.cov.native.func.gii"
				check_file_exists "${check_dir}/R.goodvoxels.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.goodvoxels.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.goodvoxels.native.func.gii"
				check_file_exists "${check_dir}/ribbon_only.nii.gz"
				check_file_exists "${check_dir}/R.mean.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.mean.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.mean_all.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.mean_all.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/R.mean_all.native.func.gii"
				check_file_exists "${check_dir}/R.mean.native.func.gii"
				check_file_exists "${check_dir}/SmoothNorm.nii.gz"
				check_file_exists "${check_dir}/std.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/MNINonLinear/Results/rfMRI_REST1_7T_PA
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "2. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/brainmask_fs.1.60.nii.gz"
				check_file_exists "${check_dir}/Movement_AbsoluteRMS_mean.txt"
				check_file_exists "${check_dir}/Movement_AbsoluteRMS.txt"
				check_file_exists "${check_dir}/Movement_Regressors_dt.txt"
				check_file_exists "${check_dir}/Movement_Regressors.txt"
				check_file_exists "${check_dir}/Movement_RelativeRMS_mean.txt"
				check_file_exists "${check_dir}/Movement_RelativeRMS.txt"


				if [ "${g_post_patch}" = "TRUE" ]; then
					check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas_1.6mm.dtseries.nii"
				else
					check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas.59k.dtseries.nii"
				fi

				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas.dtseries.nii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_AtlasSubcortical_s1.60.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_AtlasSubcortical_s2.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_dropouts.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Jacobian.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.atlasroi.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.atlasroi.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.native.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_PhaseOne_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_PhaseTwo_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.R.atlasroi.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.R.atlasroi.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.R.native.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s1.60.atlasroi.L.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s1.60.atlasroi.R.59k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s2.atlasroi.L.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_s2.atlasroi.R.32k_fs_LR.func.gii"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_SBRef.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_bias.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_reference.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/MNINonLinear/Results
				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/MNINonLinear
				check_dir=${check_dir}/xfms # rfMRI_REST1_7T_preproc/MNINonLinear/xfms
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "3. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}2standard.nii.gz"
				check_file_exists "${check_dir}/standard2${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/MNINonLinear
				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc
				check_dir=${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir} # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Distortion...based
				check_dir=${check_dir}/ComputeSpinEchoBiasField # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Distortion...based/ComputeSpinEchoBiasField
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "4. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/AllGreyMatter.nii.gz"
				check_file_exists "${check_dir}/CorticalGreyMatter.nii.gz"
				check_file_exists "${check_dir}/Dropouts_inv.nii.gz"
				check_file_exists "${check_dir}/Dropouts.nii.gz"
				check_file_exists "${check_dir}/GRE_bias.nii.gz"
				check_file_exists "${check_dir}/GRE_bias_raw.nii.gz"
				check_file_exists "${check_dir}/GRE_bias_raw_s5.nii.gz"
				check_file_exists "${check_dir}/GRE_bias_roi.nii.gz"
				check_file_exists "${check_dir}/GRE_bias_roi_s5.nii.gz"
				check_file_exists "${check_dir}/GRE_greyroi.nii.gz"
				check_file_exists "${check_dir}/GRE_greyroi_s5.nii.gz"
				check_file_exists "${check_dir}/GRE_grey_s5.nii.gz"
				check_file_exists "${check_dir}/GRE.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_dropouts.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_bias.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_reference.nii.gz"
				check_file_exists "${check_dir}/sebased_bias_dil.nii.gz"
				check_file_exists "${check_dir}/sebased_reference_dil.nii.gz"
				check_file_exists "${check_dir}/SE_BCdivGRE_brain.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain_bias.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain_thr.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain_thr_roi.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain_thr_roi_s5.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE_brain_thr_s5.nii.gz"
				check_file_exists "${check_dir}/SEdivGRE.nii.gz"
				check_file_exists "${check_dir}/SpinEchoMean_brain_BC.nii.gz"
				check_file_exists "${check_dir}/SpinEchoMean.nii.gz"
				check_file_exists "${check_dir}/SubcorticalGreyMatter.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Distortion...based
				check_dir=${check_dir}/FieldMap # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Distortion...based/FieldMap
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "4. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/acqparams.txt"
				check_file_exists "${check_dir}/BothPhases.nii.gz"
				check_file_exists "${check_dir}/BothPhases.topup_log"
				check_file_exists "${check_dir}/Coefficents_fieldcoef.nii.gz"
				check_file_exists "${check_dir}/Coefficents_movpar.txt"
				check_file_exists "${check_dir}/fullWarp_abs.nii.gz"
				check_file_exists "${check_dir}/Jacobian_01.nii.gz"
				check_file_exists "${check_dir}/Jacobian_02.nii.gz"
				check_file_exists "${check_dir}/Jacobian_03.nii.gz"
				check_file_exists "${check_dir}/Jacobian_04.nii.gz"
				check_file_exists "${check_dir}/Jacobian_05.nii.gz"
				check_file_exists "${check_dir}/Jacobian_06.nii.gz"
				check_file_exists "${check_dir}/Jacobian.nii.gz"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/Magnitude_brain_mask.nii.gz"
				check_file_exists "${check_dir}/Magnitude_brain.nii.gz"
				check_file_exists "${check_dir}/Magnitude.nii.gz"
				check_file_exists "${check_dir}/Magnitudes.nii.gz"
				check_file_exists "${check_dir}/Mask.nii.gz"
				# check_file_exists "${check_dir}/MotionMatrix_01.mat"
				# check_file_exists "${check_dir}/MotionMatrix_02.mat"
				# check_file_exists "${check_dir}/MotionMatrix_03.mat"
				# check_file_exists "${check_dir}/MotionMatrix_04.mat"
				# check_file_exists "${check_dir}/MotionMatrix_05.mat"
				# check_file_exists "${check_dir}/MotionMatrix_06.mat"
				check_file_exists "${check_dir}/PhaseOne_gdc_dc_jac.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_gdc.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_gdc_warp_jacobian.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_gdc_warp.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_mask_gdc.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_mask.nii.gz"
				check_file_exists "${check_dir}/PhaseOne.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_vol1.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_dc_jac.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_warp_jacobian.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_warp.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_mask_gdc.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_mask.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_vol1.nii.gz"
				check_file_exists "${check_dir}/qa.txt"
				check_file_exists "${check_dir}/SBRef2WarpField.mat"
				check_file_exists "${check_dir}/SBRef_dc_jac.nii.gz"
				check_file_exists "${check_dir}/SBRef_dc.nii.gz"
				check_file_exists "${check_dir}/SBRef.nii.gz"
				check_file_exists "${check_dir}/TopupField.nii.gz"
				check_file_exists "${check_dir}/trilinear.nii.gz"
				# check_file_exists "${check_dir}/WarpField_01.nii.gz"
				# check_file_exists "${check_dir}/WarpField_02.nii.gz"
				# check_file_exists "${check_dir}/WarpField_03.nii.gz"
				# check_file_exists "${check_dir}/WarpField_04.nii.gz"
				# check_file_exists "${check_dir}/WarpField_05.nii.gz"
				# check_file_exists "${check_dir}/WarpField_06.nii.gz"
				check_file_exists "${check_dir}/WarpField.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Distortion...based
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "5. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/EPItoT1w.dat"
				check_file_exists "${check_dir}/EPItoT1w.dat~"
				check_file_exists "${check_dir}/EPItoT1w.dat.log"
				check_file_exists "${check_dir}/EPItoT1w.dat.mincost"
				check_file_exists "${check_dir}/EPItoT1w.dat.param"
				check_file_exists "${check_dir}/EPItoT1w.dat.sum"
				check_file_exists "${check_dir}/fMRI2str.mat"
				check_file_exists "${check_dir}/fMRI2str.nii.gz"
				check_file_exists "${check_dir}/fMRI2str_refinement.mat"
				check_file_exists "${check_dir}/Jacobian2T1w.nii.gz"
				check_file_exists "${check_dir}/Jacobian.nii.gz"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/PhaseOne_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/PhaseOne_gdc_dc_unbias.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_dc.nii.gz"
				check_file_exists "${check_dir}/PhaseTwo_gdc_dc_unbias.nii.gz"
				check_file_exists "${check_dir}/qa.txt"
				check_file_exists "${check_dir}/SBRef_dc.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init_fast_wmedge.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init_fast_wmseg.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init_init.mat"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init.mat"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w_init_warp.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted2T1w.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_undistorted.nii.gz"
				check_file_exists "${check_dir}/T1w_acpc_dc_restore_brain.nii.gz"
				check_file_exists "${check_dir}/WarpField.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/GradientDistortionUnwarp # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/GradientDistortionUnwarp
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "6. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/fullWarp_abs.nii.gz"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/qa.txt"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_orig_vol1.nii.gz"
				check_file_exists "${check_dir}/trilinear.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/MotionCorrection # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/MotionCorrection
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "7. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_mc.ecclog"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_mc_mask.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_mc.par"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/MotionMatrices # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/MotionMatrices
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "8. check_dir: ${check_dir}"

				# check_file_exists "${check_dir}/MAT_0000"
				# check_file_exists "${check_dir}/MAT_0000_all_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0000_gdc_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0001"
				# check_file_exists "${check_dir}/MAT_0001_all_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0001_gdc_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0002"
				# ...
				# check_file_exists "${check_dir}/MAT_0897"
				# check_file_exists "${check_dir}/MAT_0897_all_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0897_gdc_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0898"
				# check_file_exists "${check_dir}/MAT_0898_all_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0898_gdc_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0899"
				# check_file_exists "${check_dir}/MAT_0899_all_warp.nii.gz"
				# check_file_exists "${check_dir}/MAT_0899_gdc_warp.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/OneStepResampling # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/OneStepResampling
				check_dir=${check_dir}/postvols # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/OneStepResampling/postvols
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "9. check_dir: ${check_dir}"

				# check_file_exists "${check_dir}/vol0_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0.nii.gz"
				# check_file_exists "${check_dir}/vol100_mask.nii.gz"
				# check_file_exists "${check_dir}/vol100.nii.gz"
				# check_file_exists "${check_dir}/vol101_mask.nii.gz"
				# check_file_exists "${check_dir}/vol101.nii.gz"
				# check_file_exists "${check_dir}/vol102_mask.nii.gz"
				# ...
				# check_file_exists "${check_dir}/vol98_mask.nii.gz"
				# check_file_exists "${check_dir}/vol98.nii.gz"
				# check_file_exists "${check_dir}/vol99_mask.nii.gz"
				# check_file_exists "${check_dir}/vol99.nii.gz"
				# check_file_exists "${check_dir}/vol9_mask.nii.gz"
				# check_file_exists "${check_dir}/vol9.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/OneStepResampling
				check_dir=${check_dir}/prevols # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/OneStepResampling/prevols
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "10. check_dir: ${check_dir}"

				# check_file_exists "${check_dir}/vol0000_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0000.nii.gz"
				# check_file_exists "${check_dir}/vol0001_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0001.nii.gz"
				# check_file_exists "${check_dir}/vol0002_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0002.nii.gz"
				# check_file_exists "${check_dir}/vol0003_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0003.nii.gz"
				# check_file_exists "${check_dir}/vol0004_mask.nii.gz"
				# ...
				# check_file_exists "${check_dir}/vol0898.nii.gz"
				# check_file_exists "${check_dir}/vol0899_mask.nii.gz"
				# check_file_exists "${check_dir}/vol0899.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/OneStepResampling
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "11. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/BiasField.1.60.nii.gz"
				check_file_exists "${check_dir}/brainmask_fs.1.60.nii.gz"
				check_file_exists "${check_dir}/gdc_dc_jacobian.nii.gz"
				check_file_exists "${check_dir}/gdc_dc_warp.nii.gz"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/qa.txt"
				check_file_exists "${check_dir}/Scout_gdc_MNI_warp.nii.gz"
				check_file_exists "${check_dir}/T1w_restore.1.60.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin_norm.wdir # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/rfMRI_REST1_7T_PA_nonlin_norm.wdir
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "12. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/qa.txt"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=${check_dir}/Scout_GradientDistortionUnwarp # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA/Scout_GradientDistortionUnwarp
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "13. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/fullWarp_abs.nii.gz"
				check_file_exists "${check_dir}/log.txt"
				check_file_exists "${check_dir}/qa.txt"
				check_file_exists "${check_dir}/Scout_orig_vol1.nii.gz"
				check_file_exists "${check_dir}/trilinear.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/rfMRI_REST1_7T_PA
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "14. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/BiasField.1.60.nii.gz"
				check_file_exists "${check_dir}/brainmask_fs.1.60.nii.gz"
				check_file_exists "${check_dir}/Jacobian_MNI.1.60.nii.gz"
				check_file_exists "${check_dir}/Jacobian.nii.gz"
				check_file_exists "${check_dir}/Movement_AbsoluteRMS_mean.txt"
				check_file_exists "${check_dir}/Movement_AbsoluteRMS.txt"
				check_file_exists "${check_dir}/Movement_Regressors_dt.txt"
				check_file_exists "${check_dir}/Movement_Regressors.txt"
				check_file_exists "${check_dir}/Movement_RelativeRMS_mean.txt"
				check_file_exists "${check_dir}/Movement_RelativeRMS.txt"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc_warp_jacobian.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc_warp.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_mc.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin_mask.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin_norm.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_orig.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_SBRef_nonlin.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_SBRef_nonlin_norm.nii.gz"
				check_file_exists "${check_dir}/Scout2T1w.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_mask.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_warp_jacobian.nii.gz"
				check_file_exists "${check_dir}/Scout_gdc_warp.nii.gz"
				check_file_exists "${check_dir}/Scout_orig.nii.gz"
				check_file_exists "${check_dir}/T1wMulEPI.nii.gz"
				check_file_exists "${check_dir}/T1w_restore.1.60.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc
				check_dir=${check_dir}/T1w # rfMRI_REST1_7T_preproc/T1w
				check_dir=${check_dir}/Results # rfMRI_REST1_7T_preproc/T1w/Results
				check_dir=${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir} # rfMRI_REST1_7T_preproc/T1w/Results/rfMRI_REST1_7T_PA
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "15. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_dropouts.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_bias.nii.gz"
				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_reference.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/T1w/Results
				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/T1w
				check_dir=${check_dir}/xfms # rfMRI_REST1_7T_preproc/T1w/xfms
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "16. check_dir: ${check_dir}"

				check_file_exists "${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}2str.nii.gz"

				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc/T1w
				check_dir=${check_dir}/.. # rfMRI_REST1_7T_preproc
				check_dir=$(readlink -m "${check_dir}")
				verbose_msg "17. check_dir: ${check_dir}"

			else
				# preprocessed resource for this scan does not exist, but should
				verbose_msg "Preprocessed resource does not exist but should"
				preproc_resource_exists="FALSE"
				preproc_resource_date="N/A"
				g_subject_complete="FALSE"
				g_all_files_exist="FALSE"
			fi

		else
			# Unprocessed resource dir for this scan does not exist
			verbose_msg "unproc does not exist"
			preproc_resource_exists="---"
			preproc_resource_date="---"
			g_all_files_exist="---"
		fi

		if [ "${g_report_level}" != "QUIET" ] ; then
			echo -e "${g_project}\t${g_subject}\t${short_preproc_resource_dir}\t${preproc_resource_exists}\t${preproc_resource_date}\t${g_all_files_exist}" >> ${tmp_file}
		fi

	done


	if [ "${g_report_level}" != "QUIET" ]; then
		if [ "${g_subject_complete}" = "TRUE" ]; then
			cat ${tmp_file} >> ${start_dir}/${g_project}.complete.status
		else
			cat ${tmp_file} >> ${start_dir}/${g_project}.incomplete.status
		fi

		cat ${tmp_file}
		rm -f ${tmp_file}
	fi
}

# fire up the main to get things started
main $@

if [ "${g_subject_complete}" = "TRUE" ]; then
	exit 0
else
	exit 1
fi
