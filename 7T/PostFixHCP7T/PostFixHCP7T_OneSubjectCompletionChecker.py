#!/usr/bin/env python3

"""
PostFixHCP7T_OneSubjectCompletionChecer.py: Check PostFixHCP7T processing completion status
for one HCP 7T Subject.
"""

# import of built-in modules
import os

# import of third party modules
pass

# import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


class PostFixHCP7T_OneSubjectCompletionChecker:

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp7t_subject_info, scan_name):
        return scan_name in archive.available_PostFix_processed_names(hcp7t_subject_info)

    def is_processing_complete(self, archive, hcp7t_subject_info, scan_name):
        """
        Returns True if the specified scan has completed
        PostFixHCP7T processing for the specified subject.
        """

        # If the output resource does not exist, then the PostFixHCP7T processing
        # has not been done.
        if not self.does_processed_resource_exist(archive, hcp7t_subject_info, scan_name):
            return False

        # If we reach here, then the PostFixHCP7T processed resource at least exists.
        # Next we need to check to see if the expected files exist.
        results_dir = archive.subject_resources_dir_fullpath(hcp7t_subject_info) 
        results_dir += os.sep + archive.PostFix_processed_resource_name(scan_name)

        results_scan_dir = results_dir + os.sep + 'MNINonLinear' + os.sep + 'Results' 
        results_scan_dir += os.sep + archive.functional_scan_long_name(scan_name)

        file_name_list = []

        # files in results_scan_dir
        file_name_list.append(results_scan_dir + os.sep + hcp7t_subject_info.subject_id + '_' +
                              archive.functional_scan_long_name(scan_name) + '_ICA_Classification_dualscreen.scene')
        file_name_list.append(results_scan_dir + os.sep + hcp7t_subject_info.subject_id + '_' +
                              archive.functional_scan_long_name(scan_name) + '_ICA_Classification_singlescreen.scene')
        file_name_list.append(results_scan_dir + os.sep + 'ReclassifyAsNoise.txt')
        file_name_list.append(results_scan_dir + os.sep + 'ReclassifyAsSignal.txt')

        if scan_name != 'tfMRI_7T_RETCCW_AP_RETCW_PA_RETEXP_AP_RETCON_PA_RETBAR1_AP_RETBAR2_PA':
            file_name_list.append(results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) +
                                  '_Atlas_hp2000.dtseries.nii')

        # files in ica_dir
        ica_dir = results_scan_dir + os.sep + archive.functional_scan_long_name(scan_name) + '_hp2000.ica'

        file_name_list.append(ica_dir + os.sep + 'Noise.txt')
        file_name_list.append(ica_dir + os.sep + 'Signal.txt')

        # files in filtered_func_data_dir
        filtered_func_data_dir = ica_dir + os.sep + 'filtered_func_data.ica'

        file_name_list.append(filtered_func_data_dir + os.sep + 'ICAVolumeSpace.txt')
        file_name_list.append(filtered_func_data_dir + os.sep + 'mask.nii.gz')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_FTmix.sdseries.nii')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_mix.sdseries.nii')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_oIC.dscalar.nii')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_oIC.dtseries.nii')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_oIC_vol.dscalar.nii')
        file_name_list.append(filtered_func_data_dir + os.sep + 'melodic_oIC_vol.dtseries.nii')

        for file_name in file_name_list:
            # _inform("Checking for existence of file: " + file_name)
            if os.path.isfile(file_name):
                continue
            # If we get here, the most recently checked file does not exist
            _inform("FILE DOES NOT EXIST: " + file_name)
            return False

        # If we get here, all files that were checked exist
        return True
