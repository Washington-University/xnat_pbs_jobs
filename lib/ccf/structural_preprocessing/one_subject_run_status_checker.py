#!/usr/bin/env python3

# import of built-in modules
#import subprocess
import platform
import os

# import of third-party modules

# import of local modules

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker():

    def __init__(self):
        super().__init__()

    def _path_to_running_marker_file(self, subject_info):

        running_status_dir = os.getenv('XNAT_PBS_JOBS_RUNNING_STATUS_DIR')
        if not running_status_dir:
            raise RuntimeError("Environment variable XNAT_PBS_JOBS_RUNNING_STATUS_DIR must be set")
        
        processing_name = 'StructuralPreprocessing'

        file_name = processing_name
        file_name += '.' + subject_info.subject_id
        file_name += '_' + subject_info.classifier
        file_name += '.' + 'RUNNING'

        path = running_status_dir + os.sep + subject_info.project + os.sep + file_name

        return path
            
    def get_queued_or_running(self, subject_info):
        return os.path.exists(self._path_to_running_marker_file(subject_info))
    
    def get_run_status(self, subject_info):

        processing_name = 'StructuralPreprocessing'
        session_name = subject_info.subject_id + '_' + subject_info.classifier
        
        USER = os.getenv('USER')
        if not USER:
            raise RuntimeError("Environment variable USER must be set")

        qstat_running_cmd = 'qstat -u ' + USER + ' | grep ' + subject_info.subject_id + '.Struc' + ' | grep " R "'

        qstat_stream = platform.popen(qstat_running_cmd, "r")
        qstat_results = qstat_stream.readline()
        qstat_stream.close()

        if qstat_results:
            return 'R'

        qstat_queued_cmd = 'qstat -u ' + USER + ' | grep ' + subject_info.subject_id + '.Struc' + ' | grep " Q "'
        
        qstat_stream = platform.popen(qstat_queued_cmd, "r")
        qstat_results = qstat_stream.readline()
        qstat_stream.close()

        if qstat_results:
            return 'Q'

        return None
    
