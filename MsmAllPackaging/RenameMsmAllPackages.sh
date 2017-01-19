#!/bin/bash

pushd /HCP/hcpdb/packages/PostMsmAll

#DO_IT="FALSE"
DO_IT="TRUE"

subjects=`ls -1`

for subject in ${subjects} ; do
    echo ""
    echo "subject: ${subject}"
    echo ""

    pushd ${subject}
    files=`find . -name "*.MSMAllPatch*"`

    for file in ${files} ; do
        new_name="${file//\.MSMAllPatch/_S500_to_S900_extension}"
        if [ "${DO_IT}" = "TRUE" ] ; then
            mv --verbose ${file} ${new_name}
        else
            echo -e "file: ${file}\tnew_name: ${new_name}"
        fi
    done

    popd

done


popd
