#!/bin/bash
g_script_name=$(basename "${0}")

g_user=nobody
g_password=nothing

echo "${g_script_name}: ABORTING: you need to edit this script and put in a user name and password"
exit 1

do_put()
{
    local project=${1}
    local subject=${2}
    local scan=${3}

    /home/HCPpipeline/pipeline_tools/xnat_pbs_jobs/WorkingDirPut/PutDirIntoResource.sh \
        --user=${g_user} \
        --password=${g_password} \
        --project=${project} \
        --subject=${subject} \
        --session=${subject}_3T \
        --resource=rfMRI_${scan}_HandReclassification \
        --dir=/data/hcpdb/build_ssd/chpc/BUILD/HandReclassifications/${subject}_${scan}_HandReclassification \
        --reason="HandReclassification" \
        --force
}

# # --------------------

# project=HCP_500
# subject=101107
# scan_list=""
# scan_list+=" REST1_LR "
# scan_list+=" REST2_LR "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# # --------------------

# project=HCP_500
# subject=111716
# scan_list=""
# scan_list+=" REST1_RL "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# exit

# # --------------------

# project=HCP_500
# subject=162733
# scan_list=""
# scan_list+=" REST2_LR "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# # --------------------

# project=HCP_500
# subject=211720
# scan_list=""
# scan_list+=" REST1_RL "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# --------------------

# project=HCP_500
# subject=786569
# scan_list=""
# scan_list+=" REST1_LR "
# scan_list+=" REST1_RL "
# scan_list+=" REST2_LR "
# scan_list+=" REST2_RL "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# # --------------------

# project=HCP_900
# subject=134728
# scan_list=""
# scan_list+=" REST1_LR "
# scan_list+=" REST1_RL "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# # --------------------

# project=HCP_900
# subject=148436
# scan_list=""
# scan_list+=" REST1_RL "

# for scan in ${scan_list} ; do
#   do_put ${project} ${subject} ${scan}
# done

# --------------------

project=HCP_900
subject=178647
scan_list=""
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_900
subject=336841
scan_list=""
scan_list+=" REST1_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_900
subject=614439
scan_list=""
scan_list+=" REST1_RL "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_900
subject=628248
scan_list=""
scan_list+=" REST1_RL "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=136631
scan_list=""
scan_list+=" REST1_LR "
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=165941
scan_list=""
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=186040
scan_list=""
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=204218
scan_list=""
scan_list+=" REST1_LR "
scan_list+=" REST1_RL "
scan_list+=" REST2_LR "
scan_list+=" REST2_RL "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=567759
scan_list=""
scan_list+=" REST1_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=763557
scan_list=""
scan_list+=" REST1_LR "
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=825553
scan_list=""
scan_list+=" REST2_LR "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done

# --------------------

project=HCP_Staging
subject=943862
scan_list=""
scan_list+=" REST1_LR "
scan_list+=" REST2_LR "
scan_list+=" REST2_RL "

for scan in ${scan_list} ; do
    do_put ${project} ${subject} ${scan}
done


