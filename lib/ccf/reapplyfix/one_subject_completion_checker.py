#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_completion_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(ccf.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()
        self._reg_name = None

    @property
    def reg_name(self):
        return self._reg_name

    @reg_name.setter
    def reg_name(self, value):
        self._reg_name = value

    def does_processed_resource_exist(self, archive, subject_info, scan_name):
        name_list = archive.available_reapplyfix_names(subject_info, self.reg_name)
        return scan_name in name_list

    def is_processing_complete(self, archive, subject_info, scan_name, verbose=False):

        # If the processed resource does not exist, then the processing is certainly not complete.
        if not self.does_processed_resource_exist(archive, subject_info, scan_name):
            return False

        file_name_list = []

        results_dir = os.sep.join([archive.reapplyfix_dir_full_path(subject_info, scan_name, self.reg_name),
                                   str(subject_info.subject_id),
                                   'MNINonLinear',
                                   'Results'])
        scan_results_dir = os.sep.join([results_dir, scan_name])

        if self.reg_name is None:
            file_name_list.append(scan_results_dir + os.sep + scan_name + '_Atlas_hp2000_clean.dtseries.nii')
        elif self.reg_name.upper() == 'MSMALL':
            file_name_list.append(scan_results_dir + os.sep + scan_name + '_Atlas_MSMAll_hp2000_clean.dtseries.nii')
        else:
            raise NotImplementedError()

        file_name_list.append(scan_results_dir + os.sep + scan_name + '_hp2000_clean.nii.gz')

        ica_dir = os.sep.join([scan_results_dir, scan_name + '_hp2000.ica'])

        file_name_list.append(ica_dir + os.sep + 'Atlas_hp_preclean.dtseries.nii')
        file_name_list.append(ica_dir + os.sep + 'Atlas.nii.gz')

        return self.do_all_files_exist(fileName_list, verbose)
