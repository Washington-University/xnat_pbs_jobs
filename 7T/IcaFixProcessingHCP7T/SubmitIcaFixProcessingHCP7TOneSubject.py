#!/usr/bin/env python3

"""SubmitIcaFixProcessingHCP7TOneSubject.py: Submit ICA+FIX processing jobs for one HCP 7T subject."""

# import of built-in modules
import os
import sys
import argparse
import time
import contextlib
import urllib
import stat
import subprocess

# import of third party modules
pass

# path changes and import of local modules
sys.path.append('../lib')
import hcp7t_archive
import hcp7t_subject

sys.path.append('../../lib')
import xnat_access
import str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)

def get_server_name(url):
    (scheme, location, path, params, query, fragment) = urllib.parse.urlparse(url)
    return location

def get_required_env_value(var_name):
    value = os.getenv(var_name)
    if value == None:
        inform("Environment variable " + var_name + " must be set!")
        sys.exit(1)
    return value

class MyArgumentParser(argparse.ArgumentParser):
    """This subclass of ArgumentParser prints out the help message when an error is found in parsing."""
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

class IcaFix7TOneSubjectSubmitter:
    """This class submits a set of dependent jobs for ICA+FIX processing for a single HCP 7T subject."""

    def __init__(self, hcp7t_archive, build_home):
        """Constructs an IcaFix7TOneSubjectSubmitter.

        :param hcp7t_archive: HCP 7T Archive
        :type hcp7t_archive: Hcp7T_Archive

        :param build_home: path to build space
        :type build_home: str
        """
        self._archive = hcp7t_archive
        self._build_home = build_home

        home = get_required_env_value('HOME')
        self._xnat_pbs_jobs_home = home + os.sep + 'pipeline_tools' + os.sep + 'xnat_pbs_jobs'

        self._log_dir = get_required_env_value('LOG_DIR')

    @property
    def PIPELINE_NAME(self):
        return "IcaFixProcessingHCP7T"

    @property
    def archive(self):
        """Returns the archive with which this submitter is to work."""
        return self._archive

    @property
    def build_home(self):
        """Returns the temporary (or build space) root directory."""
        return self._build_home

    @property
    def xnat_pbs_jobs_home(self):
        """Returns the home directory for the XNAT PBS job scripts."""
        return self._xnat_pbs_jobs_home

    @property
    def log_dir(self):
        """Returns the log directory in which to place put logs."""
        return self._log_dir

    def submit_jobs(self, 
                    username, password, server,
                    project, subject, session,
                    structural_reference_project, structural_reference_session,
                    put_server, clean_output_resource_first, setup_script, 
                    incomplete_only, scan = None):
        """Submit job(s) to perform IcaFixProcessing for HCP 7T data for specified subject.

        Parameters related to connecting to ConnectomeDB 

        :param username: ConnectomeDB username
        :type username: str

        :param password: ConnectomeDB password
        :type password: str

        :param server: ConnectomeDB server
        :type server: str

        Parameters that specify the subject for which to run the processing

        :param project: ConnectomeDB project
        :type project: str

        :param subject: ConnectomeDB subject ID
        :type subject: str

        :param session: ConnectomeDB session
        :type session: str

        Parameters that specify where additional information about the subject can be found
        in other projects and sessions

        :param structural_reference_project: ConnectomeDB structural reference project
        :type structural_reference_project: str

        :param structural_reference_session: ConnectomeDB structural reference session
        :type structural_reference_session: str

        Other miscellaneous parameters

        :param put_server: PUT server
        :type put_server: str

        :param clean_output_resource_first: indication of whether output resource 
                                            should be deleted prior to starting processing
        :type clean_output_resource_first: bool

        :param setup_script: path to set up script
        :type setup_script: str 

        :param incomplete_only: indication of whether to submit jobs for incomplete scans only
        :type incomplete_only: bool

        :param scan: indication of scan to process. If None, then process all scans that should
                     have ICA FIX processing done for this subject.
        :type scan: str
        """
        
        subject_info = hcp7t_subject.Hcp7TSubjectInfo(project, structural_reference_project, subject)

        # determine names of the preprocessed resting state scans that are available for the subject
        resting_state_scan_names = self.archive.available_resting_state_preproc_names(subject_info)
        inform("Preprocessed resting state scans available for subject: " + str(resting_state_scan_names))

        # determine names of the preprocessed MOVIE task scans that are available for the subject
        movie_scan_names = self.archive.available_movie_preproc_names(subject_info)
        inform("Preprocessed movie scans available for subject " + str(movie_scan_names))

        scan_list = []
        if scan == None:
            scan_list = resting_state_scan_names + movie_scan_names
        else:
            scan_list.append(scan)

        for scan_name in scan_list:
            if self.archive.FIX_processed(subject_info, scan_name) and incomplete_only:
                inform("scan: " + scan_name + " is already FIX processed")
                inform("Only submitted jobs for incomplete scans - skipping " + scan_name)
                continue

            long_scan_name = self.archive.functional_scan_long_name(scan_name)
            output_resource_name = self.archive.FIX_processed_resource_name(scan_name)

            inform("")
            inform("-------------------------------------------------")
            inform("Submitting jobs for scan: " + long_scan_name)
            inform("Output resource name: " + output_resource_name)
            inform("-------------------------------------------------")
            inform("")

            # make sure working directories don't have the same name based on the
            # same start time by sleeping a few seconds
            time.sleep(5)

            current_seconds_since_epoch = int(time.time())

            working_directory_name = self.build_home
            working_directory_name += os.sep + project 
            working_directory_name += os.sep + self.PIPELINE_NAME
            working_directory_name += '.' + subject 
            working_directory_name += '.' + long_scan_name 
            working_directory_name += '.' + str(current_seconds_since_epoch)

            # make the working directory
            inform("Making working directory: " + working_directory_name)
            os.makedirs(name=working_directory_name)

            # get JSESSION ID
            jsession_id = xnat_access.get_jsession_id(
                server   = 'db.humanconnectome.org',
                username = username,
                password = password)
            inform("jsession_id: " + jsession_id)

            # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
            xnat_session_id = xnat_access.get_session_id(
                server   = 'db.humanconnectome.org',
                username = username,
                password = password,
                project  = project,
                subject  = subject,
                session  = session)

            inform("xnat_session_id: " + xnat_session_id)

            # get XNAT Workflow ID
            workflow_obj = xnat_access.Workflow(username, password, server, jsession_id)
            workflow_id = workflow_obj.create_workflow(xnat_session_id, project, self.PIPELINE_NAME, 'Queued')

            inform("workflow_id: " + workflow_id)

            # Clean the output resource if requested
            if clean_output_resource_first: 
                inform("Deleting resource: " + output_resource_name + " for:")
                inform("  project: " + project)
                inform("  subject: " + subject)
                inform("  session: " + session)

                # re-implement this functionality as a Python class or function to be called?
                delete_resource_cmd = self.xnat_pbs_jobs_home + os.sep + 'WorkingDirPut' + os.sep + 'DeleteResource.sh'
                delete_resource_cmd += ' --user=' + username
                delete_resource_cmd += ' --password=' + password
                delete_resource_cmd += ' --server=' + get_server_name(server)
                delete_resource_cmd += ' --project=' + project
                delete_resource_cmd += ' --subject=' + subject
                delete_resource_cmd += ' --session=' + session
                delete_resource_cmd += ' --resource=' + output_resource_name
                delete_resource_cmd += ' --force'

                completed_delete_process = subprocess.run(delete_resource_cmd, shell=True, check=True)

            script_file_start_name = working_directory_name
            script_file_start_name += os.sep + subject 
            script_file_start_name += '.' + long_scan_name 
            script_file_start_name += '.' + self.PIPELINE_NAME 
            script_file_start_name += '.' + project 
            script_file_start_name += '.' + session 

            # Create script to submit to set up data
            # setup_script_name = script_file_start_name + '.DATA_SETUP_job.sh'
            # with contextlib.suppress(FileNotFoundError):
            #     os.remove(setup_script_name)
                
            # setup_script = open(setup_script_name, 'w')
            
            # setup_script.write('#PBS -l nodes-1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
            # setup_script.write('#PBS -o ' + working_directory_name + os.linesep)
            # setup_script.write('#PBS -e ' + working_directory_name + os.linesep)
            # setup_script.write(os.linesep)

            # setup_script.close()
            # os.chmod(setup_script_name, stat.S_IRWXU | stat.S_IRWXG)
                        
            # Create script to submit to do the actual work
            work_script_name = script_file_start_name + '.XNAT_PBS_job.sh'
            with contextlib.suppress(FileNotFoundError):
                os.remove(work_script_name)

            work_script = open(work_script_name, 'w')

            work_script.write('#PBS -l nodes=1:ppn=1,walltime=36:00:00,mem=40gb,vmem=55gb' + os.linesep)
            work_script.write('#PBS -o ' + working_directory_name + os.linesep)
            work_script.write('#PBS -e ' + working_directory_name + os.linesep)
            work_script.write(os.linesep)
            work_script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep + 'IcaFixProcessingHCP7T' + os.sep + 'IcaFixProcessingHCP7T.XNAT.sh \\' + os.linesep)
            work_script.write('  --user="' + username +'" \\' + os.linesep)
            work_script.write('  --password="' + password + '" \\' + os.linesep)
            work_script.write('  --server="' + get_server_name(server) + '" \\' + os.linesep)
            work_script.write('  --project="' + project + '" \\' + os.linesep)
            work_script.write('  --subject="' + subject + '" \\' + os.linesep)
            work_script.write('  --session="' + session + '" \\' + os.linesep)
            work_script.write('  --structural-reference-project="' + structural_reference_project + '" \\' + os.linesep)
            work_script.write('  --structural-reference-session="' + structural_reference_session + '" \\' + os.linesep)
            work_script.write('  --scan="' + long_scan_name + '" \\' + os.linesep)
            work_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
            work_script.write('  --workflow-id="' + workflow_id + '" \\' + os.linesep)
            work_script.write('  --xnat-session-id=' + xnat_session_id + '\\' + os.linesep)
            work_script.write('  --setup-script=' + setup_script + os.linesep)

            work_script.close()
            os.chmod(work_script_name, stat.S_IRWXU | stat.S_IRWXG)

            # Create script to put the results into the DB
            put_script_name = script_file_start_name + '.XNAT_PBS_PUT_job.sh'
            with contextlib.suppress(FileNotFoundError):
                os.remove(put_script_name)

            put_script = open(put_script_name, 'w')

            put_script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
            put_script.write('#PBS -q HCPput' + os.linesep)
            put_script.write('#PBS -o ' + self.log_dir + os.linesep)
            put_script.write('#PBS -e ' + self.log_dir + os.linesep)
            put_script.write(os.linesep)
            put_script.write(self.xnat_pbs_jobs_home + os.sep + 'WorkingDirPut' + os.sep + 'XNAT_working_dir_put.sh \\' + os.linesep)
            put_script.write('  --user="' + username +'" \\' + os.linesep)
            put_script.write('  --password="' + password + '" \\' + os.linesep)
            put_script.write('  --server="' + get_server_name(put_server) + '" \\' + os.linesep)
            put_script.write('  --project="' + project + '" \\' + os.linesep)
            put_script.write('  --subject="' + subject + '" \\' + os.linesep)
            put_script.write('  --session="' + session + '" \\' + os.linesep)
            put_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
            put_script.write('  --resource-suffix="' + output_resource_name + '"' + os.linesep)
            put_script.write('  --reason="' + scan_name + '_' + self.PIPELINE_NAME + '"' + os.linesep)

            put_script.close()
            os.chmod(put_script_name, stat.S_IRWXU | stat.S_IRWXG)

            # Submit the job to do the work
            work_submit_cmd = 'qsub ' + work_script_name
            inform("work_submit_cmd: " + work_submit_cmd)

            completed_work_submit_process = subprocess.run(work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
            inform("work_job_no: " + work_job_no)

            # Submit the job put the results in the DB
            put_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + put_script_name
            inform("put_submit_cmd: " + put_submit_cmd)

            completed_put_submit_process = subprocess.run(put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE, universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            inform("put_job_no: " + put_job_no)

if __name__ == "__main__":

    # create an Hcp7T_Archive object
    archive = hcp7t_archive.Hcp7T_Archive()

    # create a parser object for getting the command line options
    parser = MyArgumentParser(description="Program to submit ICA+FIX processing jobs for one HCP 7T subject.")

    # mandatory arguments
    parser.add_argument("-u"  , "--user", dest="user", required=True, type=str)
    parser.add_argument("-pw" , "--password", dest="password", required=True, type=str)
    parser.add_argument("-sub", "--subject", dest="subject", required=True, type=str)
    parser.add_argument("-srp", "--structural-reference-project", dest="structural_reference_project", required=True, type=str)
    parser.add_argument("-ss" , "--setup-script", dest="setup_script", required=True, type=str)

    # optional arguments
    parser.add_argument("-ser", "--server", dest="server", required=False, default="db.humanconnectome.org", type=str)
    parser.add_argument("-pr" , "--project", dest="project", required=False, default="HCP_Staging_7T", type=str)
    parser.add_argument("-ses", "--session", dest="session", required=False, default=None, type=str)
    parser.add_argument("-srs", "--structural-reference-session", dest="structural_reference_session", required=False, default=None, type=str)
    parser.add_argument("-ps" , "--put-server", dest="put_server", required=False, default="db.humanconnectome.org", type=str)
    parser.add_argument("-dnc", "--do-not-clean-first", action="store_false", dest="clean_output_resource_first", required=False, default=True)
    parser.add_argument("-io" , "--incomplete-only", action="store_true", dest="incomplete_only", required=False, default=False)
    parser.add_argument("-sc" , "--scan", required=False, default=None, type=str)

    # parse the comment line arguments
    args = parser.parse_args()

    if args.session == None:
        args.session = args.subject + archive.NAME_DELIMITER + archive.TESLA_SPEC

    if args.structural_reference_session == None:
        args.structural_reference_session = args.subject + archive.NAME_DELIMITER + '3T'

    # show parsed arguments
    inform("ConnectomeDB Username: " + args.user)
    inform("ConnectomeDB Password: " + "*** password mask ***")
    inform("ConnectomeDB Server: "   + args.server)
    inform("ConnectomeDB Project: "  + args.project)
    inform("ConnectomeDB Subject: "  + args.subject)
    inform("ConnectomeDB Session: "  + args.session)
    inform("ConnectomeDB Structural Reference Project: " + args.structural_reference_project)
    inform("ConnectomeDB Structural Reference Session: " + args.structural_reference_session)
    inform("PUT Server: " + args.put_server)
    inform("Clean output resource first: " + str(args.clean_output_resource_first))
    inform("Set up Script: " + args.setup_script)
    inform("Run incomplete scans only: " + str(args.incomplete_only))
    inform("Scan: " + str(args.scan))

    # create a submitter
    submitter = IcaFix7TOneSubjectSubmitter(archive, archive.build_home)

    # submit jobs for specified subject
    submitter.submit_jobs(args.user, args.password, args.server,
                          args.project, args.subject, args.session,
                          args.structural_reference_project, args.structural_reference_session,
                          args.put_server, args.clean_output_resource_first, args.setup_script, 
                          args.incomplete_only, args.scan)

