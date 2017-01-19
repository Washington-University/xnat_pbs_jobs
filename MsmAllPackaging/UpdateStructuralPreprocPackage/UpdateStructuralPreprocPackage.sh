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

    # start with a clean temporary directory for this subject
    rm -rf ${script_tmp_dir}/${g_subject}

    echo ""
    echo "--------------------------------------------------"
    echo " Get files from MSM-All Initial Registration"
    echo "--------------------------------------------------"
    echo ""

    initial_registration_resource="${subject_resources_dir}/MSMAllReg"

    mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/Native
    files=`find ${initial_registration_resource}/MNINonLinear/Native/*.SphericalDistortion*`
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Native
    done

    echo ""
    echo "--------------------------------------------------"
    echo " Get files from DeDrift and Resample"
    echo "--------------------------------------------------"
    echo ""

    dedrift_resource="${subject_resources_dir}/MSMAllDeDrift"

    mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear
    files=`find ${dedrift_resource}/MNINonLinear -type f -maxdepth 1`
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear
    done

    mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/fsaverage_LR32k
    files=`find ${dedrift_resource}/MNINonLinear/fsaverage_LR32k -type f -maxdepth 1` 
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/fsaverage_LR32k
    done
   
    mkdir -p ${script_tmp_dir}/${g_subject}/MNINonLinear/Native
    files=`find ${dedrift_resource}/MNINonLinear/Native -type f -maxdepth 1` 
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/MNINonLinear/Native
    done

    mkdir -p ${script_tmp_dir}/${g_subject}/T1w/fsaverage_LR32k
    files=`find ${dedrift_resource}/T1w/fsaverage_LR32k -type f -maxdepth 1` 
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/T1w/fsaverage_LR32k
    done

    mkdir -p ${script_tmp_dir}/${g_subject}/T1w/Native
    files=`find ${dedrift_resource}/T1w/Native -type f -maxdepth 1` 
    for file in ${files} ; do
        cp --verbose --archive ${file} ${script_tmp_dir}/${g_subject}/T1w/Native
    done

    echo ""
    echo "--------------------------------------------------"
    echo " Update release notes for patch package"
    echo "--------------------------------------------------"
    echo ""

    # figure out path to release notes file
    release_notes_file=${script_tmp_dir}/${g_subject}/release-notes/Structural_preproc.txt

    # create new release notes file
    mkdir -p ${script_tmp_dir}/${g_subject}/release-notes
    touch ${release_notes_file}
    echo "${g_subject}_3T_Structural_preproc.zip" >> ${release_notes_file}
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
    new_package_dir="${g_output_dir}/${g_subject}/preproc"
    new_package_name="${g_subject}_3T_Structural_preproc${PATCH_NAME_SUFFIX}.zip"
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
    echo " Get contents of original structural preproc package"
    echo "--------------------------------------------------"
    echo ""

    # figure out where to find the original structural preproc package
    original_struct_preproc_package=${g_packages_root}/${g_subject}/preproc/${g_subject}_3T_Structural_preproc.zip

    if [ ! -e ${original_struct_preproc_package} ]; then
        echo "ERROR: original package ${original_struct_preproc_package} not exist"
        return
    fi

    # unzip the contents of the original fix package into the temporary directory 
    # with the already existing files that we got from the MSM-All related 
    # resources
    cd ${script_tmp_dir}
    unzip -n ${original_struct_preproc_package}

    echo ""
    echo "--------------------------------------------------"
    echo " Create new package"
    echo "--------------------------------------------------"
    echo ""
    new_package_dir="${g_output_dir}/${g_subject}/preproc"
    new_package_name="${g_subject}_3T_Structural_preproc.zip"
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

    # remove temporary directory
    echo ""
    echo "--------------------------------------------------"
    echo " Remove subject's temporary directory"
    echo "--------------------------------------------------"
    echo ""

    rm -rf ${script_tmp_dir}
}

#
# Invoke the main function to get things started
#
main $@

