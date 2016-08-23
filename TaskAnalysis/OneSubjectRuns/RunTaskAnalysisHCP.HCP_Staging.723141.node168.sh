#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="723141"
project="HCP_Staging"
shadow_number=2
server="db-shadow${shadow_number}.nrg.mir:8080"
node="node168"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Task Analysis HCP job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo "--------------------------------------------------------------------------------"


at now + 6 days <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/TaskAnalysis/RunTaskAnalysis.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/TaskAnalysis/OneSubjectRuns/${subject}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/TaskAnalysis/OneSubjectRuns/${subject}.${node}.stderr
EOF
