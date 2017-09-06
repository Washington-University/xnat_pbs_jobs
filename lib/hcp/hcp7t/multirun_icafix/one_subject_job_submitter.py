#!/usr/bin/env python3

# import of built-in modules
import logging
import os
import shutil

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import utils.debug_utils as debug_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overridden by log file configuration
module_logger.setLevel(logging.WARNING)

class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "MultiRunIcaFixHCP7T"

    def create_work_script(self):
        module_logger.debug(debug_utils.get_name())

        processing_script_source_name = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        processing_script_source_name += self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_PROCESS'

        processing_script_dest_name = self.working_directory_name + os.sep
        processing_script_dest_name += self.PIPELINE_NAME + '.XNAT_PROCESS'

        shutil.copy(processing_script_source_name, processing_script_dest_name)
        os.chmod(processing_script_dest_name, stat.S_IRWXU | stat.S_IRWXG)

        
