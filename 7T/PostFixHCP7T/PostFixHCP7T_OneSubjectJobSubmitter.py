#!/usr/bin/env python3

"""
PostFixHCP7T_OneSubjectJobSubmitter.py: Submit PostFixHCP7T processing jobs for one
HCP 7T subject.
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
import PostFixHCP7T_OneSubjectCompletionChecker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.delete_resource as delete_resource
import utils.my_argparse as my_argparse
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


class PostFixHCP7T_OneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):
    """This class submits a set of dependent jobs for PostFixHCP7T processing for
    a single HCP 7T subject."""

    def __init__(self, hcp7t_archive, build_home):
        """Constructs a PostFixHCP7TOneSubjectJobSubmitter.

        :param hcp7t_archive: HCP 7T Archive
        :type hcp7t_archive: Hcp7T_Archive

        :param build_home: path to build space
        :type build_home: str
        """
        super().__init__(hcp7t_archive, build_home)

    @property
    def PIPELINE_NAME(self):
        return "PostFixHCP7T"

    def submit_jobs(self,
                    username, password, server,
                    project, subject, session,
                    structural_reference_project, structural_reference_session,
                    put_server, clean_output_resource_first, setup_script,
                    incomplete_only, scan,
                    walltime_limit_hours,
                    mem_limit_gbs,         # UNUSED
                    vmem_limit_gbs):

        subject_info = hcp7t_subject.Hcp7TSubjectInfo(project,
                                                      structural_reference_project,
                                                      subject)

        # determine names of preprocessed resting state scans that are
        # available for the subject
        preproc_resting_state_scan_names = self.archive.available_resting_state_preproc_names(subject_info)
        inform("Preprocessed resting state scans available for subject: " +
               str(preproc_resting_state_scan_names))

        # determine names of the preprocessed MOVIE task scans that are available for the subject
        preproc_movie_scan_names = self.archive.available_movie_preproc_names(subject_info)
        inform("Preprocessed movie scans available for subject " + str(preproc_movie_scan_names))

        # determine names of the FIX processed scans that are available for the subject
        fix_processed_scan_names = self.archive.available_FIX_processed_names(subject_info)
        inform("FIX processed scans available for subject " + str(fix_processed_scan_names))

        # build list of scans to process
        scan_list = []
        if scan is None:
            scan_list = fix_processed_scan_names
        else:
            scan_list.append(scan)

        # process specified scans
        for scan_name in scan_list:
            if incomplete_only:
                completion_checker = PostFixHCP7T_OneSubjectCompletionChecker.PostFixHCP7T_OneSubjectCompletionChecker()
                if completion_checker.is_processing_complete(self.archive, subject_info, scan_name):
                    inform("scan: " + scan_name + " has already completed PostFixHCP7T processing")
                    inform("Only submitting jobs for incomplete scans - skipping " + scan_name)
                    continue

            inform("scan_name: " + scan_name)
            long_scan_name = self.archive.functional_scan_long_name(scan_name)
            output_resource_name = self.archive.PostFix_processed_resource_name(scan_name)

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
                server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                username=username,
                password=password)
            inform("jsession_id: " + jsession_id)

            # get XNAT Session ID (a.k.a. the experiment ID, e.g. ConnectomeDB_E1234)
            xnat_session_id = xnat_access.get_session_id(
                server=os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                username=username,
                password=password,
                project=project,
                subject=subject,
                session=session)

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

            # Create script to submit to do the actual work
            work_script_name = script_file_start_name + '.XNAT_PBS_job.sh'
            with contextlib.suppress(FileNotFoundError):
                os.remove(work_script_name)

            work_script = open(work_script_name, 'w')

            nodes_spec = 'nodes=1:ppn=1'
            walltime_spec = 'walltime=' + str(walltime_limit_hours) + ':00:00'
            vmem_spec = 'vmem=' + str(vmem_limit_gbs) + 'gb'

            work_script.write('#PBS -l ' + nodes_spec + ',' + walltime_spec + ',' + vmem_spec + os.linesep)
            work_script.write('#PBS -o ' + working_directory_name + os.linesep)
            work_script.write('#PBS -e ' + working_directory_name + os.linesep)
            work_script.write(os.linesep)
            work_script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep + 'PostFixHCP7T' + os.sep +
                              'PostFixHCP7T.XNAT.sh \\' + os.linesep)
            work_script.write('  --user="' + username + '" \\' + os.linesep)
            work_script.write('  --password="' + password + '" \\' + os.linesep)
            work_script.write('  --server="' + str_utils.get_server_name(server) + '" \\' + os.linesep)
            work_script.write('  --project="' + project + '" \\' + os.linesep)
            work_script.write('  --subject="' + subject + '" \\' + os.linesep)
            work_script.write('  --session="' + session + '" \\' + os.linesep)
            work_script.write('  --scan="' + long_scan_name + '" \\' + os.linesep)
            work_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
            work_script.write('  --workflow-id="' + workflow_id + '" \\' + os.linesep)
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

            completed_work_submit_process = subprocess.run(work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                                                           universal_newlines=True)
            work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
            inform("work_job_no: " + work_job_no)

            # Submit the job to put the results in the DB
            put_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + put_script_name
            inform("put_submit_cmd: " + put_submit_cmd)

            completed_put_submit_process = subprocess.run(put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                                                          universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            inform("put_job_no: " + put_job_no)
