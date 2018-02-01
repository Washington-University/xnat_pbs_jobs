#!/usr/bin/env python3

"""
DeDriftAndResampleHCP7T_OneSubjectJobSubmitter.py: Submit DeDriftAndResampleHCP7T processing
jobs for one HCP 7T subject.
"""

# import of built-in modules
import contextlib
import os
import stat
import subprocess
import time

# import of third party modules
# None

# import of local modules
import hcp.hcp7t.subject as hcp7t_subject
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.delete_resource as delete_resource
import utils.os_utils as os_utils
import utils.str_utils as str_utils
import xnat.xnat_access as xnat_access

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


def _debug(msg):
    # debug_msg = "DEBUG: " + msg
    # _inform(debug_msg)
    pass


class DeDriftAndResampleHCP7T_OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, hcp7t_archive, build_home):
        super().__init__(hcp7t_archive, build_home)
        _debug("__init__")
        self._username = None
        self._password = None
        self._server = None
        self._project = None
        self._subject = None
        self._session = None
        self._structural_reference_project = None
        self._structural_reference_session = None
        self._put_server = None
        self._clean_output_resource_first = None
        self._setup_script = None
        self._walltime_limit_hours = None
        self._vmem_limit_gbs = None
        self._mem_limit_gbs = None
        
    @property
    def PIPELINE_NAME(self):
        return 'DeDriftAndResampleHCP7T'

    @property
    def username(self):
        return self._username

    @username.setter
    def username(self, username):
        self._username = username

    @property
    def password(self):
        return self._password

    @password.setter
    def password(self, password):
        self._password = password

    @property
    def server(self):
        return self._server

    @server.setter
    def server(self, server):
        self._server = server

    @property
    def project(self):
        return self._project

    @project.setter
    def project(self, project):
        self._project = project

    @property
    def subject(self):
        return self._subject

    @subject.setter
    def subject(self, subject):
        self._subject = subject

    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, session):
        self._session = session

    @property
    def structural_reference_project(self):
        return self._structural_reference_project

    @structural_reference_project.setter
    def structural_reference_project(self, structural_reference_project):
        self._structural_reference_project = structural_reference_project

    @property
    def structural_reference_session(self):
        return self._structural_reference_session

    @structural_reference_session.setter
    def structural_reference_session(self, structural_reference_session):
        self._structural_reference_session = structural_reference_session

    @property
    def put_server(self):
        return self._put_server

    @put_server.setter
    def put_server(self, put_server):
        self._put_server = put_server

    @property
    def clean_output_resource_first(self):
        return self._clean_output_resource_first

    @clean_output_resource_first.setter
    def clean_output_resource_first(self, clean_output_resource_first):
        self._clean_output_resource_first = clean_output_resource_first

    @property
    def setup_script(self):
        return self._setup_script

    @setup_script.setter
    def setup_script(self, setup_script):
        self._setup_script = setup_script

    @property
    def walltime_limit_hours(self):
        return self._walltime_limit_hours

    @walltime_limit_hours.setter
    def walltime_limit_hours(self, walltime_limit_hours):
        self._walltime_limit_hours = walltime_limit_hours

    @property
    def vmem_limit_gbs(self):
        return self._vmem_limit_gbs

    @vmem_limit_gbs.setter
    def vmem_limit_gbs(self, vmem_limit_gbs):
        self._vmem_limit_gbs = vmem_limit_gbs

    @property
    def mem_limit_gbs(self):
        return self._mem_limit_gbs

    @mem_limit_gbs.setter
    def mem_limit_gbs(self, mem_limit_gbs):
        self._mem_limit_gbs = mem_limit_gbs
        
    def validate_parameters(self):
        valid_configuration = True

        if self.username is None:
            valid_configuration = False
            _inform("Before submitting jobs: username must be set")

        if self.password is None:
            valid_configuration = False
            _inform("Before submitting jobs: password must be set")

        if self.server is None:
            valid_configuration = False
            _inform("Before submitting jobs: server must be set")

        if self.project is None:
            valid_configuration = False
            _inform("Before submitting jobs: project must be set")

        if self.subject is None:
            valid_configuration = False
            _inform("Before submitting jobs: subject must be set")

        if self.session is None:
            valid_configuration = False
            _inform("Before submitting jobs: session must be set")

        if self.structural_reference_project is None:
            valid_configuration = False
            _inform("Before submitting jobs: structural_reference_project must be set")

        if self.structural_reference_session is None:
            valid_configuration = False
            _inform("Before submitting jobs: structural_reference_session must be set")

        if self.put_server is None:
            valid_configuration = False
            _inform("Before submitting jobs: put_server must be set")

        if self.clean_output_resource_first is None:
            valid_configuration = False
            _inform("Before submitting jobs: clean_output_resource_first must be set")

        if self.setup_script is None:
            valid_configuration = False
            _inform("Before submitting jobs: setup_script must be set")

        if self.walltime_limit_hours is None:
            valid_configuration = False
            _inform("Before submitting jobs: walltime_limit_hours must be set")

        if self.vmem_limit_gbs is None:
            valid_configuration = False
            _inform("Before submitting jobs: vmem_limit_gbs must be set")

        if self.mem_limit_gbs is None:
            valid_configuration = False
            _inform("Before submitting jobs: mem_limit_gbs must be set")
            
        return valid_configuration

    def submit_jobs(self):
        _debug("submit_jobs")

        if self.validate_parameters():

            # make sure working directories don't have the same name based on the same
            # start time by sleeping a few seconds
            time.sleep(5)

            current_seconds_since_epoch = int(time.time())

            working_directory_name = self.build_home
            working_directory_name += os.sep + self.project
            working_directory_name += os.sep + self.PIPELINE_NAME
            working_directory_name += '.' + self.subject
            working_directory_name += '.' + str(current_seconds_since_epoch)

            # make the working directory
            _inform("Making working directory: " + working_directory_name)
            os.makedirs(name=working_directory_name)

            # get JSESSION ID
            jsession_id = xnat_access.get_jsession_id(
                server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                username=self.username,
                password=self.password)
            _inform("jsession_id: " + jsession_id)

            # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
            xnat_session_id = xnat_access.get_session_id(
                server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                username=self.username,
                password=self.password,
                project=self.project,
                subject=self.subject,
                session=self.session)
            _inform("xnat_session_id: " + xnat_session_id)

            # get XNAT Workflow ID
            workflow_obj = xnat_access.Workflow(
                self.username, self.password, self.server, jsession_id)
            workflow_id = workflow_obj.create_workflow(
                xnat_session_id, self.project, self.PIPELINE_NAME, 'Queued')
            _inform("workflow_id: " + workflow_id)

            # Determine the output resource name
            output_resource_name = self.archive.DEDRIFT_AND_RESAMPLE_RESOURCE_NAME
            _inform("output_resource_name: " + output_resource_name)

            # Clean the output resource if requested
            if self.clean_output_resource_first:
                _inform("Deleting resouce: " + output_resource_name + " for:")
                _inform("  project: " + self.project)
                _inform("  subject: " + self.subject)
                _inform("  session: " + self.session)

                delete_resource.delete_resource(
                    self.username, self.password, str_utils.get_server_name(self.server),
                    self.project, self.subject, self.session, output_resource_name, True)

            script_file_start_name = working_directory_name
            script_file_start_name += os.sep + self.subject
            script_file_start_name += '.' + self.PIPELINE_NAME
            script_file_start_name += '.' + self.project
            script_file_start_name += '.' + self.session

            # Create script to submit to do the actual work
            work_script_name = script_file_start_name + '.XNAT_PBS_job.sh'
            with contextlib.suppress(FileNotFoundError):
                os.remove(work_script_name)

            work_script = open(work_script_name, 'w')

            nodes_spec = 'nodes=1:ppn=1'
            walltime_spec = 'walltime=' + str(self.walltime_limit_hours) + ':00:00'
            vmem_spec = 'vmem=' + str(self.vmem_limit_gbs) + 'gb'
            mem_spec = 'mem=' + str(self.mem_limit_gbs) + 'gb'

            work_script.write('#PBS -l ' + nodes_spec + ',' + walltime_spec + ',' + vmem_spec + ',' + mem_spec + os.linesep)
            # work_script.write('#PBS -q HCPput' + os.linesep)
            work_script.write('#PBS -o ' + working_directory_name + os.linesep)
            work_script.write('#PBS -e ' + working_directory_name + os.linesep)
            work_script.write(os.linesep)
            work_script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep + 'DeDriftAndResampleHCP7T' + os.sep +
                              'DeDriftAndResampleHCP7T.XNAT.sh \\' + os.linesep)
            work_script.write('  --user="' + self.username + '" \\' + os.linesep)
            work_script.write('  --password="' + self.password + '" \\' + os.linesep)
            work_script.write('  --server="' + str_utils.get_server_name(self.server) + '" \\' + os.linesep)
            work_script.write('  --project="' + self.project + '" \\' + os.linesep)
            work_script.write('  --subject="' + self.subject + '" \\' + os.linesep)
            work_script.write('  --session="' + self.session + '" \\' + os.linesep)
            work_script.write('  --structural-reference-project="' +
                              self.structural_reference_project + '" \\' + os.linesep)
            work_script.write('  --structural-reference-session="' +
                              self.structural_reference_session + '" \\' + os.linesep)
            work_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
            work_script.write('  --workflow-id="' + workflow_id + '" \\' + os.linesep)

            # work_script.write('  --keep-all' + ' \\' + os.linesep)
            # work_script.write('  --prevent-push' + ' \\' + os.linesep)

            work_script.write('  --setup-script=' + self.setup_script + os.linesep)
            
            work_script.close()
            os.chmod(work_script_name, stat.S_IRWXU | stat.S_IRWXG)

            # Create script to put the results into the DB
            put_script_name = script_file_start_name + '.XNAT_PBS_PUT_job.sh'
            self.create_put_script(put_script_name,
                                   self.username, self.password, self.put_server,
                                   self.project, self.subject, self.session,
                                   working_directory_name, output_resource_name,
                                   self.PIPELINE_NAME)

            # Submit the job to do the work
            work_submit_cmd = 'qsub ' + work_script_name
            _inform("work_submit_cmd: " + work_submit_cmd)

            completed_work_submit_process = subprocess.run(
                work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
            _inform("work_job_no: " + work_job_no)

            # Submit the job to put the results in the DB
            put_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + put_script_name
            _inform("put_submit_cmd: " + put_submit_cmd)

            completed_put_submit_process = subprocess.run(
                put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            _inform("put_job_no: " + put_job_no)

        else:
            _inform("Unable to submit jobs")
