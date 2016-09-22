#!/usr/bin/env python3

"""
SubmitdiffusionPreprocessingHCP7TOneSubject.py: Submit Diffusion Preprocessing
jobs for one HCP 7T subject.
"""

# import of built-in modules
import contextlib
import os
import stat
import time

# import of third party modules
pass

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import hcp.one_subject_job_submitter as one_subject_job_submitter
import hcp.pe_dirs as pe_dirs
import xnat.xnat_access as xnat_access
import utils.os_utils as os_utils
import utils.my_argparse as my_argparse
import utils.delete_resource as delete_resource
import utils.str_utils as str_utils
import utils.file_utils as futils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    """Outputs a message that is prefixed by the module file name."""
    print(os.path.basename(__file__) + ": " + msg)


class DiffusionPreprocessing7TOneSubjectJobSubmitter(
    one_subject_job_submitter.OneSubjectJobSubmitter):
    """This class submits a set of dependent jobs for Diffusion Preprocessing
    for a single HCP 7T subject."""

    def __init__(self, hcp7t_archive, build_home):
        """Constructs a DiffusionPreprocessing7TOneSubjectJobSubmitter.

        :param hcp7t_archive: HCP 7T Archive
        :type hcp7t_archive: Hcp7T_Archive

        :param build_home: path to build space
        :type build_home: str
        """
        super().__init__(hcp7t_archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "DiffusionPreprocessingHCP7T"

    def _get_scripts_start_name(self):

        script_file_start_name = self._working_directory_name
        script_file_start_name += os.sep + self._subject
        script_file_start_name += '.' + self.PIPELINE_NAME
        script_file_start_name += '.' + self._project
        script_file_start_name += '.' + self._session

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
    def _continue(self):
        return ' \\'
    
    def _create_pre_eddy_script(self):

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._pre_eddy_script_name)

        walltime_limit = str(self._pre_eddy_walltime_limit_hours) + ':00:00'
        vmem_limit = str(self._pre_eddy_vmem_limit_gbs) + 'gb'
        
        resources_line = '#PBS -l nodes=1:ppn=1,walltime=' + walltime_limit
        resources_line += ',vmem=' + vmem_limit

        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T_PreEddy.XNAT.sh'

        user_line = '  --user="' + self._username + '"'
        password_line = '  --password="' + self._password + '"' 
        
        server_line = '  --server="'
        server_line += str_utils.get_server_name(self._server) + '"'

        project_line = '  --project="' + self._project + '"'
        subject_line = '  --subject="' + self._subject + '"'
        session_line = '  --session="' + self._session + '"'
        
        ref_proj_line = '  --structural-reference-project="'
        ref_proj_line += self._structural_reference_project + '"'
        
        ref_sess_line = '  --structural-reference-session="'
        ref_sess_line += self._structural_reference_session + '"'

        wdir_line = '  --working-dir="' + self._working_directory_name + '"'
        workflow_line = '  --workflow-id="' + self._workflow_id + '"'

        setup_line = '  --setup-script=' + self._setup_script
        pe_dirs_line = '  --phase-encoding-dirs=' + self._pe_dirs_spec

        
        pre_eddy_script = open(self._pre_eddy_script_name, 'w')

        futils.wl(pre_eddy_script, resources_line)
        futils.wl(pre_eddy_script, stdout_line)
        futils.wl(pre_eddy_script, stderr_line)
        futils.wl(pre_eddy_script, '')
        futils.wl(pre_eddy_script, script_line   + self._continue)
        futils.wl(pre_eddy_script, user_line     + self._continue)
        futils.wl(pre_eddy_script, password_line + self._continue)
        futils.wl(pre_eddy_script, server_line   + self._continue)
        futils.wl(pre_eddy_script, project_line  + self._continue)
        futils.wl(pre_eddy_script, subject_line  + self._continue)
        futils.wl(pre_eddy_script, session_line  + self._continue)
        futils.wl(pre_eddy_script, ref_proj_line + self._continue)
        futils.wl(pre_eddy_script, ref_sess_line + self._continue)
        futils.wl(pre_eddy_script, wdir_line     + self._continue)
        futils.wl(pre_eddy_script, workflow_line + self._continue)
        futils.wl(pre_eddy_script, setup_line    + self._continue)
        futils.wl(pre_eddy_script, pe_dirs_line)

        pre_eddy_script.close()
        os.chmod(self._pre_eddy_script_name, stat.S_IRWXU | stat.S_IRWXG)

    def _create_eddy_script(self):
         
        with contextlib.suppress(FileNotFoundError):
            os.remove(self._eddy_script_name)

        walltime_limit = str(self._eddy_walltime_limit_hours) + ':00:00'
        
        resources_line = '#PBS -l nodes=1:ppn=3:gpus=1,walltime='+walltime_limit
        stdout_line = '#PBS -o ' + self._working_directory_name
        stderr_line = '#PBS -e ' + self._working_directory_name

        script_line = self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T' + os.sep
        script_line += 'DiffusionPreprocessingHCP7T_Eddy.XNAT.sh'

        user_line = '  --user="' + self._username + '"'
        password_line = '  --password="' + self._password + '"' 

        server_line = '  --server="'
        server_line += str_utils.get_server_name(self._server) + '"'

        subject_line = '  --subject="' + self._subject + '"'
        wdir_line = '  --working-dir="' + self._working_directory_name + '"'
        workflow_line = '  --workflow-id="' + self._workflow_id + '"'
        setup_line = '  --setup-script=' + self._setup_script


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

        with contextlib.suppress(FileNotFoundError):
            os.remove(self._post_eddy_script_name)
            
        post_eddy_script = open(self._post_eddy_script_name, 'w')

        walltime_limit = str(self._post_eddy_walltime_limit_hours) + ':00:00'
        vmem_limit = str(self._post_eddy_vmem_limit_gbs) + 'gb'

        
    def submit_jobs(self,
                    username, password, server,
                    project, subject, session,
                    structural_reference_project, structural_reference_session,
                    put_server, clean_output_resource_first, setup_script,
                    pe_dirs_spec,
                    pre_eddy_walltime_limit_hours = 10,
                    pre_eddy_vmem_limit_gbs = 16,
                    eddy_walltime_limit_hours = 16,
                    post_eddy_walltime_limit_hours = 3,
                    post_eddy_vmem_limit_gbs = 20):
        
        self._username = username
        self._password = password
        self._server = server

        self._project = project
        self._subject = subject
        self._session = session

        self._structural_reference_project = structural_reference_project
        self._structural_reference_session = structural_reference_session

        self._put_server = put_server
        self._clean_output_resource_first = clean_output_resource_first
        self._setup_script = setup_script

        self._pe_dirs_spec = pe_dirs_spec

        self._pre_eddy_walltime_limit_hours = pre_eddy_walltime_limit_hours
        self._pre_eddy_vmem_limit_gbs = pre_eddy_vmem_limit_gbs

        self._eddy_walltime_limit_hours = eddy_walltime_limit_hours

        self._post_eddy_walltime_limit_hours = post_eddy_walltime_limit_hours
        self._post_eddy_vmem_limit_gbs = post_eddy_vmem_limit_gbs
        
        # subject_info = hcp7t_subject.Hcp7TSubjectInfo(self._project,
        #                                               self._structural_reference_project,
        #                                               self._subject)

        _inform("")
        _inform("--------------------------------------------------")
        _inform("Submitting " + self.PIPELINE_NAME + " jobs for ")
        _inform("  Project: " + self._project)
        _inform("  Subject: " + self._subject)
        _inform("  Session: " + self._session)
        _inform("--------------------------------------------------")

        # make sure working directories don't have the same name based on the
        # same start time by sleeping a few seconds
        time.sleep(5)
        current_seconds_since_epoch = int(time.time())

        # build the working directory name
        self._working_directory_name = self.build_home 
        self._working_directory_name += os.sep + project
        self._working_directory_name += os.sep + self.PIPELINE_NAME 
        self._working_directory_name += '.' + subject
        self._working_directory_name += '.' + str(current_seconds_since_epoch)

        # make the working directory
        _inform("making working directory: " + self._working_directory_name)
        os.makedirs(name=self._working_directory_name)

        # get JSESSION ID
        jsession_id = xnat_access.get_jsession_id(
            server = 'db.humanconnectome.org',
            username = self._username,
            password = self._password)
        _inform("jsession_id: " + jsession_id)

        # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
        xnat_session_id = xnat_access.get_session_id(
            server = 'db.humanconnectome.org',
            username = self._username,
            password = self._password,
            project = self._project,
            subject = self._subject,
            session = self._session)
        _inform("xnat_session_id: " + xnat_session_id)

        # get XNAT Workflow ID
        workflow_obj = xnat_access.Workflow(self._username, self._password, 
                                            'https://db.humanconnectome.org', jsession_id)
        self._workflow_id = workflow_obj.create_workflow(xnat_session_id, 
                                                         self._project, 
                                                         self.PIPELINE_NAME, 
                                                         'Queued')
        _inform("workflow_id: " + self._workflow_id)

        # determine output resource name
        self._output_resource_name = 'Diffusion_preproc'

        # clean the output resource if requested
        if clean_output_resource_first:
            _inform("Deleting resource: " + self._output_resource_name + " for: ")
            _inform("  project: " + self._project)
            _inform("  subject: " + self._subject)
            _inform("  session: " + self._session)

            delete_resource.delete_resource(
                self._username, self._password, 
                str_utils.get_server_name(self._server),
                self._project, self._subject, self._session, 
                self._output_resource_name)

        # create script to do the PreEddy work
        self._create_pre_eddy_script()

        # create script to do the Eddy work
        self._create_eddy_script()

        # create script to do the PostEddy work
        self._create_post_eddy_script()



