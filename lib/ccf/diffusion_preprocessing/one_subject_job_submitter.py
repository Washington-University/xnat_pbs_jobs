#!/usr/bin/env python3
"""ccf.diffusion_preprocessing.one_subject_job_submitter

Submit jobs for running CCF Diffusion Preprocessing pipeline on one subject.

"""

# import of built-in modules
import contextlib
import logging
import os
import shutil
import stat

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import ccf.subject as ccf_subject
import utils.debug_utils as debug_utils

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

    def create_process_data_job_script(self):
        """Create the script to be submitted to perform the processing of the retrieved data."""
        module_logger.debug(debug_utils.get_name())

        # copy the PreEddy, Eddy, and PostEddy .XNAT_PROCESS scripts to the working directory
        for phase in ['PreEddy', 'Eddy', 'PostEddy']:

            processing_script_source_path = self.xnat_pbs_jobs_home
            processing_script_source_path += os.sep + self.PIPELINE_NAME
            processing_script_source_path += os.sep + self.PIPELINE_NAME + '_' + phase
            processing_script_source_path += '.XNAT_PROCESS'

            processing_script_dest_path = self.working_directory_name
            processing_script_dest_path += os.sep + self.PIPELINE_NAME + '_' + phase
            processing_script_dest_path += '.XNAT_PROCESS'

            shutil.copy(processing_script_source_path, processing_script_dest_path)
            os.chmod(processing_script_dest_path, stat.S_IRWXU | stat.S_IRWXG)


        # write the PBS job scripts (that call the .XNAT_PROCESS scripts)

        subject_info = ccf_subject.SubjectInfo(self.project, self.subject, self.classifier)

        # first the PreEddy PBS job script
        script_name = self.scripts_start_name + '.PreEddy.PROCESS_DATA_job.sh'

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        resources_line = '#PBS -l nodes=1:ppn=1,walltime=10:00:00,vmem=16gb'
        stdout_line = '#PBS -o ' + self.working_directory_name
        stderr_line = '#PBS -e ' + self.working_directory_name

        script_line = self.working_directory_name + os.sep + self.PIPELINE_NAME
        script_line += '_' + 'PreEddy' + '.XNAT_PROCESS'

        user_line = '  --user=' + self.username
        password_line = '  --password=' + self.password


        with open(script_name, 'w') as script:
            script.write(resources_line + os.linesep)
            script.write(stdout_line + os.linesep)
            script.write(stderr_line + os.linesep)
            script.write(os.linesep)
            script.write(script_line + '\\' + os.linesep)
            script.write(user_line + '\\' + os.linesep)
            script.write(password_line + '\\' + os.linesep)


        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)




