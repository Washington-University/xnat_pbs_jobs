#!/usr/bin/env python3

# import of built-in modules
import contextlib
import logging
import os
import shutil
import stat
import subprocess

# import of third-party modules

# import of local modules
import ccf.one_subject_job_submitter as one_subject_job_submitter
import ccf.processing_stage as ccf_processing_stage
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
        return 'FunctionalPreprocessing'

    def __init__(self, archive, build_home):
        super().__init__(archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    def create_process_data_job_script(self):
        module_logger.debug(debug_utils.get_name())

        # copy the .XNAT_PROCESS script to the working directory
        processing_script_source_path = self.xnat_pbs_jobs_home
        processing_script_source_path += os.sep + self.PIPELINE_NAME
        processing_script_source_path += os.sep + self.PIPELINE_NAME
        processing_script_source_path += '.XNAT_PROCESS'

        processing_script_dest_path = self.working_directory_name
        processing_script_dest_path += os.sep + self.PIPELINE_NAME
        processing_script_dest_path += '.XNAT_PROCESS' 

        shutil.copy(processing_script_source_path, processing_script_dest_path)
        os.chmod(processing_script_dest_path, stat.S_IRWXU | stat.S_IRWXG)
       
        # write the process data job script (that calls the .XNAT_PROCESS script)

        subject_info = ccf_subject.SubjectInfo(self.project, self.subject,
                                               self.classifier, self.scan)

        script_name = self.process_data_job_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)



        with open(script_name, 'w') as script:
            script.write('hello there you fool' + os.linesep)



            
            os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)
            

    def output_resource_name(self):
        module_logger.debug(debug_utils.get_name())
        return self.output_resource_suffix

    def mark_running_status(self, stage):
        module_logger.debug(debug_utils.get_name())

        if stage > ccf_processing_stage.ProcessingStage.PREPARE_SCRIPTS:
            mark_cmd = self._xnat_pbs_jobs_home
            mark_cmd += os.sep + self.PIPELINE_NAME
            mark_cmd += os.sep + self.PIPELINE_NAME
            mark_cmd += '.XNAT_MARK_RUNNING_STATUS'
            mark_cmd += ' --project=' + self.project
            mark_cmd += ' --subject=' + self.subject
            mark_cmd += ' --classifier=' + self.classifier
            mark_cmd += ' --scan=' + self.scan
            mark_cmd += ' --queued'

            completed_mark_cmd_process = subprocess.run(
                mark_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            print(completed_mark_cmd_process.stdout)

            return
        