if __name__ == "__main__":

    # create an Hcp7T_Archive object
    archive = hcp7t_archive.Hcp7T_Archive()

    # create a parser object for getting command line options
    parser = my_argparse.MyArgumentParser(description="Program to submit Diffusion Preprocessing jobs for one HCP 7T subject.")

    # add arguments
    parser.add_argument('-u', '--user', dest='user', required=True, type=str)

    parser.add_argument('-pw', '--password', dest='password', required=True, 
                        type=str)

    parser.add_argument('-ser', '--server', dest='server', required=False, 
                        type=str, default='db.humanconnectome.org')

    parser.add_argument('-pr', '--project', dest='project', required=False, 
                        type=str, default='HCP_Staging_7T')

    parser.add_argument('-sub', '--subject', dest='subject', required=True,
                        type=str)

    parser.add_argument('-ses', '--session', dest='session', required=False, 
                        type=str, default=None)

    parser.add_argument('-peds', '--pe-dirs', dest='pe_dirs', required=True,
                        type=str)

    parser.add_argument('-srp', '--structural-reference-project', 
                        dest='structural_reference_project', required=True,
                        type=str)

    parser.add_argument('-srs', '--structural-reference-session',
                        dest='structural_reference_session', required=False, 
                        type=str, default=None)

    parser.add_argument('-ps', '--put-server', dest='put_server', 
                        required=False, type=str, 
                        default='db.humanconnectome.org')

    parser.add_argument('-dnc', '--do-not-clean-first',
                        dest='clean_output_resource_first', required=False, 
                        action='store_false', default=True)

    parser.add_argument('-ss', '--setup-script', dest='setup_script', 
                        required=True, type=str)

    # parse the command line arguments
    args = parser.parse_args()

    # set default argument values that are derived from other argument values
    if not args.session:
        args.session = args.subject + archive.NAME_DELIMITER + archive.TESLA_SPEC

    if not args.structural_reference_session:
        args.structural_reference_session = args.subject + archive.NAME_DELIMITER + '3T'

    # check arguments for valid values
    if args.pe_dirs == pe_dirs.PEDirs.RLLR.name:
        args.pe_dirs = pe_dirs.PEDirs.RLLR
    elif args.pe_dirs == pe_dirs.PEDirs.PAAP.name:
        args.pe_dirs = pe_dirs.PEDirs.PAAP
    else:
        raise ValueError("--pe-dirs= must be one of '" + 
                         pe_dirs.PEDirs.RLLR.name + "' or '" + 
                         pe_dirs.PEDirs.PAAP.name + "'")

    # show parsed arguments
    _inform("ConnectomeDB Username: " + args.user)
    _inform("ConnectomeDB Password: " + "*** password mask ***")
    _inform("ConnectomeDB Server: " + args.server)
    _inform("ConnectomeDB Project: " + args.project)
    _inform("ConnectomeDB Subject: " + args.subject)
    _inform("ConnectomeDB Session: " + args.session)
    _inform("Phase Encoding Dirs: " + args.pe_dirs.name)
    _inform("ConnectomeDB Structural Reference Project: " + args.structural_reference_project)
    _inform("ConnectomeDB Structural Reference Session: " + args.structural_reference_session)
    _inform("PUT Server: " + args.put_server)
    _inform("Clean output resource first: " + str(args.clean_output_resource_first))
    _inform("Set up script: " + args.setup_script)

    # create a job submitter
    submitter = DiffusionPreprocessing7TOneSubjectJobSubmitter(archive, archive.build_home)
    
    # _inform("")
    # _inform("submitter.PIPELINE_NAME: " + submitter.PIPELINE_NAME)
    # _inform("submitter.archive: " + str(submitter.archive))
    # _inform("submitter.build_home: " + submitter.build_home)
    # _inform("submitter.xnat_pbs_jobs_home: " + submitter.xnat_pbs_jobs_home)
    # _inform("submitter.log_dir: " + submitter.log_dir)

    # submit jobs for the specified subject
    submitter.submit_jobs(
        args.user, args.password, args.server,
        args.project, args.subject, args.session,
        args.structural_reference_project, args.structural_reference_session,
        args.put_server, args.clean_output_resource_first, args.setup_script,
        args.pe_dirs.name)

