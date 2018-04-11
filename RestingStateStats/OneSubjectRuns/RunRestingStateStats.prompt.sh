#!/bin/bash

SCRIPT_NAME=`basename ${0}`

inform()
{
	msg=${1}
	echo "${SCRIPT_NAME}: ${msg}"
}

if [ -z "${XNAT_PBS_JOBS}" ]; then
	inform "Environment variable XNAT_PBS_JOBS must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MIN_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MIN_SHADOW must be set!"
	exit 1
fi

if [ -z "${XNAT_PBS_JOBS_MAX_SHADOW}" ]; then
	inform "Environment variable XNAT_PBS_JOBS_MAX_SHADOW must be set!"
	exit 1
fi

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

#subject="329844"
printf "Subject: "
read subject

#node="node163"
printf "Node: " 
read node

printf "Delay submission for (minutes) [0]: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

start_shadow_number=${XNAT_PBS_JOBS_MIN_SHADOW}
max_shadow_number=${XNAT_PBS_JOBS_MAX_SHADOW}
shadow_number=`shuf -i ${min_shadow_number}-${max_shadow_number} -n 1`

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Resting State Stats job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo " Delaying submission for: ${delay} minutes"
echo "--------------------------------------------------------------------------------"

at now + ${delay} minutes <<EOF

${XNAT_PBS_JOBS}/RestingStateStats/RunRestingStateStats.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/OneSubjectRuns/${subject}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/RestingStateStats/OneSubjectRuns/${subject}.${node}.stderr
EOF
