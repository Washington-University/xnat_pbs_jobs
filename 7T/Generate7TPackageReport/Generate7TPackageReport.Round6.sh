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


PACKAGES_ROOT_DIR="/HCP/hcpdb/packages/prerelease/zip/HCP_1200"

subjects=""
subjects+=" 126426 "
subjects+=" 130114 "
subjects+=" 130518 "
subjects+=" 134627 "
subjects+=" 135124 "
subjects+=" 146735 "
subjects+=" 150423 "
subjects+=" 165436 "
subjects+=" 167440 "
subjects+=" 169040 "
subjects+=" 177140 "
subjects+=" 180533 "
subjects+=" 186949 "
subjects+=" 193845 "
subjects+=" 239136 "
subjects+=" 360030 "
subjects+=" 385046 "
subjects+=" 401422 "
subjects+=" 463040 "
subjects+=" 550439 "
subjects+=" 552241 "
subjects+=" 644246 "
subjects+=" 654552 "
subjects+=" 757764 "
subjects+=" 765864 "
subjects+=" 878877 "
subjects+=" 905147 "
subjects+=" 943862 "
subjects+=" 971160 "
subjects+=" 973770 "
subjects+=" 995174 "
subjects+=" 102311 "
subjects+=" 102816 "
subjects+=" 105923 "
subjects+=" 108323 "
subjects+=" 109123 "
subjects+=" 111312 "
subjects+=" 111514 "
subjects+=" 125525 "
subjects+=" 126931 "
subjects+=" 131217 "
subjects+=" 131722 "
subjects+=" 132118 "
subjects+=" 137128 "
subjects+=" 140117 "
subjects+=" 144226 "
subjects+=" 145834 "
subjects+=" 146129 "
subjects+=" 146432 "
subjects+=" 156334 "
subjects+=" 157336 "
subjects+=" 158035 "
subjects+=" 158136 "
subjects+=" 159239 "
subjects+=" 164131 "
subjects+=" 167036 "
subjects+=" 169343 "
subjects+=" 169444 "
subjects+=" 171633 "
subjects+=" 172130 "
subjects+=" 173334 "
subjects+=" 176542 "
subjects+=" 177645 "
subjects+=" 177746 "
subjects+=" 178142 "
subjects+=" 181232 "
subjects+=" 182739 "
subjects+=" 185442 "
subjects+=" 191033 "
subjects+=" 191336 "
subjects+=" 191841 "
subjects+=" 192439 "
subjects+=" 192641 "
subjects+=" 195041 "
subjects+=" 196144 "
subjects+=" 197348 "
subjects+=" 199655 "
subjects+=" 200614 "
subjects+=" 203418 "
subjects+=" 204521 "
subjects+=" 205220 "
subjects+=" 212419 "
subjects+=" 214019 "
subjects+=" 221319 "
subjects+=" 233326 "
subjects+=" 246133 "
subjects+=" 249947 "
subjects+=" 251833 "
subjects+=" 352738 "
subjects+=" 365343 "
subjects+=" 380036 "
subjects+=" 397760 "
subjects+=" 412528 "
subjects+=" 436845 "
subjects+=" 473952 "
subjects+=" 541943 "
subjects+=" 547046 "
subjects+=" 573249 "
subjects+=" 601127 "
subjects+=" 627549 "
subjects+=" 638049 "
subjects+=" 680957 "
subjects+=" 690152 "
subjects+=" 732243 "
subjects+=" 745555 "
subjects+=" 770352 "
subjects+=" 771354 "
subjects+=" 782561 "
subjects+=" 783462 "
subjects+=" 789373 "
subjects+=" 814649 "
subjects+=" 825048 "
subjects+=" 826353 "
subjects+=" 833249 "
subjects+=" 859671 "
subjects+=" 861456 "
subjects+=" 871762 "
subjects+=" 872764 "
subjects+=" 898176 "
subjects+=" 899885 "
subjects+=" 901139 "
subjects+=" 901442 "
subjects+=" 910241 "
subjects+=" 951457 "
subjects+=" 958976 "
subjects+=" 100610 "
subjects+=" 104416 "
subjects+=" 114823 "
subjects+=" 115017 "
subjects+=" 115825 "
subjects+=" 116726 "
subjects+=" 118225 "
subjects+=" 128935 "
subjects+=" 134829 "
subjects+=" 146937 "
subjects+=" 148133 "
subjects+=" 155938 "
subjects+=" 162935 "
subjects+=" 164636 "
subjects+=" 169747 "
subjects+=" 175237 "
subjects+=" 178243 "
subjects+=" 178647 "
subjects+=" 181636 "
subjects+=" 182436 "
subjects+=" 187345 "
subjects+=" 198653 "
subjects+=" 200210 "
subjects+=" 200311 "
subjects+=" 201515 "
subjects+=" 209228 "
subjects+=" 214524 "
subjects+=" 257845 "
subjects+=" 263436 "
subjects+=" 283543 "
subjects+=" 318637 "
subjects+=" 320826 "
subjects+=" 330324 "
subjects+=" 346137 "
subjects+=" 381038 "
subjects+=" 389357 "
subjects+=" 393247 "
subjects+=" 395756 "
subjects+=" 406836 "
subjects+=" 429040 "
subjects+=" 467351 "
subjects+=" 525541 "
subjects+=" 536647 "
subjects+=" 562345 "
subjects+=" 572045 "
subjects+=" 581450 "
subjects+=" 585256 "
subjects+=" 617748 "
subjects+=" 671855 "
subjects+=" 706040 "
subjects+=" 724446 "
subjects+=" 725751 "
subjects+=" 751550 "
subjects+=" 818859 "
subjects+=" 878776 "
subjects+=" 926862 "
subjects+=" 927359 "
subjects+=" 942658 "
subjects+=" 966975 "

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


