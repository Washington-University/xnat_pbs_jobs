#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_prereq_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectPrereqChecker(ccf.one_subject_prereq_checker.OneSubjectPrereqChecker):

    def __init__(self):
        super().__init__()

    def are_prereqs_met(self, archive, subject_info, verbose=False):

        struct_preproc_dir_paths = archive.available_structural_preproc_dir_full_paths(subject_info)
        if len(struct_preproc_dir_paths) <= 0:
            return False

        diffusion_unproc_dir_paths = archive.available_diffusion_unproc_dir_full_paths(subject_info)
        if len(diffusion_unproc_dir_paths) <= 0:
            return False

        return True
    
