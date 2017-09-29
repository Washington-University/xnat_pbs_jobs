#!/usr/bin/env python3

# import of built-in modules
import logging

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.batch_submitter as batch_submitter
import ccf.structural_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
# Note: The following can be overridden by file configuration
module_logger.setLevel(logging.WARNING)


class BatchSubmitter(batch_submitter.BatchSubmitter):

    def __init__(self):
        super().__init__(ccf_archive.CcfArchive())

    def submit_jobs(self, username, password, subject_list, config):

        # submit jobs for the listed subject scans
        for subject in subject_list:

            run_status_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()
            if run_status_checker.get_queued_or_running(subject):
                print("-----")
                print("\t NOT SUBMITTING JOBS FOR"
