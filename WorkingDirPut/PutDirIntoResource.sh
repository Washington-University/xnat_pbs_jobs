#!/bin/bash

set -e

# home directory for scripts to be sourced to setup the environment
SCRIPTS_HOME=/home/HCPpipeline/SCRIPTS

# home directory for XNAT pipeline engine installation
XNAT_PIPELINE_HOME=/home/HCPpipeline/pipeline

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
	unset g_dir
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
			--dir=*)
				g_dir=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--force)
				g_force="TRUE"
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: unrecognized option: ${argument}"
				echo ""
				exit 1
				;;
		esac
	done

	local default_server="${XNAT_PBS_JOBS_XNAT_SERVER}"

	local error_count=0

	# check parameters
	if [ -z "${g_user}" ]; then
		echo "ERROR: user (--user=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_user: ${g_user}"
	fi

	if [ -z "${g_password}" ]; then
		echo "ERROR: password (--password=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_password: *******"
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
	echo "g_protocol: ${g_protocol}"
	echo "g_server: ${g_server}"

	if [ -z "${g_project}" ]; then
		echo "ERROR: project (--project=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_project: ${g_project}"
	fi

	if [ -z "${g_subject}" ]; then
		echo "ERROR: subject (--subject=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_subject: ${g_subject}"
	fi

	if [ -z "${g_session}" ]; then
		echo "ERROR: session (--session=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_session: ${g_session}"
	fi

	if [ -z "${g_resource}" ]; then
		echo "ERROR: resource (--resource=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_resource: ${g_resource}"
	fi

	if [ -z "${g_dir}" ]; then
		echo "ERROR: dir (--dir=) required"
		error_count=$(( error_count + 1 ))
	else
		echo "g_dir: ${g_dir}"
	fi

	echo "g_reason: ${g_reason}"
	echo "g_force: ${g_force}"

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
	source ${SCRIPTS_HOME}/epd-python_setup.sh

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g ConnectomeDB_E1234)
	get_session_id_cmd="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py --server=${XNAT_PBS_JOBS_XNAT_SERVER} --username=${g_user} --password=${g_password} --project=${g_project} --subject=${g_subject} --session=${g_session}"
	#echo "get_session_id_cmd: ${get_session_id_cmd}"
	sessionID=`${get_session_id_cmd}`
	echo "XNAT session ID: ${sessionID}"

	resource_url=""
	resource_url+="${g_protocol}:"
	resource_url+="//${g_server}"
	resource_url+="/REST/projects/${g_project}"
	resource_url+="/subjects/${g_subject}"
	resource_url+="/experiments/${sessionID}"
	resource_url+="/resources/${g_resource}"
	resource_url+="/files"

	variable_values=""
	variable_values+="?overwrite=true"
	variable_values+="&replace=true"
	if [ ! -z "${g_reason}" ]; then
		variable_values+="&event_reason=${g_reason}"
	else
		variable_values+="&event_reason=Unspecified"
	fi
	variable_values+="&reference=${g_dir}"

	resource_uri="${resource_url}${variable_values}"

	echo "resource_uri: ${resource_uri}"

	if [ ! -z "${g_force}" ]; then
		put_it="TRUE"
	elif utils_ShouldProceed ; then 
		put_it="TRUE"
	else
		unset put_it
	fi

	if [ ! -z "${put_it}" ]; then
		java_cmd=""
		java_cmd+="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar"
		java_cmd+=" -u ${g_user}"
		java_cmd+=" -p ${g_password}"
		java_cmd+=" -m PUT"
		java_cmd+=" -r ${resource_uri}"
		#echo "java_cmd: ${java_cmd}"
		${java_cmd}
	else
		echo "Did not attempt to put to resource: ${resource_url}"
	fi
}

# Invoke the main function to get things started
main $@
