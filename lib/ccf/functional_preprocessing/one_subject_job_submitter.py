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
import utils.str_utils as str_utils

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

    @property
    def WORK_NODE_COUNT(self):
        return 1

    @property
    def WORK_PPN(self):
        return 1
    
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

        walltime_limit_str = str(self.walltime_limit_hours) + ':00:00'
        vmem_limit_str = str(self.vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=' + str(self.WORK_NODE_COUNT)
        resources_line += ':ppn=' + str(self.WORK_PPN)
        resources_line += ',walltime=' + walltime_limit_str
        resources_line += ',mem=' + vmem_limit_str
        
        stdout_line = '#PBS -o ' + self.working_directory_name
        stderr_line = '#PBS -e ' + self.working_directory_name

        script_line      = processing_script_dest_path
        user_line        = '  --user=' + self.username
        password_line    = '  --password=' + self.password
        server_line      = '  --server=' + str_utils.get_server_name(self.server)
        project_line     = '  --project=' + self.project
        subject_line     = '  --subject=' + self.subject
        session_line     = '  --session=' + self.session
        scan_line        = '  --scan=' + self.scan
        session_classifier_line = '  --session-classifier=' + self.classifier
        dcmethod_line    = '  --dcmethod=TOPUP'
        topupconfig_line = '  --topupconfig=b02b0.cnf'
        gdcoeffs_line    = '  --gdcoeffs=Prisma_3T_coeff_AS82.grad'

        wdir_line  = '  --working-dir=' + self.working_directory_name
        setup_line = '  --setup-script=' + self.setup_file_name
        
        with open(script_name, 'w') as script:
            script.write(resources_line + os.linesep)
            script.write(stdout_line + os.linesep)
            script.write(stderr_line + os.linesep)
            script.write(os.linesep)
            script.write(script_line +      ' \\' + os.linesep)
            script.write(user_line +        ' \\' + os.linesep)
            script.write(password_line +    ' \\' + os.linesep)
            script.write(server_line +      ' \\' + os.linesep)
            script.write(project_line +     ' \\' + os.linesep)
            script.write(subject_line +     ' \\' + os.linesep)
            script.write(session_line +     ' \\' + os.linesep)
            script.write(scan_line +        ' \\' + os.linesep)
            script.write(session_classifier_line + ' \\' + os.linesep)
            script.write(dcmethod_line +    ' \\' + os.linesep)
            script.write(topupconfig_line + ' \\' + os.linesep)
            script.write(gdcoeffs_line +    ' \\' + os.linesep)
            script.write(wdir_line + ' \\' + os.linesep)
            script.write(setup_line + os.linesep)
            
            os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)
            
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
        
