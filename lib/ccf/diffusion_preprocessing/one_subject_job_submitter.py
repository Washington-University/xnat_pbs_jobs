#!/usr/bin/env python3

# import of built-in modules
import logging

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overidden by log file configuration
module_logger.setLevel(logging.WARNING)


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):
    
    @classmethod
    def MY_PIPELINE_NAME(cls):
        return 'DiffusionPreprocessing'

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    @property
    def WORK_NODE_COUNT(self):
        return 1

    @property
    def WORK_PPN(self):
        return 3

    @property
    def WORK_GPU_COUNT(self):
        return 1
    
    
