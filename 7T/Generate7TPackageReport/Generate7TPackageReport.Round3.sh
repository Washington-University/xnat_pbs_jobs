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
subjects+=" 193845 "

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
		
		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}"

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

		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}"

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

		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}"

	done

done