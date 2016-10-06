#!/bin/bash

get_date()
{
	local path=${1}
	local __functionResultVar=${2}
	local file_info
	local the_date

	if [ -e "${path}" ] ; then
		file_info=`ls -lh ${path}`
		the_date=`echo ${file_info} | cut -d " " -f 6-8`
	else
		the_date="DOES NOT EXIST"
	fi

	eval $__functionResultVar="'${the_date}'"
}

get_size()
{
	local path=${1}
	local __functionResultVar=${2}
	local file_info
	local the_size

	if [ -e "${path}" ] ; then
		file_info=`ls -lh ${path}`
		the_size=`echo ${file_info} | cut -d " " -f 5`
	else
		the_size="DOES NOT EXIST"
	fi

	eval $__functionResultVar="'${the_size}'"
}


PACKAGES_ROOT_DIR="/HCP/hcpdb/packages/prerelease/zip/HCP_Staging_7T"

subjects=""
subjects+=" 102311 "
subjects+=" 105923 "
subjects+=" 111312 "
subjects+=" 111514 "
subjects+=" 125525 "
subjects+=" 131722 "
subjects+=" 137128 "
subjects+=" 140117 "
subjects+=" 144226 "
subjects+=" 146129 "
subjects+=" 146432 "
subjects+=" 150423 "
subjects+=" 156334 "
subjects+=" 157336 "
subjects+=" 158035 "
subjects+=" 158136 "
subjects+=" 164131 "
subjects+=" 171633 "
subjects+=" 176542 "
subjects+=" 177746 "
subjects+=" 178142 "
subjects+=" 181232 "
subjects+=" 182739 "
subjects+=" 185442 "
subjects+=" 191841 "
subjects+=" 192641 "
subjects+=" 195041 "
subjects+=" 196144 "
subjects+=" 197348 "
subjects+=" 203418 "
subjects+=" 212419 "
subjects+=" 214019 "
subjects+=" 221319 "
subjects+=" 249947 "
subjects+=" 352738 "
subjects+=" 365343 "
subjects+=" 380036 "
subjects+=" 397760 "
subjects+=" 541943 "
subjects+=" 547046 "
subjects+=" 573249 "
subjects+=" 627549 "
subjects+=" 638049 "
subjects+=" 680957 "
subjects+=" 690152 "
subjects+=" 732243 "
subjects+=" 770352 "
subjects+=" 783462 "
subjects+=" 898176 "
subjects+=" 901139 "
subjects+=" 951457 "
subjects+=" 958976 "
subjects+=" 100610 "
subjects+=" 104416 "
subjects+=" 114823 "
subjects+=" 115017 "
subjects+=" 118225 "
subjects+=" 128935 "
subjects+=" 155938 "
subjects+=" 162935 "
subjects+=" 181636 "
subjects+=" 182436 "
subjects+=" 187345 "
subjects+=" 198653 "
subjects+=" 200210 "
subjects+=" 200311 "
subjects+=" 201515 "
subjects+=" 209228 "
subjects+=" 283543 "
subjects+=" 318637 "
subjects+=" 381038 "
subjects+=" 389357 "
subjects+=" 395756 "
subjects+=" 467351 "


scans=""
scans+=" rfMRI_REST1 "
scans+=" rfMRI_REST2 "
scans+=" rfMRI_REST3 "
scans+=" rfMRI_REST4 "

scans+=" tfMRI_MOVIE1 "
scans+=" tfMRI_MOVIE2 "
scans+=" tfMRI_MOVIE3 "
scans+=" tfMRI_MOVIE4 "

scans+=" tfMRI_RETBAR1 "
scans+=" tfMRI_RETBAR2 "
scans+=" tfMRI_RETCCW "
scans+=" tfMRI_RETCON "
scans+=" tfMRI_RETCW "
scans+=" tfMRI_RETEXP "

for unproc_scan in ${scans} ; do

	echo ""
	echo "Unproc Package: ${unproc_scan}"
	echo ""
	echo -e "\t\tSubject\tPackage\tSize\tDate"

	count=0
	for subject in ${subjects} ; do
		
		count=$(( count + 1 ))
		package_file=${PACKAGES_ROOT_DIR}/${subject}/unproc/${subject}_7T_${unproc_scan}_unproc.zip
		md5_file=${package_file}.md5
		
		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date
		
		#get_size ${md5_file} md5_file_size
		#get_date ${md5_file} md5_file_date
		
		short_package_file=${package_file##*/}
		
		echo -e "\t${count}\t${subject}\t${short_package_file}\t${package_file_size}\t${package_file_date}"

	done

done

preproc_packages=""
preproc_packages+=" 7T_MOVIE_1.6mm_preproc.zip "
preproc_packages+=" 7T_MOVIE_2mm_preproc.zip "
preproc_packages+=" 7T_MOVIE_preproc_extended.zip "
preproc_packages+=" 7T_MOVIE_Volume_preproc.zip "
preproc_packages+=" 7T_REST_1.6mm_preproc.zip "
preproc_packages+=" 7T_REST_2mm_preproc.zip "
preproc_packages+=" 7T_REST_preproc_extended.zip "
preproc_packages+=" 7T_REST_Volume_preproc.zip "
preproc_packages+=" 7T_RET_1.6mm_preproc.zip "
preproc_packages+=" 7T_RET_2mm_preproc.zip "
preproc_packages+=" 7T_RET_preproc_extended.zip "
preproc_packages+=" 7T_RET_Volume_preproc.zip "
preproc_packages+=" 7T_Structural_preproc.zip "

for preproc_package in ${preproc_packages} ; do

	echo ""
	echo "Preproc Package: ${preproc_package}"
	echo ""
	echo -e "\t\tSubject\tPackage\tSize\tDate"

	count=0
	for subject in ${subjects} ; do

		count=$(( count + 1 ))
		package_file=${PACKAGES_ROOT_DIR}/${subject}/preproc/${subject}_${preproc_package}
		md5_file=${package_file}.md5

		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date

		short_package_file=${package_file##*/}
		echo -e "\t${count}\t${subject}\t${short_package_file}\t${package_file_size}\t${package_file_date}"

	done

done

fix_packages=""
fix_packages+=" 7T_MOVIE_1.6mm_fix.zip "
fix_packages+=" 7T_MOVIE_2mm_fix.zip "
fix_packages+=" 7T_MOVIE_Volume_fix.zip "
fix_packages+=" 7T_REST_1.6mm_fix.zip "
fix_packages+=" 7T_REST_2mm_fix.zip "
fix_packages+=" 7T_REST_Volume_fix.zip "

for fix_package in ${fix_packages} ; do 

	echo ""
	echo "FIX Package: ${fix_package}"
	echo ""
	echo -e "\t\tSubject\tPackage\tSize\tDate"

	count=0
	for subject in ${subjects} ; do

		count=$(( count + 1 ))
		package_file=${PACKAGES_ROOT_DIR}/${subject}/fix/${subject}_${fix_package}
		md5_file=${package_file}.md5

		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date

		short_package_file=${package_file##*/}
		echo -e "\t${count}\t${subject}\t${short_package_file}\t${package_file_size}\t${package_file_date}"

	done

done