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
subjects+=" 102816 "
subjects+=" 108323 "
subjects+=" 109123 "
subjects+=" 115825 "
subjects+=" 116726 "
subjects+=" 126426 "
subjects+=" 126931 "
subjects+=" 130114 "
subjects+=" 130518 "
subjects+=" 131217 "
subjects+=" 132118 "
subjects+=" 134627 "
subjects+=" 134829 "
subjects+=" 135124 "
subjects+=" 145834 "
subjects+=" 146735 "
subjects+=" 146937 "
subjects+=" 148133 "
subjects+=" 159239 "
subjects+=" 164636 "
subjects+=" 165436 "
subjects+=" 167036 "
subjects+=" 167440 "
subjects+=" 169040 "
subjects+=" 169343 "
subjects+=" 169444 "
subjects+=" 169747 "
subjects+=" 172130 "
subjects+=" 173334 "
subjects+=" 175237 "
subjects+=" 177140 "
subjects+=" 177645 "
subjects+=" 178243 "
subjects+=" 178647 "
subjects+=" 180533 "
subjects+=" 186949 "
subjects+=" 191033 "
subjects+=" 191336 "
subjects+=" 192439 "
subjects+=" 193845 "
subjects+=" 195041 "
subjects+=" 199655 "
subjects+=" 200614 "
subjects+=" 204521 "
subjects+=" 205220 "
subjects+=" 214524 "
subjects+=" 233326 "
subjects+=" 239136 "
subjects+=" 246133 "
subjects+=" 251833 "
subjects+=" 257845 "
subjects+=" 263436 "
subjects+=" 320826 "
subjects+=" 330324 "
subjects+=" 346137 "
subjects+=" 360030 "
subjects+=" 385046 "
subjects+=" 393247 "
subjects+=" 401422 "
subjects+=" 406836 "
subjects+=" 412528 "
subjects+=" 429040 "
subjects+=" 436845 "
subjects+=" 463040 "
subjects+=" 473952 "
subjects+=" 525541 "
subjects+=" 536647 "
subjects+=" 550439 "
subjects+=" 552241 "
subjects+=" 562345 "
subjects+=" 572045 "
subjects+=" 581450 "
subjects+=" 585256 "
subjects+=" 601127 "
subjects+=" 617748 "
subjects+=" 644246 "
subjects+=" 654552 "
subjects+=" 671855 "
subjects+=" 706040 "
subjects+=" 724446 "
subjects+=" 725751 "
subjects+=" 745555 "
subjects+=" 751550 "
subjects+=" 757764 "
subjects+=" 765864 "
subjects+=" 771354 "
subjects+=" 782561 "
subjects+=" 789373 "
subjects+=" 814649 "
subjects+=" 818859 "
subjects+=" 825048 "
subjects+=" 826353 "
subjects+=" 833249 "
subjects+=" 859671 "
subjects+=" 861456 "
subjects+=" 871762 "
subjects+=" 872764 "
subjects+=" 878776 "
subjects+=" 878877 "
subjects+=" 899885 "
subjects+=" 901442 "
subjects+=" 905147 "
subjects+=" 910241 "
subjects+=" 926862 "
subjects+=" 927359 "
subjects+=" 942658 "
subjects+=" 943862 "
subjects+=" 966975 "
subjects+=" 971160 "
subjects+=" 973770 "
subjects+=" 995174 "

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