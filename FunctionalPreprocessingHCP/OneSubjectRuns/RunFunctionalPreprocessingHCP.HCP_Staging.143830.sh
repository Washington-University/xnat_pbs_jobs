#!/bin/bash

printf "Connectome DB Username: "
read userid

stty -echo
printf "Connectome DB Password: "
read password
echo ""
stty echo

subject="143830"
shadow_number=3
node="node167"
project="HCP_Staging"
server="db-shadow${shadow_number}.nrg.mir:8080"

echo ""
echo "--------------------------------------------------------------------------------"
echo " Running Functional Preprocessing job for subject: ${subject}"
echo " Using server: ${server}"
echo "--------------------------------------------------------------------------------"

at now <<EOF

/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/FunctionalPreprocessingHCP/RunFunctionalPreprocessingHCP.OneSubject.sh \
	--user=${userid} \
	--password=${password} \
	--server=${server} \
	--project=${project} \
	--subject=${subject} \
	--node=${node} \
	> /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/FunctionalPreprocessingHCP/OneSubjectRuns/${subject}.stdout \
	2>/home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/FunctionalPreprocessingHCP/OneSubjectRuns/${subject}.stderr
EOF