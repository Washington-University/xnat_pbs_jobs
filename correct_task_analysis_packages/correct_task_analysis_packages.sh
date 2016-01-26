#!/bin/bash

get_options() 
{
	local arguments=($@)

	unset g_project
	unset g_subject

	local num_args=${#arguments[@]}
	local argument
	local index=0

	while [ ${index} -lt ${num_args} ]; do
		argument=${arguments[index]}

		case ${argument} in
			--project=*)
				g_project=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			--subject=*)
				g_subject=${argument/*=/""}
				index=$(( index + 1 ))
				;;
			*)
				echo "ERROR: unrecognized option: ${argument}"
				exit 1
		esac
	done
}

main()
{
	get_options $@

	date

	pushd /HCP/hcpdb/packages/live/${g_project}/${g_subject}

	smoothing_levels="2 4"

	for smoothing_level in ${smoothing_levels} ; do
		pushd analysis_s${smoothing_level}

		pwd

		tasks="EMOTION GAMBLING LANGUAGE MOTOR RELATIONAL SOCIAL WM"

		for task in ${tasks} ; do
			other_tasks=${tasks/${task}/}
			other_smoothing_levels=${smoothing_levels/${smoothing_level}/}

			echo "Working on task: ${task}"
			echo "Other tasks: ${other_tasks}"
			echo "Working on smoothing level: ${smoothing_level}"
			echo "Other smoothing levels: ${other_smoothing_levels}"

			extension_file="${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}_S500_to_S900_extension.zip"
			echo ""
			echo "--------------------------------------------------------------------------------"
			echo "extension_file: ${extension_file}"
			echo "--------------------------------------------------------------------------------"
			echo ""
			if [ -e "${extension_file}" ] ; then
				new_dir="/HCP/hcpdb/packages/task_analysis_repair/${g_subject}/analysis_s${smoothing_level}"
				mkdir -p ${new_dir}

				new_file=${new_dir}/${extension_file}
				cp ${extension_file} ${new_file}

				for other_task in ${other_tasks} ; do
					echo "other_task: ${other_task}"
					some_to_remove=`unzip -l ${new_file} | grep "${other_task}"`
					echo -e "some_to_remove:\n${some_to_remove}"
					if [ ! -z "${some_to_remove}" ] ; then
						zip --verbose -d ${new_file} "*${other_task}*"
					fi
				done

				for other_level in ${other_smoothing_levels} ; do
					echo "other_level: ${other_level}"
					some_to_remove=`unzip -l ${new_file} | grep "_s${other_level}"`
					echo -e "some_to_remove:\n${some_to_remove}"
					if [ ! -z "${some_to_remove}" ] ; then
						zip --verbose -d ${new_file} "*_s${other_level}*"
					fi
				done

				md5sum ${new_file} > ${new_file}.md5
				chmod u=rw,g=rw,o=r ${new_file}.md5
			fi
			echo ""
			


			full_package_file="${g_subject}_3T_tfMRI_${task}_analysis_s${smoothing_level}.zip"
			echo ""
			echo "--------------------------------------------------------------------------------"
			echo "full_package_file: ${full_package_file}"
			echo "--------------------------------------------------------------------------------"
			echo ""

			if [ -e "${full_package_file}" ] ; then
				new_dir="/HCP/hcpdb/packages/task_analysis_repair/${g_subject}/analysis_s${smoothing_level}"
				mkdir -p ${new_dir}

				new_file=${new_dir}/${full_package_file}
				cp ${full_package_file} ${new_file}

				for other_task in ${other_tasks} ; do
					echo "other_task: ${other_task}"
					some_to_remove=`unzip -l ${new_file} | grep "${other_task}"`
					echo -e "some_to_remove:\n${some_to_remove}"
					if [ ! -z "${some_to_remove}" ] ; then
						zip --verbose -d ${new_file} "*${other_task}*"
					fi
				done

				for other_level in ${other_smoothing_levels} ; do
					echo "other_level: ${other_level}"
					some_to_remove=`unzip -l ${new_file} | grep "_s${other_level}"`
					echo -e "some_to_remove:\n${some_to_remove}"
					if [ ! -z "${some_to_remove}" ] ; then
						zip --verbose -d ${new_file} "*_s${other_level}*"
					fi
				done

				md5sum ${new_file} > ${new_file}.md5
				chmod u=rw,g=rw,o=r ${new_file}.md5
			fi
			echo ""

		done

		popd

	done

	popd

	date
}

# Invoke the main function to get things started
main $@
