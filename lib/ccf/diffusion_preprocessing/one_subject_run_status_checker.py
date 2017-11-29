#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.diffusion_preprocessing.one_subject_job_submitter as one_subject_job_submitter

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker(one_subject_run_status_checker.OneSubjectRunStatusChecker):
    """Determine run status of CCF Diffusion Preprocessing."""

    @property
    def PIPELINE_NAME(self):
        """Return the name of the pipeline for which this status checker is used."""
        return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()
