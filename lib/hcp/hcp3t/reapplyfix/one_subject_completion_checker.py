#!/usr/bin/env python3

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import hcp.one_subject_completion_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(hcp.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp3t_subject_info, scan_name):
        name_list = archive.available_reapplyfix_names(hcp3t_subject_info)
        return scan_name in name_list

    def is_processing_complete(self, archive, hcp3t_subject_info, scan_name, verbose=False):

        # If the processed resource does not exist, then the process is certainly not complete.
        if not self.does_processed_resource_exist(archive, hcp3t_subject_info, scan_name):
            return False

        # If we reach here, then the processed resource at least exists.
        # Next we need to check to see if the expected files exist.

        # Build a list of expected files
        file_name_list = []

        results_dir = os.sep.join([archive.reapplyfix_dir_fullpath(hcp3t_subject_info, scan_name),
                                   str(hcp3t_subject_info.subject_id),
                                   'MNINonLinear',
                                   'Results'])
        scan_results_dir = os.sep.join([results_dir, scan_name])

        file_name_list.append(scan_results_dir + os.sep + scan_name + '_Atlas_MSMSulc_hp2000_clean.dtseries.nii')
        file_name_list.append(scan_results_dir + os.sep + scan_name + '_hp2000_clean.nii.gz')

        ica_dir = os.sep.join([scan_results_dir, scan_name + '_hp2000.ica'])

        file_name_list.append(ica_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii')
        file_name_list.append(ica_dir + os.sep + 'Atlas.nii.gz')

        return self.do_all_files_exist(file_name_list, verbose)

