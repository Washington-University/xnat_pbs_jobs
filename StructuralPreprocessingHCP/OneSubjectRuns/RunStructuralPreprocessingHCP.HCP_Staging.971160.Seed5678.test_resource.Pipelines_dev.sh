#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

seed=5678
subject="971160"
shadow_number=1
#node="node017"
node="node100"

project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Structural Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/RunStructuralPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--seed=${seed} \
	--node=${node} \
	--output-resource="Structural_preproc_test_Pipelines_dev" \
	--setup-script="/home/HCPpipeline/SCRIPTS/SetUpHCPPipeline_StructuralPreprocHCP.Pipelines_dev.sh" \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/OneSubjectRuns/${subject}.${seed}.${node}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/StructuralPreprocessingHCP/OneSubjectRuns/${subject}.${seed}.${node}.stderr
EOF

