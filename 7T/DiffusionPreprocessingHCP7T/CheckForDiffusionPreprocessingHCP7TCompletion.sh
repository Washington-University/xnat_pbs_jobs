#!/bin/bash

DEBUG_MODE="FALSE"
#DEBUG_MODE="TRUE"

inform()
{
	local msg=${1}
	echo "CheckForDiffusionPreprocessingHCP7TCompletion.sh: ${msg}"
}

debug_msg()
{
	local msg=${1}
	if [ "${DEBUG_MODE}" = "TRUE" ] ; then
		msg="DEBUG: ${msg}"
		inform "${msg}"
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
            *)
                inform "Unrecognized Option: ${argument}"
                exit 1
                ;;
        esac
    done

    # check required parameters
	local error_count=0

    if [ -z ${g_project} ]; then
        inform "ERROR: --project=<project-name> is required."
        error_count=$(( error_count + 1 ))
    fi

    if [ -z ${g_subject} ]; then
        inform "ERROR: --subject=<subject-id> is required."
        error_count=$(( error_count + 1 ))
    fi

	if [ "${error_count}" -gt 0 ]; then
		exit 1
	fi
}

main()
{
	get_options $@

	tmp_file=${g_project}.${g_subject}.tmp
	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	subject_complete="TRUE"

	archive_dir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"
	resources_dir="${archive_dir}/RESOURCES"

ici ici ici 




		resting_state_scan="FALSE"
		if [[ ${scan} == *REST* ]]; then
			resting_state_scan="TRUE"
		fi
		debug_msg "resting_state_scan: ${resting_state_scan}"

		movie_scan="FALSE"
		if [[ ${scan} == *MOVIE* ]]; then
			movie_scan="TRUE"
		fi
		debug_msg "movie_scan: ${movie_scan}"

		retinotopy_scan="FALSE"
		if [[ ${scan} == *RET* ]]; then
			retinotopy_scan="TRUE"
		fi
		debug_msg "retinotopy_scan: ${retinotopy_scan}"

		if [ "${resting_state_scan}" = "TRUE" ] ; then
			prefix=${RESTING_PREFIX}
		else
			prefix=${TASK_PREFIX}
		fi

		unproc_resource_dir=${resources_dir}/${prefix}${scan}${UNPROC_SUFFIX}
		short_preproc_resource_dir=${prefix}${scan}${PREPROC_SUFFIX}
		preproc_resource_dir=${resources_dir}/${short_preproc_resource_dir}
		
		scan_without_pe_dir=${scan%_*}
		debug_msg "scan_without_pe_dir: ${scan_without_pe_dir}"
		pe_dir=${scan#*_}
		debug_msg "pe_dir: ${pe_dir}"

		# Does unprocessed resource for this scan exist?
		if [ -d "${unproc_resource_dir}" ] ; then
			debug_msg "Unprocessed resource directory for this scan does exist"

			# Does preprocessed resource for this scan exist?
			if [ -d "${preproc_resource_dir}" ] ; then
				debug_msg "Preprocessed resource exists, i've got some checking to do"
				preproc_resource_exists="TRUE"

				preproc_resource_date=$(stat -c %y ${preproc_resource_dir})
				preproc_resource_date=${preproc_resource_date%%\.*}

				files=""
				
				check_dir=${preproc_resource_dir}/MNINonLinear/Results/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}
				debug_msg "1. check_dir: ${check_dir}"
				
				files+=" ${check_dir}/brainmask_fs.1.60.nii.gz "
				files+=" ${check_dir}/Movement_AbsoluteRMS_mean.txt "
				files+=" ${check_dir}/Movement_AbsoluteRMS.txt "
				files+=" ${check_dir}/Movement_Regressors_dt.txt "
				files+=" ${check_dir}/Movement_Regressors.txt "
				files+=" ${check_dir}/Movement_RelativeRMS_mean.txt "
				files+=" ${check_dir}/Movement_RelativeRMS.txt "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas.59k.dtseries.nii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Atlas.dtseries.nii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_AtlasSubcortical_s1.60.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_AtlasSubcortical_s2.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_dropouts.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_Jacobian.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.atlasroi.32k_fs_LR.func.gii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.atlasroi.59k_fs_LR.func.gii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.L.native.func.gii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_PhaseOne_gdc_dc.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_PhaseTwo_gdc_dc.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.R.atlasroi.32k_fs_LR.func.gii "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.R.atlasroi.59k_fs_LR.func.gii "

				check_dir=${check_dir}/RibbonVolumeToSurfaceMapping
				debug_msg "2. check_dir: ${check_dir}"

				files+=" ${check_dir}/cov.nii.gz "
				files+=" ${check_dir}/cov_norm_modulate.nii.gz "
				files+=" ${check_dir}/cov_norm_modulate_ribbon.nii.gz "
				files+=" ${check_dir}/cov_ribbon.nii.gz "
				files+=" ${check_dir}/cov_ribbon_norm.nii.gz "
				files+=" ${check_dir}/cov_ribbon_norm_s5.nii.gz "
				files+=" ${check_dir}/goodvoxels.nii.gz "
				files+=" ${check_dir}/L.cov.32k_fs_LR.func.gii "
				files+=" ${check_dir}/L.cov.59k_fs_LR.func.gii "
				files+=" ${check_dir}/L.cov_all.32k_fs_LR.func.gii "
				files+=" ${check_dir}/L.cov_all.59k_fs_LR.func.gii "
				files+=" ${check_dir}/L.cov_all.native.func.gii "
				files+=" ${check_dir}/L.cov.native.func.gii "
				files+=" ${check_dir}/L.goodvoxels.32k_fs_LR.func.gii "
				files+=" ${check_dir}/L.goodvoxels.59k_fs_LR.func.gii "
				files+=" ${check_dir}/L.goodvoxels.native.func.gii "
				files+=" ${check_dir}/L.mean.32k_fs_LR.func.gii "
				files+=" ${check_dir}/L.mean.59k_fs_LR.func.gii "
				files+=" ${check_dir}/L.mean_all.32k_fs_LR.func.gii "
				files+=" ${check_dir}/L.mean_all.59k_fs_LR.func.gii "
				files+=" ${check_dir}/L.mean_all.native.func.gii "
				files+=" ${check_dir}/SmoothNorm.nii.gz "

				check_dir=${preproc_resource_dir}/MNINonLinear/xfms
				debug_msg "3. check_dir: ${check_dir}"

				files+=" ${check_dir}/standard2${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}2standard.nii.gz"

				check_dir=${preproc_resource_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}
				debug_msg "4. check_dir: ${check_dir}"

				files+=" ${check_dir}/BiasField.1.60.nii.gz "
				files+=" ${check_dir}/brainmask_fs.1.60.nii.gz "
				files+=" ${check_dir}/DistortionCorrectionAndEPIToT1wReg_FLIRTBBRAndFreeSurferBBRbased "
				files+=" ${check_dir}/GradientDistortionUnwarp "
				files+=" ${check_dir}/Jacobian_MNI.1.60.nii.gz "
				files+=" ${check_dir}/Jacobian.nii.gz "
				files+=" ${check_dir}/MotionCorrection "
				files+=" ${check_dir}/MotionMatrices "
				files+=" ${check_dir}/Movement_AbsoluteRMS_mean.txt "
				files+=" ${check_dir}/Movement_AbsoluteRMS.txt "
				files+=" ${check_dir}/Movement_Regressors_dt.txt "
				files+=" ${check_dir}/Movement_Regressors.txt "
				files+=" ${check_dir}/Movement_RelativeRMS_mean.txt "
				files+=" ${check_dir}/Movement_RelativeRMS.txt "
				files+=" ${check_dir}/OneStepResampling "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc_warp_jacobian.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_gdc_warp.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_mc.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin_mask.nii.gz "
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_nonlin.nii.gz "

				check_dir=${preproc_resource_dir}/T1w/Results/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}
				debug_msg "5. check_dir: ${check_dir}"

				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_dropouts.nii.gz"
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_bias.nii.gz"
				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}_sebased_reference.nii.gz"
				
				check_dir=${preproc_resource_dir}/T1w/xfms

				files+=" ${check_dir}/${prefix}${scan_without_pe_dir}${TESLA_SPEC}_${pe_dir}2str.nii.gz"

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

			else
				# preprocessed resource for this scan does not exist, but should
				debug_msg "Preprocessed resource does not exist but should"
				preproc_resource_exists="FALSE"
				preproc_resource_date="N/A"
				subject_complete="FALSE"
				all_files_exist="FALSE"
			fi

		else
			# Unprocessed resource dir for this scan does not exist
			debug_msg "unproc does not exist"
			preproc_resource_exists="---"
			preproc_resource_date="---"
			all_files_exist="---"
		fi

		#echo -e "${g_subject}\t\t${g_project}\t${short_preproc_resource_dir}\t${preproc_resource_exists}\t${preproc_resource_date}\t${all_files_exist}" >> ${tmp_file}
		echo -e "${g_project}\t${g_subject}\t${short_preproc_resource_dir}\t${preproc_resource_exists}\t${preproc_resource_date}\t${all_files_exist}" >> ${tmp_file}


	done

	if [ "${subject_complete}" = "TRUE" ]; then
		cat ${tmp_file} >> ${g_project}.complete.txt
	else
		cat ${tmp_file} >> ${g_project}.incomplete.txt
	fi

	cat ${tmp_file}
	rm -f ${tmp_file}
}

# fire up the main to get things started
main $@
