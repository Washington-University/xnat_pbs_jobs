#!/usr/bin/env python3

# import of built-in modules
import platform
import os

# import of third-party modules

# import of local modules
import hcp.hcp7t.multirun_icafix.one_subject_job_submitter as one_subject_job_submitter

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker():

    def __init__(self):
        super().__init__()
        
    @property
    def PIPELINE_NAME(self):
        return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    def _path_to_running_marker_file(self, subject_info):

        running_status_dir = os.getenv('XNAT_PBS_JOBS_RUNNING_STATUS_DIR')
        if not running_status_dir:
            raise RuntimeError("Environment variable XNAT_PBS_JOBS_RUNNING_STATUS_DIR must be set")

        file_name = self.PIPELINE_NAME
        file_name += '.' + subject_info.project
        file_name += '_' + subject_info.subject_id
        file_name += '_' + '7T'
        file_name += '_' + subject_info.extra
        file_name += '.' + 'RUNNING'

        path = running_status_dir + os.sep + subject_info.project + os.sep + file_name
        return path

    def get_queued_or_running(self, subject_info):
        return os.path.exists(self._path_to_running_marker_file(subject_info))

    def get_run_status(self, subject_info):

        session_name = subject_info.subject_id + '_' + '7T'

        USER = os.getev('USER')
        if not USER:
            raise RuntimeError("Environment variable USER must be set")

        qstat_running_cmd = 'qstat -u ' + USER
        qstat_running_cmd += ' | grep ' + subject_info.subject_id + '.MultiRunI'
        qstat_running_cmd += ' | grep " R "'

        qstat_stream = platform.popen(qstat_running_cmd, "r")
        qstat_results = qstat_stream.readline()
        qstat_stream.close()

        if qstat_results:
            return 'R'

        qstat_queued_cmd = 'qstat -u ' + USER
        qstat_queued_cmd += ' | grep ' + subject_info.subject_id + '.MultiRunI'
        qstat_queued_cmd += ' | grep " Q "'

        qstat_stream = platform.popen(qstat_queued_cmd, "r")
        qstat_results = qstat_stream.readline()
        qstat_stream.close()

        if qstat_results:
            return 'Q'

        return None
