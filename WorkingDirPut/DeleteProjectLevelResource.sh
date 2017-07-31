#!/bin/bash
set -e
g_script_name=$(basename ${0})

# home directory for XNAT pipeline engine installation
if [ -z "${XNAT_PBS_JOBS_PIPELINE_ENGINE}" ] ; then
    echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS_PIPELINE_ENGINE environment variable must be set"
    exit 1
fi

show_msg()
{
    local msg="${1}"
    echo "${g_script_name}: ${msg}"
}

get_options()
{
    local arguments=($@)

    # initialize global output variables
    unset g_user
    unset g_password
    unset g_protocol
    unset g_server
    unset g_project
    unset g_resource
    unset g_force    # No prompt

    # parse arguments
    local num_args=${#arguments[@]}
    local argument
    local index=0

    while [ ${index} -lt ${num_args} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --user=*)
                g_user=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --password=*)
                g_password=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --protocol=*)
                g_protocol=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --server=*)
                g_server=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --project=*)
                g_project=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --resource=*)
                g_resource=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --force)
                g_force="TRUE"
                index=$(( index + 1 ))
                ;;
            *)
                show_msg "ERROR: unrecognized option: ${argument}"
                show_msg ""
                exit 1
                ;;
        esac
    done

    local default_server="${XNAT_PBS_JOBS_XNAT_SERVER}"

    local error_count=0

    # check parameters
    if [ -z "${g_user}" ]; then
        show_msg "ERROR: user (--user=) required"
        error_count=$(( error_count + 1 ))
    else
        show_msg "g_user: ${g_user}"
    fi

    if [ -z "${g_password}" ]; then
        stty -echo
        printf "Password: "
        read g_password
        echo ""
        stty echo
    fi
    show_msg "g_password: Now you know I'm not going to show you that."

    if [ -z "${g_server}" ]; then
        g_server="${default_server}"
    fi

    if [ -z "${g_protocol}" ]; then
        if [ "${g_server}" = "${default_server}" ]; then
            g_protocol="https"
        else
            g_protocol="http"
        fi
    fi
    show_msg "g_protocol: ${g_protocol}"
    show_msg "g_server: ${g_server}"

    if [ -z "${g_project}" ]; then
        show_msg "ERROR: project (--project=) required"
        error_count=$(( error_count + 1 ))
    else
        show_msg "g_project: ${g_project}"
    fi

    if [ -z "${g_resource}" ]; then
        show_msg "ERROR: resource (--resource=) required"
        error_count=$(( error_count + 1 ))
    else
        show_msg "g_resource: ${g_resource}"
    fi

    show_msg "g_force: ${g_force}"

    if [ ${error_count} -gt 0 ]; then
        exit 1
    fi
}

utils_IsYes() {
    answer="$1"
    # lowercase the answer
    answer=$(echo $answer | tr '[:upper:]' '[:lower:]')
    if [ "$answer" = "y" ] || [ "$answer" = "yes" ]
    then
        return 0 # The answer is yes: True
    else
        return 1 # The answer is yes: False
    fi
}

utils_ShouldProceed() {
    echo -ne "Proceed? [n]: "
    read proceed

    if utils_IsYes $proceed
    then
        return 0 # Should proceed
    else
        return 1 # Should not proceed
    fi
}

main()
{
    get_options "$@"

    resource_url=""
    resource_url+="${g_protocol}:"
    resource_url+="//${g_server}"
    resource_url+="/REST/projects/${g_project}"
    resource_url+="/resources/${g_resource}"

    variable_values="?removeFiles=true"
    resource_uri="${resource_url}${variable_values}"

    show_msg "resource_uri: ${resource_uri}"

    if [ ! -z "${g_force}" ]; then
        delete_it="TRUE"
    elif utils_ShouldProceed ; then
        delete_it="TRUE"
    else
        unset delete_it
    fi

    if [ ! -z "${delete_it}" ]; then
        java_cmd=""
        java_cmd+="java -Xmx1024m -jar ${XNAT_PBS_JOBS_PIPELINE_ENGINE}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
        java_cmd+=" -u ${g_user}"
        java_cmd+=" -p ${g_password}"
        java_cmd+=" -m DELETE"
        java_cmd+=" -r ${resource_uri}"
        #show_msg "java_cmd: ${java_cmd}"
        ${java_cmd}
    else
        show_msg "Did not attempt to delete resource: ${resource_url}"
    fi
}

# Invoke the main function to get things started
main "$@"
