#
# Prerequisites:
#   XNAT_PIPELINE_HOME must be set
#   Shoud be setup to run python by sourcing epd-python_setup.sh 
#
delete_resource()
{
	local user=${1}     # Database user name
	local password=${2} # Database user password
	local server=${3}   # Database server
	local project=${4}  # Database project (e.g. HCP_500)
	local subject=${5}  # Database subject (e.g. 100307)
	local session=${6}  # Database session (e.g. 100307_3T)
	local resource=${7} # Resource name (e.g. rfMRI_REST1_LR_PostFix)

	echo ""
	echo "----------" `date` "----------"
	echo "Deleting Resource from archive"
	echo " User: ${user}"
	echo " Password: ********"
	echo " Server: ${server}"
	echo " Project: ${project}"
	echo " Subject: ${subject}"
	echo " Session: ${session}"
	echo " Resource: ${resource}"

	# Get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
	local get_session_id_cmd=""
	get_session_id_cmd+="python ${XNAT_PIPELINE_HOME}/catalog/ToolsHCP/resources/scripts/sessionid.py "
	get_session_id_cmd+="--server=${XNAT_PBS_JOBS_XNAT_SERVER} "
	get_session_id_cmd+="--username=${user} "
	get_session_id_cmd+="--password=${password} "
	get_session_id_cmd+="--project=${project} "
	get_session_id_cmd+="--subject=${subject} "
	get_session_id_cmd+="--session=${session}"
	local sessionID=`${get_session_id_cmd}`
	echo "XNAT sessionID: ${sessionID}"

	# Delete the specified resource
	local delete_resource_cmd=""
	delete_resource_cmd+="java -Xmx1024m -jar ${XNAT_PIPELINE_HOME}/lib/xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar "
	delete_resource_cmd+="-u ${user} -p ${password} -m DELETE "
	delete_resource_cmd+="-r http://${server}/REST/projects/${project}/subjects/${subject}/experiments/${sessionID}/resources/${resource}?removeFiles=true"
	${delete_resource_cmd}
}