# preproc packages
preproc_packages=""

preproc_packages+=" 7T_MOVIE_1.6mm_preproc.zip "
preproc_packages+=" 7T_MOVIE_2mm_preproc.zip "
preproc_packages+=" 7T_MOVIE_preproc_extended.zip "

preproc_packages+=" 7T_REST_1.6mm_preproc.zip "
preproc_packages+=" 7T_REST_2mm_preproc.zip "
preproc_packages+=" 7T_REST_preproc_extended.zip "

preproc_packages+=" 7T_RET_1.6mm_preproc.zip "
preproc_packages+=" 7T_RET_2mm_preproc.zip "
preproc_packages+=" 7T_RET_preproc_extended.zip "

preproc_packages+=" 3T_Structural_1.6mm_preproc.zip "

# fix packages
fix_packages=""

fix_packages+=" 7T_MOVIE_1.6mm_fix.zip "
fix_packages+=" 7T_MOVIE_2mm_fix.zip "

fix_packages+=" 7T_REST_1.6mm_fix.zip "
fix_packages+=" 7T_REST_2mm_fix.zip "

fix_packages+=" 7T_RET_1.6mm_fix.zip "
fix_packages+=" 7T_RET_2mm_fix.zip "

# fix_extended packages
fix_extended_packages=""

fix_extended_packages+=" 7T_MOVIE_fixextended.zip "
fix_extended_packages+=" 7T_REST_fixextended.zip "
fix_extended_packages+=" 7T_RET_fixextended.zip "

echo ""
echo "All Packages"
echo ""
echo -e "\tSubject #\tSubject\tPackage\tSize\tDate\tChecksum Date"
echo ""

count=0
for subject in ${subjects} ; do

	count=$(( count + 1 ))

	for preproc_package in ${preproc_packages} ; do
		
		package_file=${PACKAGES_ROOT_DIR}/${subject}/preproc/${subject}_${preproc_package}
		md5_file=${package_file}.md5
		
		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date
		get_date ${md5_file} md5_file_date
		
		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"

	done
	
	for fix_package in ${fix_packages} ; do 
		
		package_file=${PACKAGES_ROOT_DIR}/${subject}/fix/${subject}_${fix_package}
		md5_file=${package_file}.md5

		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date
		get_date ${md5_file} md5_file_date

		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"

	done

	for fix_extended_package in ${fix_extended_packages} ; do 

		package_file=${PACKAGES_ROOT_DIR}/${subject}/fixextended/${subject}_${fix_extended_package}
		md5_file=${package_file}.md5
		
		get_size ${package_file} package_file_size
		get_date ${package_file} package_file_date
		get_date ${md5_file} md5_file_date
		
		echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"
		
	done

	echo ""
done


all_packages=""
all_packages+=" ${preproc_packages} "
all_packages+=" ${fix_packages} "
all_packages+=" ${fix_extended_packages} "

for package in ${all_packages} ; do

	echo ""
	echo "Package: ${package}"
	echo ""
	echo -e "\tSubject #\tSubject\tPackage\tSize\tDate\tChecksum Date"	
	echo ""

	count=0
	for subject in ${subjects} ; do
		count=$(( count + 1 ))
		
		if [[ ${preproc_packages} = *${package}* ]]; then

			package_file=${PACKAGES_ROOT_DIR}/${subject}/preproc/${subject}_${package}
			md5_file=${package_file}.md5
			
			get_size ${package_file} package_file_size
			get_date ${package_file} package_file_date
			get_date ${md5_file} md5_file_date
			
			echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"

		elif [[ ${fix_packages} = *${package}* ]]; then

			package_file=${PACKAGES_ROOT_DIR}/${subject}/fix/${subject}_${package}
			md5_file=${package_file}.md5
			
			get_size ${package_file} package_file_size
			get_date ${package_file} package_file_date
			get_date ${md5_file} md5_file_date
			
			echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"
			
		elif [[ ${fix_extended_packages} = *${package}* ]]; then

			package_file=${PACKAGES_ROOT_DIR}/${subject}/fixextended/${subject}_${package}
			md5_file=${package_file}.md5
			
			get_size ${package_file} package_file_size
			get_date ${package_file} package_file_date
			get_date ${md5_file} md5_file_date
			
			echo -e "\t${count}\t${subject}\t${package_file}\t${package_file_size}\t${package_file_date}\t${md5_file_date}"
			
		else

			echo "ERROR: Cannot figure out what kind of package ${package} is."
			exit 1
			
		fi

	done

done
