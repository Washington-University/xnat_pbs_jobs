#!/usr/bin/env python3

"""SubmitIcaFixProcessingHCP7TOneSubject.py: Submit ICA+FIX processing jobs for one HCP 7T subject."""

# import of built-in modules
import os
import sys
import argparse
import time
import contextlib

# import of third party modules
pass

# path changes and import of local modules
sys.path.append('../lib')
import hcp7t_archive
import hcp7t_subject

sys.path.append('../../lib')
import xnat_access

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
                inform("I have been asked to only submit jobs for incomplete scans - skipping")
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

                inform("  TO BE IMPLEMENTED  ")

            script_file_start_name = working_directory_name
            script_file_start_name += os.sep + subject 
            script_file_start_name += '.' + long_scan_name 
            script_file_start_name += '.' + self.PIPELINE_NAME 
            script_file_start_name += '.' + project 
            script_file_start_name += '.' + session 

            # Submit job to set up data
            # setup_data_script_file_name = script_file_start_name + '.DATA_SETUP_job.sh'
            # with contextlib.suppress(FileNotFoundError):
            #     os.remove(setup_data_script_file_name)
                
            # setup_data_script_file = open(setup_data_script_file_name, 'w')
            
            # setup_data_script_file.write("#PBS -l nodes-1:ppn=1,walltime=4:00:00,vmem=12gb" + os.linesep)
            # setup_data_script_file.write("#PBS -o " + working_directory_name + os.linesep)
            # setup_data_script_file.write("#PBS -e " + working_directory_name + os.linesep)
            # setup_data_script_file.write("")

            # setup_data_script_file.close()
            
            
            # Submit job to do the actual work
            script_file_to_do_work_name = script_file_start_name + '.XNAT_PBS_job.sh'
            with contextlib.suppress(FileNotFoundError):
                os.remove(script_file_to_do_work_name)

            script_file_to_do_work = open(script_file_to_do_work_name, 'w')

            script_file_to_do_work.write("#PBS -l nodes=1:ppn=1,walltime=36:00:00,mem=40gb,vmem=55gb" + os.linesep)
            script_file_to_do_work.write("#PBS -o " + working_directory_name + os.linesep)
            script_file_to_do_work.write("#PBS -e " + working_directory_name + os.linesep)
            script_file_to_do_work.write(os.linesep)
            script_file_to_do_work.write("${XNAT_PBS_JOBS_HOME}/7T/IcaFixProcessingHCP7T/IcaFixProcessingHCP7T.XNAT.sh \\" + os.linesep)
            script_file_to_do_work.write("  --user=\"${g_user}\" \\" + os.linesep)
            script_file_to_do_work.write("  --password=\"${g_password}\" \\" + os.linesep)
            script_file_to_do_work.write("  --server=\"${g_server}\" \\" + os.linesep)
            script_file_to_do_work.write("  --project=\"${g_project}\" \\" + os.linesep)
            script_file_to_do_work.write("  --subject=\"${g_subject}\" \\" + os.linesep)
            script_file_to_do_work.write("  --session=\"${g_session}\" \\" + os.linesep)
            script_file_to_do_work.write("  --structural-reference-project=\"${g_structural_reference_project}\" \\" + os.linesep)
            script_file_to_do_work.write("  --structural-reference-session=\"${g_structural_reference_session}\" \\" + os.linesep)
            script_file_to_do_work.write("  --scan=\"${scan}\" \\" + os.linesep)
            script_file_to_do_work.write("  --working-dir=\"${working_directory_name}\" \\" + os.linesep)
            script_file_to_do_work.write("  --workflow-id=\"${workflowID}\" \\" + os.linesep)
            script_file_to_do_work.write("  --xnat-session-id=${sessionID}  \\" + os.linesep)
            script_file_to_do_work.write("  --setup-script=${g_setup_script}"   + os.linesep)









            # Submit job to put the results into the DB









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

