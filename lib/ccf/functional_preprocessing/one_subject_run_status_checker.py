#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.functional_preprocessing.one_subject_job_submitter as one_subject_job_submitter
import ccf.one_subject_run_status_per_scan_checker as one_subject_run_status_per_scan_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker(one_subject_run_status_per_scan_checker.OneSubjectRunStatusPerScanChecker):

    @property
    def PIPELINE_NAME(self):
        return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()
    
