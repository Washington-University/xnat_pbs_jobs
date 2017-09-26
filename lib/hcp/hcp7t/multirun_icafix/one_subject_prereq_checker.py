#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_prereq_checker as one_subject_prereq_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectPrereqChecker(one_subject_prereq_checker.OneSubjectPrereqChecker):

    def __init__(self):
        super().__init__()

    def are_prereqs_met(self, archive, subject_info, verbose=False):

        retinotopy_unproc_dir_paths = archive.available_retinotopy_unproc_names(subject_info)
        retinotopy_preproc_dir_paths = archive.available_retinotopy_preproc_names(subject_info)

        if retinotopy_unproc_dir_paths == retinotopy_preproc_dir_paths:
            return True
        
        return False
