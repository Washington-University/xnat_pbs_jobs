#!/usr/bin/env python3

"""
SubmitIcaFixProcessingHCP7TOneSubject.py: Submit ICA+FIX processing jobs 
for one HCP 7T subject.
"""

# import of built-in modules
import contextlib
import os
import stat
import subprocess
import time

# import of third party modules
pass

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
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

def inform(msg):
    """Outputs a message that is prefixed by the module file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)

class IcaFix7TOneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):
    """This class submits a set of dependent jobs for ICA+FIX processing 
    for a single HCP 7T subject."""

    def __init__(self, hcp7t_archive, build_home):
        """Constructs an IcaFix7TOneSubjectJobSubmitter.

        :param hcp7t_archive: HCP 7T Archive
        :type hcp7t_archive: Hcp7T_Archive

        :param build_home: path to build space
        :type build_home: str
        """
        super().__init__(hcp7t_archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "IcaFixProcessingHCP7T"

    def submit_jobs(self, 
                    username, password, server,
                    project, subject, session,
                    structural_reference_project, structural_reference_session,
                    put_server, clean_output_resource_first, setup_script, 
                    incomplete_only, scan, 
                    walltime_limit_hours,
                    mem_limit_gbs,
                    vmem_limit_gbs):
        """Submit job(s) to perform IcaFixProcessing for HCP 7T data for the
        specified subject.

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

        Parameters that specify where additional information about the subject 
        can be found in other projects and sessions

        :param structural_reference_project: ConnectomeDB structural reference 
                                             project
        :type structural_reference_project: str

        :param structural_reference_session: ConnectomeDB structural reference 
                                             session
        :type structural_reference_session: str

        Other miscellaneous parameters

        :param put_server: PUT server
        :type put_server: str

        :param clean_output_resource_first: indication of whether output resource 
                                            should be deleted prior to starting 
                                            processing
        :type clean_output_resource_first: bool

        :param setup_script: path to set up script
        :type setup_script: str 

        :param incomplete_only: indication of whether to submit jobs for 
                                incomplete scans only
        :type incomplete_only: bool

        :param scan: indication of scan to process. If None, then process all 
                     scans that should have ICA FIX processing done for this 
                     subject.
        :type scan: str

        :param walltime_limit_hrs: the walltime limit (specified in hours) for 
                                   the processing job
        :type walltime_limit_hrs: int

        :param mem_limit_gbs: the memory limit (specified in GBs) for the processing 
                              job
        :type mem_limit_gbs: int

        :param vmem_limit_gbs: the virtual memory limit (specified in GBs) for 
                               the processing job
        :type vmem_limit_gbs: int                     
        """
        
        subject_info = hcp7t_subject.Hcp7TSubjectInfo(project, 
                                                      structural_reference_project,
                                                      subject)

        # determine names of the preprocessed resting state scans that are 
        # available for the subject
        resting_state_scan_names = self.archive.available_resting_state_preproc_names(subject_info)
        inform("Preprocessed resting state scans available for subject: " + 
               str(resting_state_scan_names))

        # determine names of the preprocessed MOVIE task scans that are available for the subject
        movie_scan_names = self.archive.available_movie_preproc_names(subject_info)
        inform("Preprocessed movie scans available for subject " + str(movie_scan_names))

        # build list of scans to process
        scan_list = []
        if scan == None:
            scan_list = resting_state_scan_names + movie_scan_names
        else:
            scan_list.append(scan)

        # process specified scans
        for scan_name in scan_list:
            if incomplete_only and self.archive.FIX_processing_complete(subject_info, scan_name):
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
                
                delete_resource.delete_resource(
                    username, password, str_utils.get_server_name(server), 
                    project, subject, session, output_resource_name)

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

            work_script.write('#PBS -l nodes=1:ppn=1,walltime=' + str(walltime_limit_hours) + ':00:00,mem=' + str(mem_limit_gbs) + 'gb,vmem=' + str(vmem_limit_gbs) + 'gb' + os.linesep)
            work_script.write('#PBS -o ' + working_directory_name + os.linesep)
            work_script.write('#PBS -e ' + working_directory_name + os.linesep)
            work_script.write(os.linesep)
            work_script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep + 'IcaFixProcessingHCP7T' + os.sep + 'IcaFixProcessingHCP7T.XNAT.sh \\' + os.linesep)
            work_script.write('  --user="' + username +'" \\' + os.linesep)
            work_script.write('  --password="' + password + '" \\' + os.linesep)
            work_script.write('  --server="' + str_utils.get_server_name(server) + '" \\' + os.linesep)
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
            self.create_put_script(put_script_name, 
                                   username, password, put_server, 
                                   project, subject, session, 
                                   working_directory_name, output_resource_name,
                                   scan_name + '_' + self.PIPELINE_NAME)

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

