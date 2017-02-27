#!/bin/bash

set -e

# --------------------
project=HCP_500
# --------------------

subject_list=""
subject_list+=" 101107 "
subject_list+=" 111716 "
subject_list+=" 162733 "
subject_list+=" 211720 "
subject_list+=" 786569 "

for subject in ${subject_list} ; do

	current_seconds_since_epoch=`date +%s`

	./UpdateFixPackage.sh \
		--current-packages-root=/HCP/hcpdb/packages/live \
		--archive-root=/HCP/hcpdb/archive \
		--output-dir=/HCP/hcpdb/packages/HandReclassification \
		--tmp-dir=/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp/UpdateFixPackage_${current_seconds_since_epoch}_${subject} \
		--subject=${subject} \
		--project=${project}
	
done

# --------------------
project=HCP_900
# --------------------

subject_list=""
subject_list+=" 134728 "
subject_list+=" 148436 "
subject_list+=" 178647 "
subject_list+=" 336841 "
subject_list+=" 614439 "
subject_list+=" 628248 "

for subject in ${subject_list} ; do

	current_seconds_since_epoch=`date +%s`

	./UpdateFixPackage.sh \
		--current-packages-root=/HCP/hcpdb/packages/live \
		--archive-root=/HCP/hcpdb/archive \
		--output-dir=/HCP/hcpdb/packages/HandReclassification \
		--tmp-dir=/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp/UpdateFixPackage_${current_seconds_since_epoch}_${subject} \
		--subject=${subject} \
		--project=${project}
	
done

# --------------------
project=HCP_1200
# --------------------

subject_list=""

subject_list+=" 136631 "
subject_list+=" 165941 "
subject_list+=" 186040 "
subject_list+=" 204218 "
subject_list+=" 567759 "
subject_list+=" 763557 "
subject_list+=" 825553 "
subject_list+=" 943862 "

for subject in ${subject_list} ; do

	current_seconds_since_epoch=`date +%s`

	./UpdateFixPackage.sh \
		--current-packages-root=/HCP/hcpdb/packages/live \
		--archive-root=/HCP/hcpdb/archive \
		--output-dir=/HCP/hcpdb/packages/HandReclassification \
		--tmp-dir=/HCP/hcpdb/build_ssd/chpc/BUILD/packages/temp/UpdateFixPackage_${current_seconds_since_epoch}_${subject} \
		--subject=${subject} \
		--project=${project}
	
done




