#!/usr/bin/env python3

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import hcp.one_subject_completion_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(hcp.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp7t_subject_info, scan_name):
        name_list = archive.available_RSS_processed_names(hcp7t_subject_info)
        return scan_name in name_list

    def is_processing_complete(self, archive, hcp7t_subject_info, scan_name, verbose=False):
        
        # If the processsed resource does not exist, then the process is certainly not complete.
        if not self.does_processed_resource_exist(archive, hcp7t_subject_info, scan_name):
            return False
            
        # If we reach here, then the processed resource at least exists.
        # Next we need to check to see if the expected files exist.
        
        # Build a list of expected files
        scan_long_name = archive.functional_scan_long_name(scan_name)
        file_name_list = []

        results_dir = os.sep.join([archive.RSS_processed_dir_fullpath(hcp7t_subject_info, scan_name),
                                   'MNINonLinear',
                                   'Results'])

        scan_results_dir = os.sep.join([results_dir, scan_long_name])

        file_name_list.append(scan_results_dir + os.sep + scan_long_name + '_Atlas_hp2000_clean_vn.dscalar.nii')
        file_name_list.append(scan_results_dir + os.sep + scan_long_name + '_Atlas_stats.dscalar.nii')
        file_name_list.append(scan_results_dir + os.sep + scan_long_name + '_Atlas_stats.txt')
        file_name_list.append(scan_results_dir + os.sep + scan_long_name + '_CSF.txt')
        file_name_list.append(scan_results_dir + os.sep + scan_long_name + '_WM.txt')

        resting_state_stats_dir = os.sep.join([scan_results_dir, 'RestingStateStats'])

        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1-2_OrigTCS-HighPassTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1-2_OrigTCS-HighPassTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1-5_OrigTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1-5_OrigTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1_OrigTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_1_OrigTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2-3_HighPassTCS-PostMotionTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2-3_HighPassTCS-PostMotionTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2-5_HighPassTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2-5_HighPassTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2_HighPassTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_2_HighPassTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3-4_PostMotionTCS-CleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3-4_PostMotionTCS-CleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3-5_PostMotionTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3-5_PostMotionTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3_PostMotionTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_3_PostMotionTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-5_CleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-5_CleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-6_CleanedTCS-WMCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-6_CleanedTCS-WMCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-7_CleanedTCS-CSFCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-7_CleanedTCS-CSFCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-8_CleanedTCS-WMCSFCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4-8_CleanedTCS-WMCSFCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4_CleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_4_CleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_5_UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_5_UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_6-5_WMCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_6-5_WMCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_6_WMCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_6_WMCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_7-5_CSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_7-5_CSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_7_CSFCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_7_CSFCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_8-5_WMCSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_8-5_WMCSFCleanedTCS-UnstructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_8_WMCSFCleanedTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_8_WMCSFCleanedTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_9_StructNoiseTCS_QC_Summary_Plot.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_9_StructNoiseTCS_QC_Summary_Plot_z.png')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_CleanedCSFtc.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_CleanedMGT.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_CleanedWMtc.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_HighPassMGT.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_NoiseMGT.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_OrigMGT.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_PostMotionMGT.txt')
        file_name_list.append(resting_state_stats_dir + os.sep + scan_long_name + '_Atlas_UnstructNoiseMGT.txt')

        rois_dir = os.sep.join([archive.RSS_processed_dir_fullpath(hcp7t_subject_info, scan_name),
                                'MNINonLinear',
                                'ROIs'])
        
        file_name_list.append(rois_dir + os.sep + 'CSFReg.1.60.nii.gz')
        file_name_list.append(rois_dir + os.sep + 'WMReg.1.60.nii.gz')

        return self.do_all_files_exist(file_name_list, verbose)
