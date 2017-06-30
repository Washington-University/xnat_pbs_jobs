#!/usr/bin/env python3

# import of built-in modules
import contextlib
import datetime
import enum
import logging
import os
import stat
import subprocess
import time

# import of third party modules

# import of local modules
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.delete_resource as delete_resource
import utils.file_utils as file_utils
import utils.ordered_enum as ordered_enum
import utils.os_utils as os_utils
import utils.str_utils as str_utils
import xnat.xnat_access as xnat_access

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
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
        return "bedpostx"

    @property
    def username(self):
        return self._username

    @username.setter
    def username(self, value):
        self._username = value
        logger.debug("username set to " + str(value))

    @property
    def password(self):
        return self._password

    @password.setter
    def password(self, value):
        self._password = value
        logger.debug("password set to " + str(value))

    @property
    def server(self):
        return self._server

    @server.setter
    def server(self, value):
        self._server = value
        logger.debug("server set to " + str(value))

    @property
    def project(self):
        return self._project

    @project.setter
    def project(self, value):
        self._project = value
        logger.debug("project set to " + str(value))

    @property
    def subject(self):
        return self._subject

    @subject.setter
    def subject(self, value):
        self._subject = value
        logger.debug("subject set to " + str(value))

    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, value):
        self._session = value
        logger.debug("session set to " + str(value))

    @property
    def clean_output_resource_first(self):
        return self._clean_output_resource_first

    @clean_output_resource_first.setter
    def clean_output_resource_first(self, value):
        self._clean_output_resource_first = value
        logger.debug("clean_output_resource_first set to " + str(value))

    @property
    def put_server(self):
        return self._put_server

    @put_server.setter
    def put_server(self, value):
        self._put_server = value
        logger.debug("put_server set to " + str(value))

    @property
    def setup_script(self):
        return self._setup_script

    @setup_script.setter
    def setup_script(self, value):
        self._setup_script = value
        logger.debug("setup_script set to " + str(value))

    def _get_scripts_start_name(self):
        start_name = self._working_directory_name
        start_name += os.sep + self.subject
        start_name += '.' + self.PIPELINE_NAME
        start_name += '.' + self.project
        start_name += '.' + self.session

        return start_name

    def _get_data_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_GET_DATA_job.sh'

    def _clean_data_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_PBS_CLEAN_DATA_job.sh'

    def _create_get_data_script(self):
        logger.debug("_create_get_data_script")

        script_name = self._get_data_script_name()

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)

        script.write(self.xnat_pbs_jobs_home + os.sep +
                     self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_GET.sh \\' + os.linesep)
        script.write('  --project=' + self.project + ' \\' + os.linesep)
        script.write('  --subject=' + self.subject + ' \\' + os.linesep)
        script.write('  --working-dir=' + self._working_directory_name + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _process_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_PBS_PROCESS_DATA_job.sh'

    def _write_bash_header(self, script):

        # bash_line = '#PBS -S /bin/bash'
        bash_line = '#!/bin/bash'

        file_utils.wl(script, bash_line)
        file_utils.wl(script, '')

    def _write_doc_header(self, script):

        file_utils.wl(script, '')
        file_utils.wl(script, "# Copyright (C) " + str(datetime.datetime.now().year) + " The Human Connectome Project")
        file_utils.wl(script, "#")
        file_utils.wl(script, "# This file was autogenerated to run the " + self.PIPELINE_NAME + " pipeline")
        file_utils.wl(script, "# for subject: " + self.subject)
        file_utils.wl(script, '')

    def _write_env_setup(self, script):

        setup_file = open(self.setup_script, 'r')

        for line in setup_file:
            script.write(line)

        file_utils.wl(script, '')
        setup_file.close()

    def _write_host_id_section(self, script):
        file_utils.wl(script, 'echo "Job started on `hostname` at `date`"')
        file_utils.wl(script, '')

    def _write_platform_info_section(self, script):
        file_utils.wl(script, 'echo "----- Platform Information: Begin -----"')
        file_utils.wl(script, 'uname -a')
        file_utils.wl(script, 'echo "----- Platform Information: End -----"')
        file_utils.wl(script, '')

    def _starttime_file_name(self):
        return self._working_directory_name + os.sep + self.PIPELINE_NAME + '.starttime'

    def _write_rm_old_starttime_file_section(self, script):
        file_utils.wl(script, 'echo "Create a start time file"')
        file_utils.wl(script, 'start_time_file=' + self._starttime_file_name())
        file_utils.wl(script, 'if [ -e "${start_time_file}" ]; then')
        file_utils.wl(script, '    echo "Removing old ${start_time_file}"')
        file_utils.wl(script, '    rm -f ${start_time_file}')
        file_utils.wl(script, 'fi')
        file_utils.wl(script, '')

    # def _write_setup_for_epd_python_section(self, script):
    #     scripts_home = os.getenv('SCRIPTS_HOME')
    #     if not scripts_home:
    #         raise RuntimeError("Environment variable SCRIPTS_HOME must be set")

    #     file_utils.wl(script, 'echo "Setting up to use EPD Python 2"')
    #     file_utils.wl(script, 'source ' + scripts_home + os.sep + 'epd-python_setup.sh')
    #     file_utils.wl(script, '')

    # def _write_setup_for_xnat_workflow_section(self, script):
    #     xnat_utils_home = os.getenv('XNAT_UTILS_HOME')
    #     if not xnat_utils_home:
    #         raise RuntimeError("Environment variable XNAT_UTILS_HOME must be set")

    #     file_utils.wl(script, 'echo "Setting up to use XNAT workflow utilities"')
    #     file_utils.wl(script, 'source ' + xnat_utils_home + os.sep + 'xnat_workflow_utilities.sh')
    #     file_utils.wl(script, '')

    def _write_sleep_section(self, script):
        file_utils.wl(script, 'echo "Sleep for 1 minute"')
        file_utils.wl(script, 'sleep 1m || die')
        file_utils.wl(script, '')

    def _write_die_function(self, script):
        file_utils.wl(script, 'die()')
        file_utils.wl(script, '{')
        # file_utils.wl(script, '    xnat_workflow_fail ' + str_utils.get_server_name(self.server) 
        #               + ' ' + self.username + ' ' + self.password + ' ' + self._workflow_id)
        file_utils.wl(script, '    exit 1')
        file_utils.wl(script, '}')
        file_utils.wl(script, '')

    def _write_starttime_creation_section(self, script):
        file_utils.wl(script, 'echo "Creating start time file: ${start_time_file}"')
        file_utils.wl(script, 'touch ${start_time_file} || die')
        file_utils.wl(script, 'ls -l ${start_time_file}')
        file_utils.wl(script, '')

    # def _write_workflow_show_section(self, script):
    #     file_utils.wl(script, 'xnat_workflow_show ' + str_utils.get_server_name(self.server)
    #                   + ' ' + self.username + ' ' + self.password + ' ' + self._workflow_id)
    #     file_utils.wl(script, '')

    def _write_bedpostx_call(self, script):
        bedpostx_call_line = '${FSLDIR}/bin/bedpostx_gpu.tbb' + ' '
        bedpostx_call_line += self._working_directory_name + os.sep 
        bedpostx_call_line += self.subject + os.sep
        bedpostx_call_line += 'T1w' + os.sep + 'Diffusion' + ' '
        bedpostx_call_line += '-n 3 -b 3000 -model 3 -g --rician'

        file_utils.wl(script, 'echo "Calling bedpostx_gpu"')
        file_utils.wl(script, bedpostx_call_line)
        file_utils.wl(script, '')

    def _write_process_invocation(self, script):

        # file_utils.wl(script, 'PIPELINE_NAME=' + self.PIPELINE_NAME)
        self._write_die_function(script)
        # self._write_setup_for_epd_python_section(script)
        # self._write_setup_for_xnat_workflow_section(script)
        self._write_host_id_section(script)
        self._write_platform_info_section(script)
        self._write_rm_old_starttime_file_section(script)
        self._write_sleep_section(script)
        self._write_starttime_creation_section(script)
        self._write_sleep_section(script)
        # self._write_workflow_show_section(script)
        self._write_bedpostx_call(script)

    def _create_process_script(self):
        logger.debug("_create_process_script")

        script_name = self._process_script_name()

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        self._write_bash_header(script)
        self._write_doc_header(script)
        self._write_env_setup(script)
        self._write_process_invocation(script)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_clean_data_script(self):
        logger.debug("_create_clean_data_script")

        script_name = self._clean_data_script_name()

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
        script.write('#PBS -o ' + self._working_directory_name + os.linesep)
        script.write('#PBS -e ' + self._working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write('echo "Newly created or modified files:"' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject + 
                     ' -type f -newer ' + self._starttime_file_name() + os.linesep)
        script.write(os.linesep)
        script.write('echo "The following files are being removed."' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject +
                     ' -not -newer ' + self._starttime_file_name() + ' -print -delete' + os.linesep)

        script.write(os.linesep)
        script.write('exit 0')

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _put_data_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_PBS_PUT_DATA_job.sh'

    def submit_jobs(self, processing_stage=ProcessingStage.PUT_DATA):
        logger.debug("submit_jobs: processing_stage: " + str(processing_stage))

        logger.info("----------")
        logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
        logger.info(" Project: " + self.project)
        logger.info(" Subject: " + self.subject)
        logger.info(" Session: " + self.session)
        logger.info("   Stage: " + str(processing_stage))
        logger.info("----------")

        # make sure working directories do not have the same name based on
        # the same start time by sleeping a few seconds
        time.sleep(5)

        # build the working directory name
        self._working_directory_name = \
            self.build_working_directory_name(self.project, self.PIPELINE_NAME, self.subject)
        logger.info("Making working directory: " + self._working_directory_name)
        os.makedirs(name=self._working_directory_name)

        # # get JSESSION ID
        # jsession_id = xnat_access.get_jsession_id(
        #     server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
        #     username=self.username,
        #     password=self.password)
        # logger.info("jsession_id: " + jsession_id)

        # # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
        # xnat_session_id = xnat_access.get_session_id(
        #     server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
        #     username=self.username,
        #     password=self.password,
        #     project=self.project,
        #     subject=self.subject,
        #     session=self.session)
        # logger.info("xnat_session_id: " + xnat_session_id)

        # # get XNAT Workflow ID
        # workflow_obj = xnat_access.Workflow(self.username, self.password,
        #                                     os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
        #                                     jsession_id)
        # self._workflow_id = workflow_obj.create_workflow(xnat_session_id,
        #                                                  self.project,
        #                                                  self.PIPELINE_NAME,
        #                                                  'Queued')
        # logger.info("workflow_id: " + self._workflow_id)

        # determine output resource name
        self._output_resource_name = "Diffusion_bedpostx"

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
            # create script to get data
            self._create_get_data_script()
            self._create_process_script()
            self._create_clean_data_script()

            put_script_name = self._put_data_script_name()
            self.create_put_script(put_script_name,
                                   self.username, self.password, self.put_server,
                                   self.project, self.subject, self.session,
                                   self._working_directory_name,
                                   self._output_resource_name,
                                   self.PIPELINE_NAME)

        # run the script to get the data
        if processing_stage >= ProcessingStage.GET_DATA:

            stdout_file = open(self._get_data_script_name() + '.stdout', 'w')
            stderr_file = open(self._get_data_script_name() + '.stderr', 'w')

            logger.info("Running get data script")
            logger.info("  stdout: " + stdout_file.name)
            logger.info("  stderr: " + stderr_file.name)

            proc = subprocess.Popen(['bash', self._get_data_script_name()], 
                                    stdout=stdout_file, stderr=stderr_file)
            proc.communicate()

            logger.info("  return code: " + str(proc.returncode))

            stdout_file.close()
            stderr_file.close()

            if proc.returncode != 0:
                raise RuntimeError("get data script ended with non-zero return code")

        else:
            logger.info("Get data script not run")

        # run the script to submit processing jobs 
        if processing_stage >= ProcessingStage.PROCESS_DATA:

            stdout_file = open(self._process_script_name() + '.stdout', 'w')
            stderr_file = open(self._process_script_name() + '.stderr', 'w')

            logger.info("Running script to submit processing jobs")
            logger.info("  stdout: " + stdout_file.name)
            logger.info("  stderr: " + stderr_file.name)

            proc = subprocess.Popen(['bash', self._process_script_name()],
                                    stdout=stdout_file, stderr=stderr_file)
            proc.communicate()
            
            stdout_file.close()
            stderr_file.close()

            logger.info("  return code: " + str(proc.returncode))

            if proc.returncode != 0:
                raise RuntimeError("script to submit processing jobs ended with non-zero return code")

        else:
            logger.info("process data job not submitted")

        # submit the job to clean the data
        if processing_stage >= ProcessingStage.CLEAN_DATA:

            # figure out what the job id number is for the bedpostx postprocessing job 
            postproc_file_name = self._working_directory_name + os.sep 
            postproc_file_name += self.subject + os.sep
            postproc_file_name += 'T1w' + os.sep
            postproc_file_name += 'Diffusion.bedpostX' + os.sep
            postproc_file_name += 'logs' + os.sep
            postproc_file_name += 'postproc_ID'
            logger.info("Post-processing job ID file name: " + postproc_file_name)

            f = open(postproc_file_name, 'r')
            id_str = f.readline().rstrip()
            logger.info("Post-processing job ID: " + id_str)
            f.close()

            clean_submit_cmd = 'qsub -W depend=afterok:' + id_str + ' ' + self._clean_data_script_name()
            logger.info("clean_submit_cmd: " + clean_submit_cmd)

            completed_clean_submit_process = subprocess.run(
                clean_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            clean_job_no = str_utils.remove_ending_new_lines(completed_clean_submit_process.stdout)
            logger.info("clean_job_no: " + clean_job_no)

        else:
            logger.info("Clean data job not submitted")

        # submit the job to put the resulting data in the DB
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
