#!/bin/bash

PATCH_NAME_SUFFIX="_S500_to_S900_extension"

get_options()
{
    local arguments=($@)

    unset g_script_name
    unset g_packages_root
    unset g_archive_root
    unset g_tmp_dir
    unset g_subject
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
            --packages-root=*)
                g_packages_root=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
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

    if [ -z "${g_packages_root}" ]; then
        echo "ERROR: --packages-root= required"
        error_count=$(( error_count + 1 ))
    else
        echo "packages root: ${g_packages_root}"
    fi

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

main() 
{
    # get command line options
    get_options $@

    # determine and create the temporary directory for this script's work
    short_script_name=${g_script_name%.sh}
    msecs_since_epoch=`date +%s%3N`
    script_tmp_dir="${g_tmp_dir}/${g_subject}.${short_script_name}.${msecs_since_epoch}"
    mkdir -p ${script_tmp_dir}

    # determine subject resources directory
    subject_resources_dir="${g_archive_root}/${g_subject}_3T/RESOURCES"

    # figure out what tasks there are that have analysis resources
    potential_tasks="EMOTION GAMBLING LANGUAGE MOTOR RELATIONAL SOCIAL WM"
    tasks=""
    for task in ${potential_tasks} ; do
        if [ -e "${subject_resources_dir}/tfMRI_${task}" ]; then
            tasks+=" ${task}"
        fi
    done

    for task in ${tasks} ; do 

        for smoothing_level in 2 4 ; do

            # start with a clean temporary directory for this subject
            rm -rf ${script_tmp_dir}/${g_subject}

            echo ""
            echo "--------------------------------------------------"
            echo " Updating Task Analysis Package for: ${task} at smoothing level: ${smoothing_level}"
            echo "--------------------------------------------------"
            echo ""
            
            echo ""
            echo "--------------------------------------------------"
            echo " Get files from PostMsmAllTaskAnalysis"
            echo "--------------------------------------------------"
            echo ""

            post_msm_task_analysis_resource="${subject_resources_dir}/tfMRI_${task}_PostMsmAllTaskAnalysis"
            echo "post_msm_task_analysis_resource: ${post_msm_task_analysis_resource}"
            
            to_dir=${script_tmp_dir}/${g_subject}/MNINonLinear/Results/tfMRI_${task}/tfMRI_${task}_hp200_s${smoothing_level}_level2_MSMAll.feat
            echo "to_dir: ${to_dir}"
            from_dir=${post_msm_task_analysis_resource}/MNINonLinear/Results/tfMRI_${task}/tfMRI_${task}_hp200_s${smoothing_level}_level2_MSMAll.feat
            echo "from_dir: ${from_dir}"

            mkdir -p ${to_dir}
            #files=`find ${from_dir} -maxdepth 1 -name "${g_subject}_tfMRI_${task}_level2_beta_hp200_s${smoothing_level}_MSMAll.dscalar.nii"`

            files=" "
            files+=`find ${from_dir} -maxdepth 1 -name "${g_subject}_tfMRI_${task}_level2_hp200_s${smoothing_level}_MSMAll.dscalar.nii"`

            for extension in txt con png ppm fsf grp mat ; do
                files+=" "
                files+=`find ${from_dir} -maxdepth 1 -name "*.${extension}"`
            done

            for file in ${files} ; do
                cp --verbose --archive ${file} ${to_dir}
            done

            mkdir -p ${to_dir}/GrayordinatesStats
            from_dirs=`find ${from_dir}/GrayordinatesStats -type d -name "cope*.feat"`
            for feat_dir in ${from_dirs} ; do
                echo "feat_dir: ${feat_dir}"
                cp --verbose --archive --recursive ${feat_dir} ${to_dir}/GrayordinatesStats
            done

            echo ""
            echo "--------------------------------------------------"
            echo " Update release notes for patch package"
            echo "--------------------------------------------------"
            echo ""

            # figure out path to release notes file
            release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/tfMRI_${task}_analysis_s${smoothing_level}.txt

            # create new release notes file
            mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
            touch ${release_notes_file}
            echo "${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}.zip" >> ${release_notes_file}
            echo "" >> ${release_notes_file}
            echo `date` >> ${release_notes_file}
            echo "" >> ${release_notes_file}
            cat ${g_release_notes_template_file} >> ${release_notes_file}
            echo "" >> ${release_notes_file}

            echo ""
            echo "--------------------------------------------------"
            echo " Create patch package"
            echo "--------------------------------------------------"
            echo ""
            new_package_dir="${g_output_dir}/${g_subject}/analysis_s${smoothing_level}"
            new_package_name="${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}${PATCH_NAME_SUFFIX}.zip"
            new_package_path="${new_package_dir}/${new_package_name}"

            # start with a clean slate
            rm -f ${new_package_path}
            rm -f ${new_package_path}.md5
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
                echo "--------------------------------------------------"
                echo " Create MD5 Checksum"
                echo "--------------------------------------------------"
                echo ""
                
                pushd ${new_package_dir}
                md5sum ${new_package_name} > ${new_package_name}.md5
                chmod u=rw,g=rw,o=r ${new_package_name}.md5
                popd
            fi
            
            popd

            echo ""
            echo "--------------------------------------------------"
            echo " Get contents of original task analysis package"
            echo "--------------------------------------------------"
            echo ""
            
            # figure out where to find the original task analysis package
            original_package=${g_packages_root}/${g_subject}/analysis_s${smoothing_level}/${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}.zip

            if [ ! -e ${original_package} ]; then
                echo "ERROR: original package ${original_package} does not exist"
                return
            fi

            # unzip the contents of the original task analysis package into the temporary directory 
            # with the already existing files that we got from the MSM-All related 
            # resources
            cd ${script_tmp_dir}
            unzip -n ${original_package}

            echo ""
            echo "--------------------------------------------------"
            echo " Create new package"
            echo "--------------------------------------------------"
            echo ""
            new_package_dir="${g_output_dir}/${g_subject}/analysis_s${smoothing_level}"
            new_package_name="${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}.zip"
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
                echo "--------------------------------------------------"
                echo " Create MD5 Checksum"
                echo "--------------------------------------------------"
                echo ""
                
                pushd ${new_package_dir}
                md5sum ${new_package_name} > ${new_package_name}.md5
                chmod u=rw,g=rw,o=r ${new_package_name}.md5
                popd
            fi
        
            popd

        done # smoothing_level

    done # task


    # remove temporary directory
    echo ""
    echo "--------------------------------------------------"
    echo " Remove temporary directory"
    echo "--------------------------------------------------"
    echo ""
    
    rm -rf ${script_tmp_dir}
    
}

#
# Invoke the main function to get things started
#
main $@

