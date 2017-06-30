#!/usr/bin/env python3

"""
hcp/hcp7t/diffusion_preprocessing/one_subject_job_submitter.py:
Submit jobs to perform HCP 7T diffusion preprocessing for one HCP 7T Subject.
"""

# import of built-in modules
import contextlib
import os
import stat
import subprocess
import time

# import of third party modules

# import of local modules
import hcp.one_subject_job_submitter as one_subject_job_submitter
import hcp.pe_dirs as pe_dirs
import utils.delete_resource as delete_resource
import utils.file_utils as futils
import utils.os_utils as os_utils
import utils.str_utils as str_utils
import xnat.xnat_access as xnat_access

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


def _debug(msg):
    # debug_msg = "DEBUG: " + msg
    # _inform(debug_msg)
    pass


class OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, hcp7t_archive, build_home):
        super().__init__(hcp7t_archive, build_home)
        _debug("__init__")

    @property
    def PIPELINE_NAME(self):
        return "DiffusionPreprocessingHCP7T"

    @property
    def project(self):
        return self._project

    @project.setter
    def project(self, value):
        self._project = value

    @property
    def subject(self):
        return self._subject

    @subject.setter
    def subject(self, value):
        self._subject = value

    @property
    def session(self):
        return self._session

    @session.setter
    def session(self, value):
        self._session = value

    @property
    def clean_output_resource_first(self):
        return self._clean_output_resource_first

    @clean_output_resource_first.setter
    def clean_output_resource_first(self, value):
        self._clean_output_resource_first = value

    @property
    def username(self):
        return self._username

    @username.setter
    def username(self, value):
        self._username = value

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

    def _get_scripts_start_name(self):
        script_file_start_name = self._working_directory_name
        script_file_start_name += os.sep + self.subject
        script_file_start_name += '.' + self.PIPELINE_NAME
        script_file_start_name += '.' + self.project
        script_file_start_name += '.' + self.session

        return script_file_start_name

    @property
    def _pre_eddy_script_name(self):
        return self._get_scripts_start_name() + '_PreEddy.XNAT_PBS_job.sh'

    @property
    def _eddy_script_name(self):
        return self._get_scripts_start_name() + '_Eddy.XNAT_PBS_job.sh'

    @property
    def _post_eddy_script_name(self):
        return self._get_scripts_start_name() + '_PostEddy.XNAT_PBS_job.sh'

    @property
    def pre_eddy_walltime_limit_hours(self):
        return self._pre_eddy_walltime_limit_hours

    @pre_eddy_walltime_limit_hours.setter
    def pre_eddy_walltime_limit_hours(self, value):
        self._pre_eddy_walltime_limit_hours = value

    @property
    def eddy_walltime_limit_hours(self):
        return self._eddy_walltime_limit_hours

    @eddy_walltime_limit_hours.setter
    def eddy_walltime_limit_hours(self, value):
        self._eddy_walltime_limit_hours = value

    @property
    def post_eddy_walltime_limit_hours(self):
        return self._post_eddy_walltime_limit_hours

    @post_eddy_walltime_limit_hours.setter
    def post_eddy_walltime_limit_hours(self, value):
        self._post_eddy_walltime_limit_hours = value

    @property
    def pre_eddy_vmem_limit_gbs(self):
        return self._pre_eddy_walltime_limit_gbs

    @pre_eddy_vmem_limit_gbs.setter
    def pre_eddy_vmem_limit_gbs(self, value):
        self._pre_eddy_walltime_limit_gbs = value

    @property
    def post_eddy_vmem_limit_gbs(self):
        return self._post_eddy_walltime_limit_gbs

    @post_eddy_vmem_limit_gbs.setter
    def post_eddy_vmem_limit_gbs(self, value):
        self._post_eddy_walltime_limit_gbs = value

    @property
    def structural_reference_project(self):
        return self._structural_reference_project

    @structural_reference_project.setter
    def structural_reference_project(self, value):
        self._structural_reference_project = value

    @property
    def structural_reference_session(self):
        return self._structural_reference_session

    @structural_reference_session.setter
    def structural_reference_session(self, value):
        self._structural_reference_session = value

    @property
    def setup_script(self):
        return self._setup_script

    @setup_script.setter
    def setup_script(self, value):
        self._setup_script = value

    @property
    def pe_dirs_spec(self):
        return self._pe_dirs_spec

    @pe_dirs_spec.setter
    def pe_dirs_spec(self, value):
        self._pe_dirs_spec = value

    @property
    def put_server(self):
        return self._put_server

    @put_server.setter
    def put_server(self, value):
        self._put_server = value

    @property
    def _continue(self):
        return ' \\'

    def validate_parameters(self):
        valid_configuration = True

        if self.project is None:
            valid_configuration = False
            _inform("Before submitting jobs: project value must be set")

        if self.subject is None:
            valid_configuration = False
            _inform("Before submitting jobs: subject value must be set")

        if self.session is None:
            valid_configuration = False
            _inform("Before submitting jobs: session value must be set")

        if self.clean_output_resource_first is None:
            valid_configuration = False
            _inform("Before submitting jobs: clean_output_resource_first value must be set")

        if self.username is None:
            valid_configuration = False
            _inform("Before submitting jobs: username value must be set")

        if self.password is None:
            valid_configuration = False
            _inform("Before submitting jobs: password value must be set")

        if self.server is None:
            valid_configuration = False
            _inform("Before submitting jobs: server value must be set")

        if self.pre_eddy_walltime_limit_hours is None:
            valid_configuration = False
            _inform("Before submitting jobs: pre_eddy_walltime_limit_hours must be set")

        if self.pre_eddy_vmem_limit_gbs is None:
            valid_configration = False
            _inform("Before submitting jobs: pre_eddy_vmem_limit_gbs must be set")

        if self.structural_reference_project is None:
            valid_configuration = False
            _inform("Before submitting jobs: structural_reference_project must be set")

        if self.structural_reference_session is None:
            valid_configuration = False
            _inform("Before submitting jobs: structural_reference_session must be set")

        if self.setup_script is None:
            valid_configuration = False
            _inform("Before submitting jobs: setup_script must be set")

        if self.pe_dirs_spec is None:
            valid_configuration = False
            _inform("Before submitting jobs: pe_dirs_spec must be set")

        if self.eddy_walltime_limit_hours is None:
            valid_configuration = False
            _inform("Before submitting jobs: eddy_walltime_limit_hours must be set")

        if self.post_eddy_walltime_limit_hours is None:
            valid_configuration = False
            _inform("Before submitting jobs: post_eddy_walltime_limit_hours must be set")

        if self.post_eddy_vmem_limit_gbs is None:
            valid_configuration = False
            _inform("Before submitting jobs: post_eddy_vmem_limit_gbs must be set")

        if self.put_server is None:
            valid_configuration = False
            _inform("Before submitting jobs: put_server must be set")

        return valid_configuration

    def _create_pre_eddy_script(self):
        _debug("_create_pre_eddy_script")

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._pre_eddy_script_name)

        walltime_limit = str(self.pre_eddy_walltime_limit_hours) + ':00:00'
        vmem_limit = str(self.pre_eddy_vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=1:ppn=1,walltime=' + walltime_limit
        resources_line += ',vmem=' + vmem_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh'

        user_line = '  --user="' + self.username + '"'
        password_line = '  --password="' + self.password + '"'
        server_line = '  --server="' + str_utils.get_server_name(self.server) + '"'
        project_line = '  --project="' + self.project + '"'
        subject_line = '  --subject="' + self.subject + '"'
        session_line = '  --session="' + self.session + '"'
        ref_proj_line = '  --structural-reference-project="'
        ref_proj_line += self.structural_reference_project + '"'
        ref_sess_line = '  --structural-reference-session="'
        ref_sess_line += self.structural_reference_session + '"'
        wdir_line = '  --working-dir="' + self._working_directory_name + '"'
        workflow_line = '  --workflow-id="' + self._workflow_id + '"'
        setup_line = '  --setup-script=' + self.setup_script
        pe_dirs_line = '  --phase-encoding-dirs=' + self.pe_dirs_spec

        pre_eddy_script = open(self._pre_eddy_script_name, 'w')

        futils.wl(pre_eddy_script, resources_line)
        futils.wl(pre_eddy_script, stdout_line)
        futils.wl(pre_eddy_script, stderr_line)
        futils.wl(pre_eddy_script, '')
        futils.wl(pre_eddy_script, script_line + self._continue)
        futils.wl(pre_eddy_script, user_line + self._continue)
        futils.wl(pre_eddy_script, password_line + self._continue)
        futils.wl(pre_eddy_script, server_line + self._continue)
        futils.wl(pre_eddy_script, project_line + self._continue)
        futils.wl(pre_eddy_script, subject_line + self._continue)
        futils.wl(pre_eddy_script, session_line + self._continue)
        futils.wl(pre_eddy_script, ref_proj_line + self._continue)
        futils.wl(pre_eddy_script, ref_sess_line + self._continue)
        futils.wl(pre_eddy_script, wdir_line + self._continue)
        futils.wl(pre_eddy_script, workflow_line + self._continue)
        futils.wl(pre_eddy_script, setup_line + self._continue)
        futils.wl(pre_eddy_script, pe_dirs_line)

        pre_eddy_script.close()
        os.chmod(self._pre_eddy_script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_eddy_script(self):
        _debug("_create_eddy_script")

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._eddy_script_name)

        walltime_limit = str(self.eddy_walltime_limit_hours) + ':00:00'

        resources_line = '#PBS -l nodes=1:ppn=3:gpus=1,walltime=' + walltime_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T_Eddy.XNAT.sh'

        user_line = '  --user="' + self.username + '"'
        password_line = '  --password="' + self.password + '"'
        server_line = '  --server="' + str_utils.get_server_name(self.server) + '"'
        subject_line = '  --subject="' + self.subject + '"'
        wdir_line = '  --working-dir="' + self._working_directory_name + '"'
        workflow_line = '  --workflow-id="' + self._workflow_id + '"'
        setup_line = '  --setup-script=' + self.setup_script

        eddy_script = open(self._eddy_script_name, 'w')

        futils.wl(eddy_script, resources_line)
        futils.wl(eddy_script, stdout_line)
        futils.wl(eddy_script, stderr_line)
        futils.wl(eddy_script, '')
        futils.wl(eddy_script, script_line + self._continue)
        futils.wl(eddy_script, user_line + self._continue)
        futils.wl(eddy_script, password_line + self._continue)
        futils.wl(eddy_script, server_line + self._continue)
        futils.wl(eddy_script, subject_line + self._continue)
        futils.wl(eddy_script, wdir_line + self._continue)
        futils.wl(eddy_script, workflow_line + self._continue)
        futils.wl(eddy_script, setup_line)

        eddy_script.close()
        os.chmod(self._eddy_script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_post_eddy_script(self):
        _debug("_create_post_eddy_script")

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._post_eddy_script_name)

        walltime_limit = str(self.post_eddy_walltime_limit_hours) + ':00:00'
        vmem_limit = str(self.post_eddy_vmem_limit_gbs) + 'gb'

        resources_line = '#PBS -l nodes=1:ppn=1,walltime=' + walltime_limit
        resources_line += ',vmem=' + vmem_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T_PostEddy.XNAT.sh'

        user_line = '  --user="' + self.username + '"'
        password_line = '  --password="' + self.password + '"'
        server_line = '  --server="' + str_utils.get_server_name(self.server) + '"'
        subject_line = '  --subject="' + self.subject + '"'
        wdir_line = '  --working-dir="' + self._working_directory_name + '"'
        workflow_line = '  --workflow-id="' + self._workflow_id + '"'
        setup_line = '  --setup-script=' + self.setup_script

        post_eddy_script = open(self._post_eddy_script_name, 'w')

        futils.wl(post_eddy_script, resources_line)
        futils.wl(post_eddy_script, stdout_line)
        futils.wl(post_eddy_script, stderr_line)
        futils.wl(post_eddy_script, '')
        futils.wl(post_eddy_script, script_line + self._continue)
        futils.wl(post_eddy_script, user_line + self._continue)
        futils.wl(post_eddy_script, password_line + self._continue)
        futils.wl(post_eddy_script, server_line + self._continue)
        futils.wl(post_eddy_script, subject_line + self._continue)
        futils.wl(post_eddy_script, wdir_line + self._continue)
        futils.wl(post_eddy_script, workflow_line + self._continue)
        futils.wl(post_eddy_script, setup_line)

        post_eddy_script.close()
        os.chmod(self._post_eddy_script_name, stat.S_IRWXU | stat.S_IRWXG)

    def submit_jobs(self):
        _debug("submit_jobs")

        if self.validate_parameters():

            _inform("")
            _inform("--------------------------------------------------")
            _inform("Submitting " + self.PIPELINE_NAME + " jobs for")
            _inform("  Project: " + self.project)
            _inform("  Subject: " + self.subject)
            _inform("  Session: " + self.session)
            _inform("--------------------------------------------------")

            # make sure working directories don't have the same name based on
            # the same start time by sleeping a few seconds
            time.sleep(5)
            current_seconds_since_epoch = int(time.time())

            # build the working directory name
            self._working_directory_name = self.build_home
            self._working_directory_name += os.sep + self.project
            self._working_directory_name += os.sep + self.PIPELINE_NAME
            self._working_directory_name += '.' + self.subject
            self._working_directory_name += '.' + str(current_seconds_since_epoch)

            # make the working directory
            _inform("making working directory: " + self._working_directory_name)
            os.makedirs(name=self._working_directory_name)

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
                project=kself.project,
                subject=self.subject,
                session=self.session)
            _inform("xnat_session_id: " + xnat_session_id)

            # get XNAT Workflow ID
            workflow_obj = xnat_access.Workflow(self.username, self.password,
                                                os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                                                jsession_id)
            self._workflow_id = workflow_obj.create_workflow(xnat_session_id,
                                                             self.project,
                                                             self.PIPELINE_NAME,
                                                             'Queued')
            _inform("workflow_id: " + self._workflow_id)

            # determine output resource name
            self._output_resource_name = 'Diffusion_preproc'

            # clean the output resource if requested
            if self.clean_output_resource_first:
                _inform("Deleting resource: " + self._output_resource_name + " for:")
                _inform("  project: " + self.project)
                _inform("  subject: " + self.subject)
                _inform("  session: " + self.session)

                delete_resource.delete_resource(
                    self.username, self.password,
                    str_utils.get_server_name(self.server),
                    self.project, self.subject, self.session,
                    self._output_resource_name)

            # create script to do the PreEddy work
            self._create_pre_eddy_script()

            # create script to do the Eddy work
            self._create_eddy_script()

            # create script to do the PostEddy work
            self._create_post_eddy_script()

            # create script to put the results into the DB
            put_script_name = self._get_scripts_start_name() + '.XNAT_PBS_PUT_job.sh'
            self.create_put_script(put_script_name,
                                   self.username, self.password, self.put_server,
                                   self.project, self.subject, self.session,
                                   self._working_directory_name, self._output_resource_name,
                                   self.PIPELINE_NAME)

            # Submit the job to do the Pre-Eddy work
            pre_eddy_submit_cmd = 'qsub ' + self._pre_eddy_script_name
            _inform("pre_eddy_submit_cmd: " + pre_eddy_submit_cmd)

            completed_pre_eddy_submit_process = subprocess.run(
                pre_eddy_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            pre_eddy_job_no = str_utils.remove_ending_new_lines(completed_pre_eddy_submit_process.stdout)
            _inform("pre_eddy_job_no: " + pre_eddy_job_no)

            # Submit the job to do the Eddy work
            eddy_submit_cmd = 'qsub -W depend=afterok:' + pre_eddy_job_no + ' ' + self._eddy_script_name
            _inform("eddy_submit_cmd: " + eddy_submit_cmd)

            completed_eddy_submit_process = subprocess.run(
                eddy_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            eddy_job_no = str_utils.remove_ending_new_lines(completed_eddy_submit_process.stdout)
            _inform("eddy_job_no: " + eddy_job_no)

            # Submit the job to do the Post-Eddy work
            post_eddy_submit_cmd = 'qsub -W depend=afterok:' + eddy_job_no + ' ' + self._post_eddy_script_name
            _inform("post_eddy_submit_cmd: " + post_eddy_submit_cmd)

            completed_post_eddy_submit_process = subprocess.run(
                post_eddy_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            post_eddy_job_no = str_utils.remove_ending_new_lines(completed_post_eddy_submit_process.stdout)
            _inform("post_eddy_job_no: " + post_eddy_job_no)

            # Submit the job to put the results in the DB
            put_submit_cmd = 'qsub -W depend=afterok:' + post_eddy_job_no + ' ' + put_script_name
            _inform("put_submit_cmd: " + put_submit_cmd)

            completed_put_submit_process = subprocess.run(
                put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            _inform("put_job_no: " + put_job_no)

        else:
            _inform("Unable to submit jobs")
