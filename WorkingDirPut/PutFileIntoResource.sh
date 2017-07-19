#!/bin/bash
set -e
g_script_name=$(basename "${0}")

inform()
{
	msg=${1}
	echo "${g_script_name} | ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ] ; then
	echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS environment variable must be set"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_XNAT_SERVER}" ] ; then
	echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS_XNAT_SERVER environment variable must be set"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_PIPELINE_ENGINE}" ] ; then
	echo "${g_script_name}: ABORTING: XNAT_PBS_JOBS_PIPELINE_ENGINE environment variable must be set"
	exit 1
fi

# Example invocation
#
# ./PutFileIntoResource.sh \
#   --user=tbbrown \
#   --password=some_password \
#   --project=PipelineTest \
#   --subject=100307 \
#   --session=100307_3T \
#   --resource=Structural_preproc \
#   --file=/data/hcpdb/build_ssd/chpc/BUILD/PipelineTest/test/T1w/wmparc.nii.gz \   # Notice that the file is locally available on the server
#   --file-path-within-resource=T1w/wmparc.nii.gz  \                                # Should not start with a slash "/"
#   --force
#

get_options()
{
	local arguments=($@)

	# initialize global output variables
	unset g_user
	unset g_password
	unset g_protocol
	unset g_server
	unset g_project
	unset g_subject
	unset g_session
	unset g_resource
	unset g_reason
	unset g_file
	unset g_file_path_within_resource # should not start with a slash
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
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--session=*)
				g_session=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--resource=*)
				g_resource=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--reason=*)
				g_reason=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--file=*)
				g_file=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--force)
				g_force="TRUE"
				index=$(( index + 1 ))
				;;
			--file-path-within-resource=*)
				g_file_path_within_resource=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				inform ""
				inform "ERROR: unrecognized option: ${argument}"
				inform ""
				exit 1
				;;
		esac
	done

	local default_server="${XNAT_PBS_JOBS_XNAT_SERVER}"

	local error_count=0

	# check parameters
	if [ -z "${g_user}" ]; then
		inform "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		inform "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_password: *******"
	fi

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
	inform "g_protocol: ${g_protocol}"
	inform "g_server: ${g_server}"

	if [ -z "${g_project}" ]; then
		inform "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		inform "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		inform "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_session: ${g_session}"
	fi

	if [ -z "${g_resource}" ]; then
		inform "ERROR: resource (--resource=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_resource: ${g_resource}"
	fi

	if [ -z "${g_file}" ]; then
		inform "ERROR: file (--file=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_file: ${g_file}"
	fi

	if [ -z "${g_file_path_within_resource}" ]; then
		inform "ERROR: file path within resource (--file-path-within-resource=) required"
		error_count=$(( error_count + 1 ))
	else
		inform "g_file_path_within_resource: ${g_file_path_within_resource}"
	fi

	inform "g_reason: ${g_reason}"
	inform "g_force: ${g_force}"

	if [ ${error_count} -gt 0 ]; then
		exit 1
	fi
}

utils_IsYes() {
    answer="$1"
    # lowercase the answer                                                                                                                           
    answer=`echo $answer | tr '[:upper:]' '[:lower:]'`
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
	get_options $@

	# Set up to run Python
	source ${XNAT_PBS_JOBS}/ToolSetupScripts/epd-python_setup.sh

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g ConnectomeDB_E1234)
	get_session_id_cmd="python ${XNAT_PBS_JOBS_PIPELINE_ENGINE}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=${XNAT_PBS_JOBS_XNAT_SERVER} --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	#echo "get_session_id_cmd: ${get_session_id_cmd}"
	sessionID=`${get_session_id_cmd}`
	inform "XNAT session ID: ${sessionID}"

	resource_url=""
	resource_url+="${g_protocol}:"
	resource_url+="//${g_server}"
	resource_url+="/REST/projects/${g_project}"
	resource_url+="/subjects/${g_subject}"
	resource_url+="/experiments/${sessionID}"
	resource_url+="/resources/${g_resource}"
	resource_url+="/files"
	resource_url+="/${g_file_path_within_resource}"

	variable_values=""
	variable_values+="?overwrite=true"
	variable_values+="&replace=true"
	if [ ! -z "${g_reason}" ]; then
		variable_values+="&event_reason=${g_reason}"
	else
		variable_values+="&event_reason=Unspecified"
	fi
	variable_values+="&reference=${g_file}"

	resource_uri="${resource_url}${variable_values}"

	inform "resource_uri: ${resource_uri}"

	if [ ! -z "${g_force}" ]; then
		put_it="TRUE"
	elif utils_ShouldProceed ; then 
		put_it="TRUE"
	else
		unset put_it
	fi

	if [ ! -z "${put_it}" ]; then
		java_cmd=""
		java_cmd+="java -Xmx1024m -jar ${XNAT_PBS_JOBS_PIPELINE_ENGINE}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
		java_cmd+=" -u ${g_user}"
		java_cmd+=" -p ${g_password}"
		java_cmd+=" -m PUT"
		java_cmd+=" -r ${resource_uri}"
		#inform "java_cmd: ${java_cmd}"
		${java_cmd}
	else
		inform "Did not attempt to put to resource: ${resource_url}"
	fi
}

# Invoke the main function to get things started
main $@
