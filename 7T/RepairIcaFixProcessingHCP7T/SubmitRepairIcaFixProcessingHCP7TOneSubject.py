#!/usr/bin/env python3

"""
SubmitRepairIcaFixProcessingHCP7TOneSubject.py: Submit Repair ICA+FIX processing jobs
for one HCP 7T subject. 
"""

# import of build-in modules
import contextlib
import os
import stat
import subprocess
import time

# import of third-party modules

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import hcp.one_subject_job_submitter as one_subject_job_submitter
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2018, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def inform(msg):
    print(os.path.basename(__file__) + ": " + msg)


class RepairIcaFixProcessing7TOneSubjectJobSubmitter(one_subject_job_submitter.OneSubjectJobSubmitter):

    def __init__(self, hcp7t_archive, build_home):
        super().__init__(hcp7t_archive, build_home)
        
    @property
    def PIPELINE_NAME(self):
        return "RepairIcaFixProcessingHCP7T"

    def create_put_script(self, put_script_name, username, password, put_server, project, subject, session,
                          working_directory_name, output_resource_name, reason, leave_subject_id_level=False):

        with contextlib.suppress(FileNotFoundError):
            os.remove(put_script_name)
            
        put_script = open(put_script_name, 'w')

        put_script.write('#PBS -l nodes=1:ppn=1,walltime=4:00:00,vmem=12gb' + os.linesep)
        put_script.write('#PBS -q HCPput' + os.linesep)
        put_script.write('#PBS -o ' + self.log_dir + os.linesep)
        put_script.write('#PBS -e ' + self.log_dir + os.linesep)
        put_script.write(os.linesep)

        put_script.write(self.xnat_pbs_jobs_home + os.sep + 'WorkingDirPut' + os.sep + 'XNAT_working_dir_files_put.sh \\' + os.linesep)

        put_script.write('  --user="' + username + '" \\' + os.linesep)
        put_script.write('  --password="' + password + '" \\' + os.linesep)
        put_script.write('  --server="' + str_utils.get_server_name(put_server) + '" \\' + os.linesep)
        put_script.write('  --project="' + project + '" \\' + os.linesep)
        put_script.write('  --subject="' + subject + '" \\' + os.linesep)
        put_script.write('  --session="' + session + '" \\' + os.linesep)
        put_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
        put_script.write('  --resource-suffix="' + output_resource_name + '" \\' + os.linesep)
        put_script.write('  --reason="' + self.PIPELINE_NAME + '" \\' + os.linesep)

        if leave_subject_id_level:
            put_script.write('  --leave-subject-id-level' + os.linesep)
        else:
            put_script.write(os.linesep)

        put_script.close()
        os.chmod(put_script_name, stat.S_IRWXU | stat.S_IRWXG)
    
    def submit_jobs(self,
                    username, password, server,
                    project, subject, session,
                    structural_reference_project, structural_reference_session,
                    put_server, setup_script,
                    incomplete_only, scan,
                    walltime_limit_hours, mem_limit_gbs, vmem_limit_gbs):

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
        if scan is None:
            scan_list = resting_state_scan_names + movie_scan_names
        else:
            scan_list.append(scan)

        # process the specified scans
        for scan_name in scan_list:
            if incomplete_only and self.archive.FIX_processing_repaired(subject_info, scan_name):
                inform("scan: " + scan_name + " FIX processing is already repaired")
                inform("Only submitting jobs for incomplete scans - skipping " + scan_name)
                continue

            long_scan_name = self.archive.functional_scan_long_name(scan_name)
            output_resource_name = self.archive.FIX_processed_resource_name(scan_name)

            inform("")
            inform("-------------------------------------------------")
            inform("Submitting jobs for scan: " + long_scan_name)
            inform("Output resource name: " + output_resource_name)
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

            inform("Making working directory: " + working_directory_name)
            os.makedirs(name=working_directory_name)

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

            work_script.write('#PBS -l nodes=1:ppn=1,walltime=' + str(walltime_limit_hours) + ':00:00,mem=' + str(mem_limit_gbs) +
                              'gb,vmem=' + str(vmem_limit_gbs) + 'gb' + os.linesep)
            work_script.write('#PBS -o ' + working_directory_name + os.linesep)
            work_script.write('#PBS -e ' + working_directory_name + os.linesep)
            work_script.write(os.linesep)
            work_script.write(self.xnat_pbs_jobs_home + os.sep + '7T' + os.sep + self.PIPELINE_NAME + os.sep +
                              self.PIPELINE_NAME + '.XNAT.sh \\' + os.linesep)
            work_script.write('  --user="' + username + '" \\' + os.linesep)
            work_script.write('  --password="' + password + '" \\' + os.linesep)
            work_script.write('  --server="' + str_utils.get_server_name(server) + '" \\' + os.linesep)
            work_script.write('  --project="' + project + '" \\' + os.linesep)
            work_script.write('  --subject="' + subject + '" \\' + os.linesep)
            work_script.write('  --session="' + session + '" \\' + os.linesep)
            work_script.write('  --structural-reference-project="' + structural_reference_project + '" \\' + os.linesep)
            work_script.write('  --structural-reference-session="' + structural_reference_session + '" \\' + os.linesep)
            work_script.write('  --scan="' + long_scan_name + '" \\' + os.linesep)
            work_script.write('  --working-dir="' + working_directory_name + '" \\' + os.linesep)
            work_script.write('  --setup-script=' + setup_script + os.linesep)
            
            work_script.close()
            os.chmod(work_script_name, stat.S_IRWXU | stat.S_IRWXG)

            # Create script to put the results into the DB
            put_script_name = script_file_start_name + '.XNAT_PBS_PUT_job.sh'
            self.create_put_script(put_script_name,
                                   username, password, put_server,
                                   project, subject, session,
                                   working_directory_name, output_resource_name,
                                   scan_name + '_' + self.PIPELINE_NAME,
                                   leave_subject_id_level=True)

            # Submit the job to do the work
            work_submit_cmd = 'qsub ' + work_script_name
            inform("work_submit_cmd: " + work_submit_cmd)

            completed_work_submit_process = subprocess.run(work_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                                                           universal_newlines=True)
            work_job_no = str_utils.remove_ending_new_lines(completed_work_submit_process.stdout)
            inform("work_job_no: " + work_job_no)

            # Submit the job put the results in the DB
            put_submit_cmd = 'qsub -W depend=afterok:' + work_job_no + ' ' + put_script_name
            inform("put_submit_cmd: " + put_submit_cmd)

            completed_put_submit_process = subprocess.run(put_submit_cmd, shell=True, check=True, stdout=subprocess.PIPE,
                                                          universal_newlines=True)
            put_job_no = str_utils.remove_ending_new_lines(completed_put_submit_process.stdout)
            inform("put_job_no: " + put_job_no)
            
