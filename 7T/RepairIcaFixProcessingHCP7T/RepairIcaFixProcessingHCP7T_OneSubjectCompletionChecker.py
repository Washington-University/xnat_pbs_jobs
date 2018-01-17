#!/usr/bin/env python3

# import of built-in modules
import os

# import of third-party modules

# import of local modules

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2018, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    print(os.path.basename(__file__) + ": " + msg)

    
class RepairIcaFixProcessingHCP7T_OneSubjectCompletionChecker:

    def __init__(self):
        super().__init__()

    def does_processed_resource_exist(self, archive, hcp7t_subject_info, scan_name):
        return archive.does_FIX_processed_exist(hcp7t_subject_info, scan_name)

    def is_processing_complete(self, archive, hcp7t_subject_info, scan_name):

        if not self.does_processed_resource_exist(archive, hcp7t_subject_info, scan_name):
            return False

        return archive.FIX_processing_repaired(hcp7t_subject_info, scan_name)
    
