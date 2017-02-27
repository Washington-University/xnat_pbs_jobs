#!/usr/bin/env python3

# import of built-in modules
import contextlib
import enum
import logging
import os
import stat
import subprocess
import time

# import of third party modules

# import of local modules
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.debug_utils as debug_utils
import utils.delete_resource as delete_resource
import utils.file_utils as file_utils
import utils.file_utils as futils
import utils.ordered_enum as ordered_enum
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create a module logger
logger = logging.getLogger(file_utils.get_logger_name(__file__))

@enum.unique
class ProcessingStage(ordered_enum.OrderedEnum):
    PREPARE_SCRIPTS = 0
    GET_DATA = 1
    PROCESS_DATA = 2
    CLEAN_DATA = 3
    PUT_DATA = 4


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, hcp3t_archive, build_home):
        super().__init__(hcp3t_archive, build_home)

    @property
    def _continue(self):
        return ' \\'

    @property
    def PIPELINE_NAME(self):
        return "ReApplyFix"

    @property 
    def username(self):
        return self._username

    @username.setter
    def username(self, value):
        self._username = value
        logger.debug(debug_utils.get_name() + ": set to: " + str(self._username))

    @property 
    def password(self):
        return self._password

    @password.setter
    def password(self, value):
        self._password = value

    @property
    def server(self):
        return self._server

    @server.setter
    def server(self, value):
        self._server = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._server))

    @property
    def setup_script(self):
        return self._setup_script

    @setup_script.setter
    def setup_script(self, value):
        self._setup_script = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._setup_script))

    @property
    def project(self):
        return self._project
    
    @project.setter
    def project(self, value):
        self._project = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._project))

    @property
    def subject(self):
        return self._subject

    @subject.setter
    def subject(self, value):
        self._subject = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._subject))

    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, value):
        self._session = value
        logger.debug(debug_utils.get_name() + ": session set to " + str(self._session))

    @property
    def scan(self):
        return self._scan

    @scan.setter
    def scan(self, value):
        self._scan = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._scan))
    
    @property
    def clean_output_resource_first(self):
        return self._clean_output_resource_first

    @clean_output_resource_first.setter
    def clean_output_resource_first(self, value):
        self._clean_output_resource_first = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._clean_output_resource_first))

    @property
    def put_server(self):
        return self._put_server

    @put_server.setter
    def put_server(self, value):
        self._put_server = value
        logger.debug(debug_utils.get_name() + ": set to " + str(self._put_server))

    @property
    def walltime_limit_hours(self):
        return self._walltime_limit_hours

    @walltime_limit_hours.setter
    def walltime_limit_hours(self, value):
        self._walltime_limit_hours = value
        logger.debug(debug_utils.get_name() + ": set to " + str(value))

    @property
    def vmem_limit_gbs(self):
        return self._vmem_limit_gbs

    @vmem_limit_gbs.setter
    def vmem_limit_gbs(self, value):
        self._vmem_limit_gbs = value
        logger.debug(debug_utils.get_name() + ": set to " + str(value))

    @property
    def reg_name(self):
        return self._reg_name

    @reg_name.setter
    def reg_name(self, value):
        self._reg_name = value
        logger.debug(debug_utils.get_name() + ": set to " + str(value))

    @property
    def output_resource_suffix(self):
        return self._output_resource_suffix

    @output_resource_suffix.setter
    def output_resource_suffix(self, value):
        self._output_resource_suffix = value
        logger.debug(debug_utils.get_name() + ": set to " + str(value))

    def _get_scripts_start_name(self):
        start_name = self._working_directory_name
        start_name += os.sep + self.subject
        start_name += '.' + self.PIPELINE_NAME
        start_name += '_' + self.scan
        start_name += '.' + self.project
        start_name += '.' + self.session

        return start_name
    
    def _get_data_script_name(self):
        logger.debug(debug_utils.get_name())
        return self._get_scripts_start_name() + '.XNAT_GET_DATA_job.sh'

    def _work_script_name(self):
        logger.debug(debug_utils.get_name())
        return self._get_scripts_start_name() + '.PROCESS_DATA_job.sh'

    def _clean_data_script_name(self):
        logger.debug(debug_utils.get_name())
        return self._get_scripts_start_name() + '.CLEAN_DATA_job.sh'

    def _starttime_file_name(self):
        logger.debug(debug_utils.get_name())
        starttime_file_name = self._working_directory_name
        starttime_file_name += os.path.sep
        starttime_file_name += self.PIPELINE_NAME
        starttime_file_name += '.starttime'

        return starttime_file_name

    def _put_data_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_PUT_DATA_job.sh'

    def _write_bash_header(self, script):

        bash_line = '#PBS -S /bin/bash'
        file_utils.wl(script, bash_line)
        file_utils.wl(script, '')

    def _create_get_data_script(self):
        logger.debug(debug_utils.get_name())

        script_name = self._get_data_script_name()
        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -q HCPput' + os.linesep)
        script.write('#PBS -o ' + self._working_directory_name + os.linesep)
        script.write('#PBS -e ' + self._working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write(self.xnat_pbs_jobs_home + os.sep + 
                     self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_GET.sh \\' + os.linesep)
        script.write('  --project=' + self.project + ' \\' + os.linesep)
        script.write('  --subject=' + self.subject + ' \\' + os.linesep)
        script.write('  --working-dir=' + self._working_directory_name + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_clean_data_script(self):
        logger.debug(debug_utils.get_name())

        script_name = self._clean_data_script_name()
        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')
        self._write_bash_header(script)
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -o ' + self._working_directory_name + os.linesep)
        script.write('#PBS -e ' + self._working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write('echo "Newly created or modified files:"' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject +
                     ' -type f -newer ' + self._starttime_file_name() + os.linesep)
        script.write(os.linesep)
        script.write('echo "Removing NOT newly created or modified files."' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject +
                     ' -not -newer ' + self._starttime_file_name() + ' -delete')
        script.write(os.linesep)
        script.write('echo "Removing any XNAT catalog files still around."' + os.linesep)
        script.write('find ' + self._working_directory_name +
                     ' -name "*_catalog.xml" -delete')
        script.write(os.linesep)
        script.write('echo "Remaining files:"' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_work_script(self):
        logger.debug(debug_utils.get_name())

        script_name = self._work_script_name()
        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        walltime_limit = str(self.walltime_limit_hours) + ':00:00'
        vmem_limit = str(self.vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=1:ppn=1,walltime=' + walltime_limit + ',vmem=' + vmem_limit
        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT.sh'

        user_line = '  --user=' + self.username
        password_line = '  --password=' + self.password
        server_line = '  --server=' + str_utils.get_server_name(self.server)
        project_line = '  --project=' + self.project
        subject_line = '  --subject=' + self.subject
        session_line = '  --session=' + self.session
        scan_line = '  --scan=' + self.scan
        wdir_line = '  --working-dir=' + self._working_directory_name
        setup_line = '  --setup-script=' + self.xnat_pbs_jobs_home + os.sep + self.PIPELINE_NAME + os.sep + self.setup_script
        reg_name_line = '  --reg-name=' + self.reg_name

        work_script = open(self._work_script_name(), 'w')

        futils.wl(work_script, resources_line)
        futils.wl(work_script, stdout_line)
        futils.wl(work_script, stderr_line)
        futils.wl(work_script, '')
        futils.wl(work_script, script_line + self._continue)
        futils.wl(work_script, user_line + self._continue)
        futils.wl(work_script, password_line + self._continue)
        futils.wl(work_script, server_line + self._continue)
        futils.wl(work_script, project_line + self._continue)
        futils.wl(work_script, subject_line + self._continue)
        futils.wl(work_script, session_line + self._continue)
        futils.wl(work_script, scan_line + self._continue)
        futils.wl(work_script, wdir_line + self._continue)
        if self.reg_name != 'MSMSulc':
            futils.wl(work_script, reg_name_line + self._continue)
        futils.wl(work_script, setup_line)

        work_script.close()
        os.chmod(self._work_script_name(), stat.S_IRWXU | stat.S_IRWXG)

    def submit_jobs(self, processing_stage=ProcessingStage.PUT_DATA):
        logger.debug(debug_utils.get_name() + ": processing_stage: " + str(processing_stage))

        logger.info("-----")
        logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
        logger.info("  Project: " + self.project)
        logger.info("  Subject: " + self.subject)
        logger.info("  Session: " + self.session)
        logger.info("     Scan: " + self.scan)
        logger.info("    Stage: " + str(processing_stage))

        # make sure working directories do not have the same name based on 
        # the same start time by sleeping a few seconds
        time.sleep(5)

        # build the working directory name
        self._working_directory_name = \
            self.build_working_directory_name(self.project, self.PIPELINE_NAME, self.subject, self.scan)
        logger.info("Making working directory: " + self._working_directory_name)
        os.makedirs(name=self._working_directory_name)

        # determine output resource name
        self._output_resource_name = self.scan + "_" + self.output_resource_suffix

        # clean output resource if requested
        if self.clean_output_resource_first:
            logger.info("Deleting resource: " + self._output_resource_name + " for:")
            logger.info("  project: " + self.project)
            logger.info("  subject: " + self.subject)
            logger.info("  session: " + self.session)

            delete_resource.delete_resource(
                self.username, self.password,
                str_utils.get_server_name(self.server),
                self.project, self.subject, self.session,
                self._output_resource_name)

        # create scripts for various stages of processing
        if processing_stage >= ProcessingStage.PREPARE_SCRIPTS:
            self._create_get_data_script()
            self._create_work_script()
            self._create_clean_data_script()

            put_script_name = self._put_data_script_name()
            self.create_put_script(put_script_name,
                                   self.username, self.password, self.put_server,
                                   self.project, self.subject, self.session,
                                   self._working_directory_name,
                                   self._output_resource_name,
                                   self.PIPELINE_NAME, leave_subject_id_level=True)

        # Submit the job to get the data
        if processing_stage >= ProcessingStage.GET_DATA:

            get_data_submit_cmd = 'qsub ' + self._get_data_script_name()
            logger.info("get_data_submit_cmd: " + get_data_submit_cmd)

            completed_get_data_submit_process = subprocess.run(
                get_data_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            get_data_job_no = str_utils.remove_ending_new_lines(completed_get_data_submit_process.stdout)
            logger.info("get_data_job_no: " + get_data_job_no)

        else:
            logger.info("Get data job not submitted")

        # Submit the job to process the data (do the work)
        if processing_stage >= ProcessingStage.PROCESS_DATA:

            work_submit_cmd = 'qsub -W depend=afterok:' + get_data_job_no + ' ' + self._work_script_name()
            logger.info("work_submit_cmd: " + work_submit_cmd)

            completed_work_submit_process = subprocess.run(
                work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
            logger.info("work_job_no: " + work_job_no)

        else:
            logger.info("Process data job not submitted")

        # Submit job to clean the data                                                                                                                                                              
        if processing_stage >= ProcessingStage.CLEAN_DATA:

            clean_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + self._clean_data_script_name()
            logger.info("clean_submit_cmd: " + clean_submit_cmd)

            completed_clean_submit_process = subprocess.run(
                clean_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            clean_job_no = str_utils.remove_ending_new_lines(completed_clean_submit_process.stdout)
            logger.info("clean_job_no: " + clean_job_no)

        else:
            logger.info("Clean data job not submitted")

        # Submit job to put the resulting data in the DB                                                                                                                                            
        if processing_stage >= ProcessingStage.PUT_DATA:

            put_submit_cmd = 'qsub -W depend=afterok:' + clean_job_no + ' ' + put_script_name
            logger.info("put_submit_cmd: " + put_submit_cmd)
            
            completed_put_submit_process = subprocess.run(
                put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            logger.info("put_job_no: " + put_job_no)
            
        else:
            logger.info("Put data job not submitted")
