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

        struct_unproc_dir_names = archive.available_structural_unproc_names(subject_info)

        count_of_t1w_resources = 0
        count_of_t2w_resources = 0
        
        for name in struct_unproc_dir_names:
            if name.startswith('T1w'):
                count_of_t1w_resources += 1
            if name.startswith('T2w'):
                count_of_t2w_resources += 1
                
        
        # does at least 1 T1w unprocessed resource exist and
        # at least 1 T2w unprocessed resource exist
        return (count_of_t1w_resources > 0) and (count_of_t2w_resources > 0)

