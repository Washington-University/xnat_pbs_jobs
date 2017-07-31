#!/bin/bash

subject=127226

stty -echo
printf "Password: "
read password
echo ""
stty echo

resources=""
resources+=" rfMRI_REST1_RL_FIX "
resources+=" rfMRI_REST1_RL_PostFix "
resources+=" rfMRI_REST1_RL_preproc "
resources+=" rfMRI_REST1_RL_RSS "

resources+=" rfMRI_REST2_LR_FIX "
resources+=" rfMRI_REST2_LR_PostFix "
resources+=" rfMRI_REST2_LR_preproc "
resources+=" rfMRI_REST2_LR_RSS "

resources+=" rfMRI_REST2_RL_FIX "
resources+=" rfMRI_REST2_RL_PostFix "
resources+=" rfMRI_REST2_RL_preproc "
resources+=" rfMRI_REST2_RL_RSS "

tasks=""
tasks+=" EMOTION "
tasks+=" GAMBLING "
tasks+=" LANGUAGE "
tasks+=" MOTOR "
tasks+=" RELATIONAL "
tasks+=" SOCIAL "
tasks+=" WM "

pe_dirs=""
pe_dirs+=" RL "
pe_dirs+=" LR "

for task in ${tasks} ; do
    for pe_dir in ${pe_dirs} ; do
        resources+=" tfMRI_${task} "
        resources+=" tfMRI_${task}_PostMsmAllTaskAnalysis "
        resources+=" tfMRI_${task}_${pe_dir}_preproc "
    done
done


for resource in ${resources} ; do
    echo "Deleting resource: ${resource}"
    ./DeleteResource.sh --user=tbbrown --project=HCP_Staging --subject=${subject} --session=${subject}_3T --resource=${resource} --password=${password} --force
done
