#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="158843"
project="HCP_900"
shadow_number=2
server="db-shadow${shadow_number}.nrg.mir:8080"
node="node156"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Post MSM-All Task Analysis HCP job for subject: ${subject}"
echo " In project: ${project}"
echo " Using server: ${server}"
echo " Using compute node: ${node}"
echo "--------------------------------------------------------------------------------"


at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/RunPostMsmAllTaskAnalysis.OneSubject.SOCIAL_ONLY.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/PostMsmAllTaskAnalysis/OneSubjectRuns/${subject}.${node}.stderr
EOF
