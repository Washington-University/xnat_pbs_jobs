#!/bin/bash

DEBUG_MODE="FALSE"
#DEBUG_MODE="TRUE"

inform()
{
	local msg=${1}
	echo "CheckForAddResolutionHCP7TCompletion.sh: ${msg}"
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
TESLA_SPEC="_3T"

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

main() 
{
	get_options $@

	tmp_file="${g_project}.${g_subject}.tmp"
	if [ -e "${tmp_file}" ]; then
		rm -f ${tmp_file}
	fi

	subject_complete="TRUE"

	presentDir=`pwd`
	archiveDir="${ARCHIVE_ROOT}/${g_project}/${ARCHIVE_PROJ_SUBDIR}/${g_subject}${TESLA_SPEC}"

	# does Structural_preproc_supplemental exist

	struct_preproc_supplemental_dir=${archiveDir}/RESOURCES/Structural_preproc_supplemental

	if [ -d "${struct_preproc_supplemental_dir}" ] ; then
		resource_exists="TRUE"
		resource_date=$(stat -c %y ${struct_preproc_supplemental_dir})
		resource_date=${resource_date%%\.*}
	else
		resource_exists="FALSE"
		resource_date="N/A"
		sobject_complete="FALSE"
	fi

	files=""

	check_dir="${struct_preproc_supplemental_dir}/MNINonLinear"
	files+=" ${check_dir}/T1w_restore.1.60.nii.gz"
	files+=" ${check_dir}/T2w_restore.1.60.nii.gz"

	check_dir="${struct_preproc_supplemental_dir}/MNINonLinear/fsaverage_LR59k"


	files+=" ${check_dir}/${g_subject}.59k_fs_LR.wb.spec"
	files+=" ${check_dir}/${g_subject}.aparc.59k_fs_LR.dlabel.nii"
	files+=" ${check_dir}/${g_subject}.aparc.a2009s.59k_fs_LR.dlabel.nii"
	files+=" ${check_dir}/${g_subject}.ArealDistortion_FS.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.ArealDistortion_MSMSulc.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.BA.59k_fs_LR.dlabel.nii"
	files+=" ${check_dir}/${g_subject}.corrThickness.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.curvature.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.L.aparc.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.L.aparc.a2009s.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.L.ArealDistortion_FS.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.atlasroi.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.BA.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.L.corrThickness.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.curvature.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.flat.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.midthickness.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.MyelinMap.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.MyelinMap_BC.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.pial.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.SmoothedMyelinMap.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.SmoothedMyelinMap_BC.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.L.sphere.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.sulc.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.thickness.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.white.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.MyelinMap.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.MyelinMap_BC.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.R.aparc.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.R.aparc.a2009s.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.R.ArealDistortion_FS.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.ArealDistortion_MSMSulc.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.atlasroi.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.BA.59k_fs_LR.label.gii"
	files+=" ${check_dir}/${g_subject}.R.corrThickness.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.curvature.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.flat.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.midthickness.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.MyelinMap.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.MyelinMap_BC.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.pial.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.SmoothedMyelinMap.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.SmoothedMyelinMap_BC.59k_fs_LR.func.gii"
	files+=" ${check_dir}/${g_subject}.R.sphere.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.sulc.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.thickness.59k_fs_LR.shape.gii"
	files+=" ${check_dir}/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.white.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.SmoothedMyelinMap.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.SmoothedMyelinMap_BC.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.sulc.59k_fs_LR.dscalar.nii"
	files+=" ${check_dir}/${g_subject}.thickness.59k_fs_LR.dscalar.nii"

	check_dir="${struct_preproc_supplemental_dir}/MNINonLinear/ROIs"
	files+=" ${check_dir}/Atlas_ROIs.1.60.nii.gz"
	files+=" ${check_dir}/Atlas_wmparc.1.60.nii.gz"
	files+=" ${check_dir}/ROIs.1.60.nii.gz"
	files+=" ${check_dir}/wmparc.1.60.nii.gz"

	check_dir="${struct_preproc_supplemental_dir}/T1w/fsaverage_LR59k"
	files+=" ${check_dir}/${g_subject}.59k_fs_LR.wb.spec"
	files+=" ${check_dir}/${g_subject}.L.inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.midthickness.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.pial.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.very_inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.L.white.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.midthickness.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.pial.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.very_inflated.59k_fs_LR.surf.gii"
	files+=" ${check_dir}/${g_subject}.R.white.59k_fs_LR.surf.gii"
	
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

	echo -e "${g_subject}\t\t${g_project}\t\tStructural_preproc_supplemental\t${resource_exists}\t${resource_date}\t${all_files_exist}" >> ${tmp_file}

	if [ "${subject_complete}" = "TRUE" ]; then
		cat ${tmp_file} >> ${g_project}.complete.status
	else
		cat ${tmp_file} >> ${g_project}.incomplete.status
	fi
	cat ${tmp_file}
	rm -f ${tmp_file}
}

main $@
