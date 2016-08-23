#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo


stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

printf "Subject: "
read subject

printf "Node: "
read node

printf "Delay submission for [0] minutes: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

shadow_number=3

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Generate Spin Echo Bias Field Prereqs job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo " Delaying submission for ${delay} minutes"
echo "--------------------------------------------------------------------------------"

at now + ${delay} minutes <<EOF

${HOME}/pipeline_tools/xnat_pbs_jobs/GenerateSpinEchoBiasFieldPrereqs/RunGenerateSpinEchoBiasFieldPrereqs.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> ${HOME}/pipeline_tools/xnat_pbs_jobs/GenerateSpinEchoBiasFieldPrereqs/OneSubjectRuns/${subject}.${node}.stdout \
	2>${HOME}/pipeline_tools/xnat_pbs_jobs/GenerateSpinEchoBiasFieldPrereqs/OneSubjectRuns/${subject}.${node}.stderr

EOF
