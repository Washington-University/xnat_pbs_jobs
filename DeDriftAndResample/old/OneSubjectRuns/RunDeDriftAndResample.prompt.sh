#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

#subject="971160"
printf "Subject: "
read subject

#node="node159"
printf "Node: "
read node

printf "Delay submission for [0] minutes: "
read delay

if [ -z "${delay}" ]; then
	delay=0
fi

shadow_number=4

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running DeDriftAndResample job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo " Delaying submission for ${delay} minutes"
echo "--------------------------------------------------------------------------------"


at now + ${delay} minutes <<EOF

${HOME}/pipeline_tools/xnat_pbs_jobs/DeDriftAndResample/RunDeDriftAndResample.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DeDriftAndResample/OneSubjectRuns/${subject}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DeDriftAndResample/OneSubjectRuns/${subject}.${node}.stderr
EOF
