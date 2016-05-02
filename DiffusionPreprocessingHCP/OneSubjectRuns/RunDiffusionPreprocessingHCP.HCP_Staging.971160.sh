#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="971160"
shadow_number=1
node="node115"
gpu_node="gpu004" # there is only one gpu node left on this cluster

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"


at now + 30 hours <<EOF

  /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/RunDiffusionPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--phase-encoding-dir=RLLR \
	--node=${node} \
	--gpu-node=${gpu_node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/${subject}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/${subject}.stderr

EOF