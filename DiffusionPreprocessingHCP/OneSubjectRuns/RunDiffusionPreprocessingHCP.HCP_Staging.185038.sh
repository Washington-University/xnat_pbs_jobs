#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

#subject="127226"
shadow_number=1
node="node115"
gpu_node="gpu004" # there is only one gpu node left on this cluster

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"


at now <<EOF

  /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/RunDiffusionPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=185038 \
	--phase-encoding-dir=RLLR \
	--node=${node} \
	--gpu-node=${gpu_node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/185038.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/DiffusionPreprocessingHCP/OneSubjectRuns/185038.stderr

EOF