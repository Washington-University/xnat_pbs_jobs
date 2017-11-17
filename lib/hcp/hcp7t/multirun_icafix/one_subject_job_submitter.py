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
import hcp.hcp7t.subject as hcp7t_subject
import utils.debug_utils as debug_utils
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overridden by log file configuration
module_logger.setLevel(logging.WARNING)

_order_list = ['RETCCW',
               'RETCW',
               'RETEXP',
               'RETCON',
               'RETBAR1',
               'RETBAR2']

def retinotopy_presentation_order_key(scan_name):
    """sort order key for sorting retinotopy scans by canonical order of task presentation"""
    scan_type_prefix, task_name, pe_dir = scan_name.split(sep='_')
    return _order_list.index(task_name)


def add_tesla_spec(scan_name):
    scan_type_prefix, task_name, pe_dir = scan_name.split(sep='_')
    return "_".join([scan_type_prefix, task_name, '7T', pe_dir])


def remove_scan_type(scan_name):
    scan_type_prefix, task_name, pe_dir = scan_name.split(sep='_')
    return "_".join([task_name, pe_dir])


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    @classmethod
    def MY_PIPELINE_NAME(cls):
        return 'MultiRunIcaFixHCP7T'
    
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
        #return 8
        return 1

    @property
    def structural_reference_project(self):
        return self._structural_reference_project

    @structural_reference_project.setter
    def structural_reference_project(self, value):
        self._structural_reference_project = value
    
    @property
    def check_data_program_path(self):
        """
        Path to program in the XNAT_PBS_JOBS that performs the actual check of result data.
        """
        name = self.xnat_pbs_jobs_home
        name += os.sep + '7T'
        name += os.sep + self.PIPELINE_NAME
        name += os.sep + self.PIPELINE_NAME
        name += '.XNAT_CHECK'
        return name
    
    @property
    def get_data_program_path(self):
        """Path to the program that can get the appropriate data for this processing"""
        name = self.xnat_pbs_jobs_home
        name += os.sep + '7T'
        name += os.sep + self.PIPELINE_NAME
        name += os.sep + self.PIPELINE_NAME
        name += '.XNAT_GET'
        return name

    @property
    def mark_running_status_program_path(self):
        """
        Path to program in XNAT_PBS_JOBS that performs the mark of running status.
        """
        name = self.xnat_pbs_jobs_home
        name += os.sep + '7T'
        name += os.sep + self.PIPELINE_NAME
        name += os.sep + self.PIPELINE_NAME
        name += '.XNAT_MARK_RUNNING_STATUS'
        return name
    
    def create_get_data_job_script(self):
        """Create the script to be submitted to perform the get data job"""
        module_logger.debug(debug_utils.get_name())

        script_name = self.get_data_job_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -q HCPput' + os.linesep)
        script.write('#PBS -o ' + self.working_directory_name + os.linesep)
        script.write('#PBS -e ' + self.working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write(self.get_data_program_path + ' \\' + os.linesep)
        script.write('  --project=' + self.project + ' \\' + os.linesep)
        script.write('  --subject=' + self.subject + ' \\' + os.linesep)
        script.write('  --ref-project=' + self.structural_reference_project + ' \\' + os.linesep)
        script.write('  --working-dir=' + self.working_directory_name + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)
    
    def create_process_data_job_script(self):
        module_logger.debug(debug_utils.get_name())

        # copy the .XNAT script to the working directory
        processing_script_source_name = self.xnat_pbs_jobs_home
        processing_script_source_name += os.sep + '7T'
        processing_script_source_name += os.sep + self.PIPELINE_NAME
        processing_script_source_name += os.sep + self.PIPELINE_NAME
        processing_script_source_name += '.XNAT_PROCESS'

        processing_script_dest_name = self.working_directory_name
        processing_script_dest_name += os.sep + self.PIPELINE_NAME
        processing_script_dest_name += '.XNAT_PROCESS'

        shutil.copy(processing_script_source_name, processing_script_dest_name)
        os.chmod(processing_script_dest_name, stat.S_IRWXU | stat.S_IRWXG)

        # write the process data job script (that calls the .XNAT script)

        subject_info = hcp7t_subject.Hcp7TSubjectInfo(project=self.project, subject_id=self.subject)

        script_name = self.process_data_job_script_name

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        walltime_limit_str = str(self.walltime_limit_hours) + ':00:00'
        mem_limit_str = str(self.mem_limit_gbs) + 'gb'
        vmem_limit_str = str(self.vmem_limit_gbs) + 'gb'
        
        resources_line = '#PBS -l nodes=' + str(self.WORK_NODE_COUNT)
        resources_line += ':ppn=' + str(self.WORK_PPN)
        resources_line += ',walltime=' + walltime_limit_str
        resources_line += ',mem=' + mem_limit_str
        resources_line += ',vmem=' + vmem_limit_str

        stdout_line = '#PBS -o ' + self.working_directory_name
        stderr_line = '#PBS -e ' + self.working_directory_name

        script_line   = processing_script_dest_name
        user_line     = '  --user='     + self.username
        password_line = '  --password=' + self.password
        server_line   = '  --server='   + str_utils.get_server_name(self.server)
        project_line  = '  --project='  + self.project
        subject_line  = '  --subject='  + self.subject
        session_line  = '  --session='  + self.subject + '_7T'

        avail_retinotopy_task_names = self.archive.available_retinotopy_preproc_names(subject_info)
        
        # sort available retinotopy task names into the order the
        # tasks were presented to the subject
        avail_retinotopy_task_names = sorted(avail_retinotopy_task_names,
                                             key=retinotopy_presentation_order_key)

        # add the tesla spec to each element of the group
        group_names = list(map(add_tesla_spec, avail_retinotopy_task_names))

        group_spec = '@'.join(group_names)
        group_line  = '  --group=' + group_spec
        
        concat_spec = '_'.join(list(map(remove_scan_type, avail_retinotopy_task_names)))
        concat_line = '  --concat-name=tfMRI_7T_' + concat_spec
        
        wdir_line  = '  --working-dir=' + self.working_directory_name
        setup_line = '  --setup-script=' + self.setup_file_name

        with open(script_name, 'w') as script:
            script.write(resources_line + os.linesep)
            script.write(stdout_line + os.linesep)
            script.write(stderr_line + os.linesep)
            script.write(os.linesep)

            script.write(script_line   + ' \\' + os.linesep)
            script.write(user_line     + ' \\' + os.linesep)
            script.write(password_line + ' \\' + os.linesep)
            script.write(server_line   + ' \\' + os.linesep)
            script.write(project_line  + ' \\' + os.linesep)
            script.write(subject_line  + ' \\' + os.linesep)
            script.write(session_line  + ' \\' + os.linesep)
            script.write(group_line    + ' \\' + os.linesep)
            script.write(concat_line   + ' \\' + os.linesep)
            script.write(wdir_line     + ' \\' + os.linesep)
            script.write(setup_line    + os.linesep)
            script.write(os.linesep)

            os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def mark_running_status(self, stage):
        module_logger.debug(debug_utils.get_name())

        if stage > ccf_processing_stage.ProcessingStage.PREPARE_SCRIPTS:
            mark_cmd = self._xnat_pbs_jobs_home
            mark_cmd += os.sep + '7T'
            mark_cmd += os.sep + self.PIPELINE_NAME
            mark_cmd += os.sep + self.PIPELINE_NAME
            mark_cmd += '.XNAT_MARK_RUNNING_STATUS' 
            mark_cmd += ' --project=' + self.project
            mark_cmd += ' --subject=' + self.subject
            mark_cmd += ' --classifier=' + '7T'

            if self.scan:
                mark_cmd += ' --scan=' + self.scan
            
            mark_cmd += ' --queued'

            completed_mark_cmd_process = subprocess.run(
                mark_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            print(completed_mark_cmd_process.stdout)
            
            return
