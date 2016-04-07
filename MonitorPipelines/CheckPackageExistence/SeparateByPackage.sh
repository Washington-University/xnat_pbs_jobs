#!/bin/bash

UNPROC_PACKAGE_TYPES=""
UNPROC_PACKAGE_TYPES+=" Structural_unproc "
UNPROC_PACKAGE_TYPES+=" rfMRI_REST1_unproc "
UNPROC_PACKAGE_TYPES+=" rfMRI_REST2_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_EMOTION_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_GAMBLING_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_LANGUAGE_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_MOTOR_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_RELATIONAL_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_SOCIAL_unproc "
UNPROC_PACKAGE_TYPES+=" tfMRI_WM_unproc "
UNPROC_PACKAGE_TYPES+=" Diffusion_unproc "

PREPROC_PACKAGE_TYPES=""
PREPROC_PACKAGE_TYPES+=" Structural_preproc "
PREPROC_PACKAGE_TYPES+=" Structural_preproc_extended "
PREPROC_PACKAGE_TYPES+=" rfMRI_REST1_preproc "
PREPROC_PACKAGE_TYPES+=" rfMRI_REST2_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_EMOTION_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_GAMBLING_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_LANGUAGE_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_MOTOR_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_RELATIONAL_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_SOCIAL_preproc "
PREPROC_PACKAGE_TYPES+=" tfMRI_WM_preproc "
PREPROC_PACKAGE_TYPES+=" Diffusion_preproc "

FIX_PACKAGE_TYPES=""
FIX_PACKAGE_TYPES+=" rfMRI_REST_fix "

FIX_EXTENDED_PACKAGE_TYPES=""
FIX_EXTENDED_PACKAGE_TYPES+=" rfMRI_REST1_fixextended "
FIX_EXTENDED_PACKAGE_TYPES+=" rfMRI_REST2_fixextended "

TASK_ANALYSIS_SMOOTHING_LEVELS=""
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 2 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 4 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 8 "
TASK_ANALYSIS_SMOOTHING_LEVELS+=" 12 "

TASK_ANALYSIS_PACKAGE_TYPES=""
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_EMOTION "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_GAMBLING "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_LANGUAGE "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_MOTOR "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_RELATIONAL "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_SOCIAL "
TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_WM "

VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS=""
VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS+=" 4 "

VOLUME_TASK_ANALYSIS_PACKAGE_TYPES=""
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_EMOTION "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_GAMBLING "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_LANGUAGE "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_MOTOR "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_RELATIONAL "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_SOCIAL "
VOLUME_TASK_ANALYSIS_PACKAGE_TYPES+=" tfMRI_WM "

UPGRADE_POSTFIX="_S500_to_S900_extension"

printf "Package Report File (All Subjects): "
read all_subjects_package_report_file

for package_type in ${UNPROC_PACKAGE_TYPES} ; do
	grep ${package_type}.zip ${all_subjects_package_report_file} > ${package_type}.Report.tsv
	grep ${package_type}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}${UPGRADE_POSTFIX}.Report.tsv
done

for package_type in ${PREPROC_PACKAGE_TYPES} ; do
	grep ${package_type}.zip ${all_subjects_package_report_file} > ${package_type}.Report.tsv
	grep ${package_type}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}${UPGRADE_POSTFIX}.Report.tsv
done

for package_type in ${FIX_PACKAGE_TYPES} ; do
	grep ${package_type}.zip ${all_subjects_package_report_file} > ${package_type}.Report.tsv
	grep ${package_type}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}${UPGRADE_POSTFIX}.Report.tsv
done

for package_type in ${FIX_EXTENDED_PACKAGE_TYPES} ; do
	grep ${package_type}.zip ${all_subjects_package_report_file} > ${package_type}.Report.tsv
	grep ${package_type}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}${UPGRADE_POSTFIX}.Report.tsv
done

for smoothing_level in ${TASK_ANALYSIS_SMOOTHING_LEVELS} ; do
	for package_type in ${TASK_ANALYSIS_PACKAGE_TYPES} ; do
		grep ${package_type}_analysis_s${smoothing_level}.zip ${all_subjects_package_report_file} > ${package_type}_analysis_s${smoothing_level}.Report.tsv
		grep ${package_type}_analysis_s${smoothing_level}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}_analysis_s${smoothing_level}${UPGRADE_POSTFIX}.Report.tsv
	done
done

for smoothing_level in ${VOLUME_TASK_ANALYSIS_SMOOTHING_LEVELS} ; do
	for package_type in ${VOLUME_TASK_ANALYSIS_PACKAGE_TYPES} ; do
		grep ${package_type}_volume_s${smoothing_level}.zip ${all_subjects_package_report_file} > ${package_type}_volume_s${smoothing_level}.Report.tsv
		grep ${package_type}_volume_s${smoothing_level}${UPGRADE_POSTFIX}.zip ${all_subjects_package_report_file} > ${package_type}_volume_s${smoothing_level}${UPGRADE_POSTFIX}.Report.tsv
	done
done
