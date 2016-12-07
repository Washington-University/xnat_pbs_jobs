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
import utils.delete_resource as delete_resource
import utils.file_utils as file_utils
import utils.ordered_enum as ordered_enum
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
        # return "bedpostxHCP3T"
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
    def walltime_limit_hours(self):
        return self._walltime_limit_hours

    @walltime_limit_hours.setter
    def walltime_limit_hours(self, value):
        self._walltime_limit_hours = value
        logger.debug("walltime_limit_hours set to " + str(value))

    @property
    def vmem_limit_gbs(self):
        return self._vmem_limit_gbs

    @vmem_limit_gbs.setter
    def vmem_limit_gbs(self, value):
        self._vmem_limit_gbs = value
        logger.debug("vmem_limit_gbs set to " + str(value))

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
        return self._get_scripts_start_name() + '.XNAT_PBS_GET_DATA_job.sh'

    def _create_get_data_script(self):
        logger.debug("_create_get_data_script")

        script_name = self._get_data_script_name()
        
        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')
        
        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=4gb' + os.linesep)
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

    def _process_script_name(self):
        return self._get_scripts_start_name() + '.XNAT_PBS_PROCESS_DATA_job.sh'

    def _create_process_script(self):
        logger.debug("_create_process_script")

        script_name = self._process_script_name()

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        walltime_limit = str(self.walltime_limit_hours) + ':00:00'
        resources_line = '#PBS -l nodes=1:ppn=3:gpus=1,walltime=' + walltime_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -o ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep
        script_line += self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_PROCESS.sh'

        user_line = '  --user=' + self.username
        password_line = '  --password=' + self.password 
        server_line = '  --server=' + str_utils.get_server_name(self.server)
        project_line = '  --project=' + self.project
        subject_line = '  --subject=' + self.subject
        session_line = '  --session=' + self.session
        working_dir_line = '  --working-dir=' + self._working_directory_name
        workflow_line = '  --workflow-id=' + self._workflow_id



        setup_line = '  --setup-script=' + self.setup_script + 'ICI NEEDS TO BE PREFACED WITH DIRECTORY'



        
        script = open(script_name, 'w')
        file_utils.wl(script, resources_line)
        file_utils.wl(script, stdout_line)
        file_utils.wl(script, stderr_line)
        file_utils.wl(script, '')
        file_utils.wl(script, script_line + self._continue)
        file_utils.wl(script, user_line + self._continue)
        file_utils.wl(script, password_line + self._continue)
        file_utils.wl(script, server_line + self._continue)
        file_utils.wl(script, project_line + self._continue)
        file_utils.wl(script, subject_line + self._continue)
        file_utils.wl(script, session_line + self._continue)
        file_utils.wl(script, working_dir_line + self._continue)
        file_utils.wl(script, workflow_line + self._continue)
        file_utils.wl(script, setup_line)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

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

        # get JSESSION ID
        jsession_id = xnat_access.get_jsession_id(
            server='db.humanconnectome.org',
            username=self.username,
            password=self.password)
        logger.info("jsession_id: " + jsession_id)

        # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
        xnat_session_id = xnat_access.get_session_id(
            server='db.humanconnectome.org',
            username=self.username,
            password=self.password,
            project=self.project,
            subject=self.subject,
            session=self.session)
        logger.info("xnat_session_id: " + xnat_session_id)

        # get XNAT Workflow ID
        workflow_obj = xnat_access.Workflow(self.username, self.password,
                                            'https://db.humanconnectome.org', jsession_id)
        self._workflow_id = workflow_obj.create_workflow(xnat_session_id,
                                                         self.project,
                                                         self.PIPELINE_NAME,
                                                         'Queued')
        logger.info("workflow_id: " + self._workflow_id)

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

            # ici - create other scripts


        # submit the job to get the data
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



