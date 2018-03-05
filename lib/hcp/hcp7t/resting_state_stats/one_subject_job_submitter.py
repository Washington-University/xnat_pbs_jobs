#!/usr/bin/env python3

"""
hcp.hcp7t.resting_state_stats.one_subject_job_submitter.py:
Submits jobs to perform HCP 7T Resting State Stats processing for one HCP 7T subject.
"""

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
import hcp.hcp7t.resting_state_stats.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp7t.subject as hcp7t_subject
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.delete_resource as delete_resource
import utils.file_utils as file_utils
import utils.file_utils as futils
import utils.ordered_enum as ordered_enum
import utils.os_utils as os_utils
import utils.str_utils as str_utils
import xnat.xnat_access as xnat_access

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016-2018, The Human Connectome Project"
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
        


def is_complete(archive, hcp7t_subject_info, scan_name):

    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
    return completion_checker.is_processing_complete(archive, hcp7t_subject_info, scan_name)
    
    
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

    @property
    def _continue(self):
        return ' \\'

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

        if self.clean_output_resource_first is None:
            valid_configuration = False
            logger.info("Before submitting jobs: clean_output_resource_first value must be set")

        if not self.put_server:
            valid_configuration = False
            logger.info("Before submitting jobs: put_server value must be set")

        return valid_configuration

    def _get_scripts_start_name(self, scan):
        script_file_start_name = self._working_directory_name
        script_file_start_name += os.sep + self.subject
        script_file_start_name += '.' + self.PIPELINE_NAME + '_' + scan
        script_file_start_name += '.' + self.project
        script_file_start_name += '.' + self.session

        return script_file_start_name

    def _work_script_name(self, scan):
        return self._get_scripts_start_name(scan) + '.XNAT_PBS_PROCESS_DATA_job.sh'

    def _get_data_script_name(self, scan):
        return self._get_scripts_start_name(scan) + '.XNAT_PBS_GET_DATA_job.sh'

    def _put_data_script_name(self, scan):
        return self._get_scripts_start_name(scan) + '.XNAT_PBS_PUT_DATA_job.sh'

    def _clean_data_script_name(self, scan):
        return self._get_scripts_start_name(scan) + '.XNAT_PBS_CLEAN_DATA_job.sh'

    def _starttime_file_name(self):
        starttime_file_name = self._working_directory_name 
        starttime_file_name += os.path.sep
        starttime_file_name += self.PIPELINE_NAME 
        starttime_file_name += '.starttime'
        
        return starttime_file_name

    def _create_get_data_script(self, scan):
        logger.debug("_create_get_data_script")

        script_name = self._get_data_script_name(scan)

        with contextlib.suppress(FileNotFoundError):
            os.remove(script_name)

        script = open(script_name, 'w')

        script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
        script.write('#PBS -o ' + self._working_directory_name + os.linesep)
        script.write('#PBS -e ' + self._working_directory_name + os.linesep)
        script.write(os.linesep)
        script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep +
                     self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT_GET.sh \\' + os.linesep)
        script.write('  --project=' + self.project + ' \\' + os.linesep)
        script.write('  --subject=' + self.subject + ' \\' + os.linesep)
        script.write('  --structural-reference-project=' + self.structural_reference_project + ' \\' + os.linesep)
        script.write('  --working-dir=' + self._working_directory_name + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_clean_data_script(self, scan):
        logger.debug("_create_clean_data_script")
        
        script_name = self._clean_data_script_name(scan)
        
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
                     ' -not -newer ' + self._starttime_file_name() + ' -print -delete')
        script.write(os.linesep)
        script.write('echo "Remaining files:"' + os.linesep)
        script.write('find ' + self._working_directory_name + os.path.sep + self.subject + os.linesep)

        script.close()
        os.chmod(script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_work_script(self, scan):
        logger.debug("_create_work_script - scan: " + scan)

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._work_script_name(scan))

        walltime_limit = str(self.walltime_limit_hours) + ':00:00'
        vmem_limit = str(self.vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=1:ppn=1,walltime=' + walltime_limit
        resources_line += ',vmem=' + vmem_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += self.PIPELINE_NAME + os.sep + self.PIPELINE_NAME + '.XNAT.sh'

        user_line = '  --user=' + self.username
        password_line = '  --password=' + self.password
        server_line = '  --server=' + str_utils.get_server_name(self.server)
        project_line = '  --project=' + self.project
        subject_line = '  --subject=' + self.subject
        session_line = '  --session=' + self.session
        ref_proj_line = '  --structural-reference-project=' + self.structural_reference_project
        ref_sess_line = '  --structural-reference-session=' + self.structural_reference_session
        scan_line = '  --scan=' + scan
        wdir_line = '  --working-dir=' + self._working_directory_name
        workflow_line = '  --workflow-id=' + self._workflow_id
        setup_line = '  --setup-script=' + self.setup_script

        work_script = open(self._work_script_name(scan), 'w')

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
        futils.wl(work_script, ref_proj_line + self._continue)
        futils.wl(work_script, ref_sess_line + self._continue)
        futils.wl(work_script, scan_line + self._continue)
        futils.wl(work_script, wdir_line + self._continue)
        futils.wl(work_script, workflow_line + self._continue)
        futils.wl(work_script, setup_line)

        work_script.close()
        os.chmod(self._work_script_name(scan), stat.S_IRWXU | stat.S_IRWXG)

    def submit_jobs(self, processing_stage=ProcessingStage.PUT_DATA):
        """
        processing_stage is the last processing stage for which to submit
        the corresponding job.
        GET_DATA means just get the data.
        PROCESS_DATA means get the data and do the processing.
        PUT_DATA means get the data, processing it, and put the results
         back in the DB
        """
        logger.debug("submit_jobs processing_stage: " + str(processing_stage))

        if self.validate_parameters():

            # determine what scans to run the RestingStateStats pipeline on for this subject
            # TBD: Does this get run on every scan for which the ICAFIX pipeline has been run,
            #      or does it only get run on every resting state scan that has been fix processed.

            subject_info = hcp7t_subject.Hcp7TSubjectInfo(
                self.project, self.structural_reference_project, self.subject)

            fix_processed_scans = self.archive.available_FIX_processed_names(subject_info)
            fix_processed_scans_set = set(fix_processed_scans)
            logger.debug("fix_processed_scans_set = " + str(fix_processed_scans_set))

            # resting_state_scans = self.archive.available_resting_state_preproc_names(subject_info)
            # resting_state_scans_set = set(resting_state_scans)
            # logger.debug("resting_state_scans_set = " + str(resting_state_scans_set))

            # scans_to_process_set = resting_state_scans_set & fix_processed_scans_set
            scans_to_process_set = fix_processed_scans_set
            scans_to_process = list(scans_to_process_set)
            scans_to_process.sort()
            logger.debug("scans_to_process: " + str(scans_to_process))

            incomplete_scans_to_process = list()
            for scan in scans_to_process:
                if (not is_complete(self.archive, subject_info, scan)) :
                    incomplete_scans_to_process.append(scan)

            logger.debug("incomplete_scans_to_process: " + str(incomplete_scans_to_process))
            print("incomplete_scans_to_process:", incomplete_scans_to_process)
            
            # for scan in scans_to_process:
            for scan in incomplete_scans_to_process:

                logger.info("")
                logger.info("--------------------------------------------------")
                logger.info("Submitting " + self.PIPELINE_NAME + " jobs for")
                logger.info("  Project: " + self.project)
                logger.info("  Subject: " + self.subject)
                logger.info("  Session: " + self.session)
                logger.info("  Structural Reference Project: " + self.structural_reference_project)
                logger.info("  Structural Reference Session: " + self.structural_reference_session)
                logger.info("     Scan: " + scan)
                logger.info("    Stage: " + str(processing_stage))
                logger.info("--------------------------------------------------")

                # make sure working directories do not have the same name based on
                # the same start time by sleeping a few seconds
                time.sleep(5)

                # build the working directory name
                self._working_directory_name = \
                    self.build_working_directory_name(self.project, self.PIPELINE_NAME, self.subject, scan)
                logger.info("Making working directory: " + self._working_directory_name)
                os.makedirs(name=self._working_directory_name)

                # get JSESSION ID
                jsession_id = xnat_access.get_jsession_id(
                    server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                    username=self.username,
                    password=self.password)
                logger.info("jsession_id: " + jsession_id)

                # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
                xnat_session_id = xnat_access.get_session_id(
                    server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                    username=self.username,
                    password=self.password,
                    project=self.project,
                    subject=self.subject,
                    session=self.session)
                logger.info("xnat_session_id: " + xnat_session_id)

                # get XNAT Workflow ID
                workflow_obj = xnat_access.Workflow(self.username, self.password,
                                                    'https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                                                    jsession_id)
                self._workflow_id = workflow_obj.create_workflow(xnat_session_id,
                                                                 self.project,
                                                                 self.PIPELINE_NAME + '_' + scan,
                                                                 'Queued')
                logger.info("workflow_id: " + self._workflow_id)

                # determine output resource name
                self._output_resource_name = scan + "_RSS"

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
                    self._create_get_data_script(scan)

                    # create script to do work
                    self._create_work_script(scan)

                    # create script to clean data
                    self._create_clean_data_script(scan)

                    # create script to put the results into the DB
                    put_script_name = self._put_data_script_name(scan)
                    self.create_put_script(put_script_name,
                                           self.username, self.password, self.put_server,
                                           self.project, self.subject, self.session,
                                           self._working_directory_name,
                                           self._output_resource_name,
                                           self.PIPELINE_NAME + '_' + scan)

                # submit job to get the data
                if processing_stage >= ProcessingStage.GET_DATA:

                    get_data_submit_cmd = 'qsub ' + self._get_data_script_name(scan)
                    logger.info("get_data_submit_cmd: " + get_data_submit_cmd)

                    completed_get_data_submit_process = subprocess.run(
                        get_data_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                        universal_newlines=True)
                    get_data_job_no = str_utils.remove_ending_new_lines(completed_get_data_submit_process.stdout)
                    logger.info("get_data_job_no: " + get_data_job_no)

                else:
                    logger.info("Get data job not submitted")

                # submit job to process the data
                if processing_stage >= ProcessingStage.PROCESS_DATA:

                    work_submit_cmd = 'qsub -W depend=afterok:' + get_data_job_no + ' ' + self._work_script_name(scan)
                    logger.info("work_submit_cmd: " + work_submit_cmd)

                    completed_work_submit_process = subprocess.run(
                        work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                        universal_newlines=True)
                    work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
                    logger.info("work_job_no: " + work_job_no)

                else:
                    logger.info("Process data job not submitted")

                # submit job to clean the data
                if processing_stage >= ProcessingStage.CLEAN_DATA:

                    clean_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + self._clean_data_script_name(scan)
                    logger.info("clean_submit_cmd: " + clean_submit_cmd)

                    completed_clean_submit_process = subprocess.run(
                        clean_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                        universal_newlines=True)
                    clean_job_no = str_utils.remove_ending_new_lines(completed_clean_submit_process.stdout)
                    logger.info("clean_job_no: " + clean_job_no)

                else:
                    logger.info("Clean data job not submitted")

                # submit job to put the resulting data in the DB
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

        else:
            logger.info("Unable to submit jobs")




