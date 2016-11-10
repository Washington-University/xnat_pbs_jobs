#!/usr/bin/env python3

"""
hcp.hcp7t.resting_state_stats.one_subject_job_submitter.py:
Submits jobs to perform HCP 7T Resting State Stats processing for one HCP 7T subject.
"""

# import of built-in modules
import logging
import os
import time


# import of third party modules
pass


# import of local modules
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.file_utils as file_utils


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


# create a module logger
logger = logging.getLogger(file_utils.get_logger_name(__file__))


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, hcp7t_archive, build_home):
        super().__init__(hcp7t_archive, build_home)
        self._username = None
        self._password = None
        self._server = None
        self._project = None
        self._subject = None
        self._session = None
        self._structural_reference_project = None
        self._structural_reference_session = None
        self._walltime_limit_hours = None
        self._vmem_limit_gbs = None
        self._setup_script = None
        self._clean_output_resource_first = None
        self._put_server = None
        logger.debug("__init__")


    @property
    def PIPELINE_NAME(self):
        return "RestingStateStatsHCP7T"

    
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
    def structural_reference_project(self):
        return self._structural_reference_project

    
    @structural_reference_project.setter
    def structural_reference_project(self, value):
        self._structural_reference_project = value
        logger.debug("structural_reference_project set to " + str(value))


    @property
    def structural_reference_session(self):
        return self._structural_reference_session

    
    @structural_reference_session.setter
    def structural_reference_session(self, value):
        self._structural_reference_session = value
        logger.debug("structural_reference_session set to " + str(value))


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
    def setup_script(self):
        return self._setup_script

    
    @setup_script.setter
    def setup_script(self, value):
        self._setup_script = value
        logger.debug("setup_script set to " + str(value))


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


    def validate_parameters(self):
        valid_configuration = True

        if not self.username:
            valid_configuration = False
            logger.info("Before submitting jobs: username value must be set")

        if not self.password:
            valid_configuration = False
            logger.info("Before submitting jobs: password value must be set")

        if not self.server:
            valid_configuration = False
            logger.info("Before submitting jobs: server value must be set")

        if not self.project:
            valid_configuration = False
            logger.info("Before submitting jobs: project value must be set")

        if not self.subject:
            valid_configuration = False
            logger.info("Before submitting jobs: subject value must be set")

        if not self.session:
            valid_configuration = False
            logger.info("Before submitting jobs: session value must be set")

        if not self.structural_reference_project:
            valid_configuration = False
            logger.info("Before submitting jobs: structural_reference_project value must be set")

        if not self.structural_reference_session:
            valid_configuration = False
            logger.info("Before submitting jobs: structural_reference_session value must be set")
                      
        if not self.walltime_limit_hours:
            valid_configuration = False
            logger.info("Before submitting jobs: walltime_limit_hours value must be set")

        if not self.vmem_limit_gbs:
            valid_configuration = False
            logger.info("Before submitting jobs: vmem_limit_gbs value must be set")

        if not self.setup_script:
            valid_configuration = False
            logger.info("Before submitting jobs: setup_script value must be set")

        if self.clean_output_resource_first == None:
            valid_configuration = False
            logger.info("Before submitting jobs: clean_output_resource_first value must be set")

        if not self.put_server:
            valid_configuration = False
            logger.info("Before submitting jobs: put_server value must be set")

        return valid_configuration


    def submit_jobs(self):
        logger.debug("submit_jobs")

        if self.validate_parameters():

            logger.info("")
            logger.info("--------------------------------------------------")
            logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
            logger.info("  Project: " + self.project)
            logger.info("  Subject: " + self.subject)
            logger.info("  Session: " + self.session)
            logger.info("--------------------------------------------------")

            # make sure working directories do not have the same name based on
            # the same start time by sleeping a few seconds
            time.sleep(5)

            # build the working directory name
            self._working_directory_name = self.build_working_directory_name(self.project, self.PIPELINE_NAME, self.subject)
            logger.info("Making working directory: " + self._working_directory_name)
            os.makedirs(name=self._working_directory_name)



            ici -- to do 


            




        else:
            logger.info("Unable to submit jobs")
