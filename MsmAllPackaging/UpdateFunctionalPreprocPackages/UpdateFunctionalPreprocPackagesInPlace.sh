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
    unset g_create_checksum
    unset g_patch_only

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
            --create-checksum)
                g_create_checksum="YES"
                index=$(( index + 1 ))
                ;;
            --patch-only)
                g_patch_only="TRUE"
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

    if [ -z "${g_create_checksum}" ]; then
        g_create_checksum="NO"
    fi
    echo "create checksum: ${g_create_checksum}"

    if [ -z "${g_patch_only}" ]; then
        g_patch_only="FALSE"
    fi
    echo "patch_only: ${g_patch_only}"

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

    # figure out what resting state scans there are
    resting_state_scan_resources=`find ${subject_resources_dir} -maxdepth 1 -name "rfMRI*_preproc"`
    resting_state_scans=""
    for resting_state_scan_resource in ${resting_state_scan_resources} ; do
        resting_state_scan=${resting_state_scan_resource##*/}
        resting_state_scan=${resting_state_scan%_preproc}
        resting_state_scan=${resting_state_scan%_LR}
        resting_state_scan=${resting_state_scan%_RL}
        resting_state_scans=${resting_state_scans//${resting_state_scan}/}
        resting_state_scans+=" ${resting_state_scan}"
    done

    # figure out what task scans there are
    task_scan_resources=`find ${subject_resources_dir} -maxdepth 1 -name "tfMRI*_preproc"`
    task_scans=""
    for task_scan_resource in ${task_scan_resources} ; do
        task_scan=${task_scan_resource##*/}
        task_scan=${task_scan%_preproc}
        task_scan=${task_scan%_LR}
        task_scan=${task_scan%_RL}
        task_scans=${task_scans//${task_scan}/}
        task_scans+=" ${task_scan}"
    done

    #echo "resting_state_scans: ${resting_state_scans}"
    #echo "task_scans: ${task_scans}"

    for scan in ${resting_state_scans} ${task_scans} ; do

        # start with a clean temporary directory for this subject
        rm -rf ${script_tmp_dir}/${g_subject}

        echo ""
        echo "--------------------------------------------------"
        echo " Updating Functional Preproc Package for: ${scan}"
        echo "--------------------------------------------------"
        echo ""

        echo ""
        echo "--------------------------------------------------"
        echo " Get files from DeDrift and Resample"
        echo "--------------------------------------------------"
        echo ""
        
        dedrift_resource="${subject_resources_dir}/MSMAllDeDrift"

        for phase in LR RL ; do
            mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
            files=`find ${dedrift_resource}/MNINonLinear/Results/${scan}_${phase} -maxdepth 1 -name "*_Atlas_MSMAll.dtseries.nii"`
            for file in ${files} ; do
                cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
            done

            func_preproc_resource="${subject_resources_dir}/${scan}_${phase}_preproc"
            #echo "func_preproc_resource: ${func_preproc_resource}"
            for hemi in L R ; do
                #echo "hemi: ${hemi}"
                files=`find ${func_preproc_resource}/MNINonLinear/Results/${scan}_${phase} -maxdepth 1 -name "${scan}_${phase}.${hemi}.native.func.gii"`
                for file in ${files} ; do
                    #echo "file: ${file}"
                    cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
                done
            done

            generate_spin_echo_resource="${subject_resources_dir}/GenerateSpinEchoBiasFieldPrereqs"

            mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
            files=`find ${generate_spin_echo_resource}/MNINonLinear/Results/${scan}_${phase} -maxdepth 1 -name "*.nii.gz"`
            for file in ${files} ; do
                #echo "file: ${file}"
                cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
            done

            mkdir -p ${script_tmp_dir}/${g_subject}/T1w/Results/${scan}_${phase}
            files=`find ${generate_spin_echo_resource}/T1w/Results/${scan}_${phase} -maxdepth 1 -name "*.nii.gz"`
            for file in ${files} ; do
                #echo "file: ${file}"
                cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/T1w/Results/${scan}_${phase}
            done

        done

        echo ""
        echo "--------------------------------------------------"
        echo " Get physio files"
        echo "--------------------------------------------------"
        echo ""

        for phase in LR RL ; do
            preproc_resource="${subject_resources_dir}/${scan}_${phase}_preproc"
            physio_file="${preproc_resource}/MNINonLinear/Results/${scan}_${phase}/${scan}_${phase}_Physio_log.txt"

            mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
            cp --verbose --archive ${physio_file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Results/${scan}_${phase}
        done

        echo ""
        echo "--------------------------------------------------"
        echo " Update release notes for patch package"
        echo "--------------------------------------------------"
        echo ""

        # figure out path to release notes file
        release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/${scan}_preproc.txt

        # create new release notes file
        mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
        touch ${release_notes_file}
        echo "${g_subject}_3T_${scan}_preproc.zip" >> ${release_notes_file}
        echo "" >> ${release_notes_file}
        echo `date` >> ${release_notes_file}
        echo "" >> ${release_notes_file}
        cat ${g_release_notes_template_file} >> ${release_notes_file}
        echo "" >> ${release_notes_file}

        echo ""
        echo "--------------------------------------------------"
        echo " Update patch package"
        echo "--------------------------------------------------"
        echo ""
        package_dir="${g_packages_root}/${g_subject}/preproc"
        package_name="${g_subject}_3T_${scan}_preproc${PATCH_NAME_SUFFIX}.zip"
        package_path="${package_dir}/${package_name}"

        # remove old checksum file
        rm -f ${package_path}.md5

        # update the zip file
        pushd ${script_tmp_dir}
        zip_cmd="zip --verbose --update --recurse-paths ${package_path} ${g_subject}"
        echo "zip_cmd: ${zip_cmd}"
        ${zip_cmd}

        # create the checksum file if requested
        if [ "${g_create_checksum}" = "YES" ]; then

            echo ""
            echo "--------------------------------------------------"
            echo " Create MD5 Checksum"
            echo "--------------------------------------------------"
            echo ""
            
            pushd ${package_dir}
            md5sum ${package_name} > ${package_name}.md5
            chmod 777 ${package_name}.md5
            popd
        fi
        
        popd

        if [ "${g_patch_only}" == "FALSE" ] ; then

            echo ""
            echo "--------------------------------------------------"
            echo " Update package"
            echo "--------------------------------------------------"
            echo ""
            package_dir="${g_packages_root}/${g_subject}/preproc"
            package_name="${g_subject}_3T_${scan}_preproc.zip"
            package_path="${package_dir}/${package_name}"
        
            # remove old checksum file
            rm -rf ${package_path}.md5
            
            # update the zip file
            pushd ${script_tmp_dir}
            zip_cmd="zip --verbose --update --recurse-paths ${package_path} ${g_subject}"
            echo "zip_cmd: ${zip_cmd}"
            ${zip_cmd}

            # create the checksum file if requested
            if [ "${g_create_checksum}" = "YES" ]; then

                echo ""
                echo "--------------------------------------------------"
                echo " Create MD5 Checksum"
                echo "--------------------------------------------------"
                echo ""
                
                pushd ${package_dir}
                md5sum ${package_name} > ${package_name}.md5
                chmod 777 ${package_name}.md5
                popd
            fi
            
            popd

        fi

    done

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

