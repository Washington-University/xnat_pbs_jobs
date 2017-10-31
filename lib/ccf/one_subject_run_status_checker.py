#!/usr/bin/env python3

"""
ccf/one_subject_run_status_checker.py: Abstract base class for an object
that checks to see if a pipeline run is currently submitted or running
for one subject.
"""

# import of built-in modules
import abc
import logging
import os

# import of third-party modules

# import of local modules
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility (CCF)"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
# Note: This can be overridden by log file configuration
module_logger.setLevel(logging.WARNING)


class OneSubjectRunStatusChecker(abc.ABC):
    """
    This class is an abstract base class for classes that are used to check 
    for the run status for one pipeline for one subject.
    """

    def __init__(self):
        self._running_status_dir = os_utils.getenv_required('XNAT_PBS_JOBS_RUNNING_STATUS_DIR')

    @property
    @abc.abstractmethod
    def PIPELINE_NAME(self):
        raise NotImplementedError()

    def path_to_running_marker_file(self, subject_info):
        """
        return the full path to the marker file used to indicate that the 
        pipeline is running for the specified subject
        """

        file_name = self.PIPELINE_NAME
        file_name += '.' + subject_info.subject_id
        file_name += '_' + subject_info.classifier
        file_name += '.' + 'RUNNING'

        path = self._running_status_dir + os.sep + subject_info.project + os.sep + file_name

        return path

    def get_queued_or_running(self, subject_info):
        """
        return an indication (boolean) of whether the pipeline is running for the specified subject.

        The result of this check is determined based upon whether the is a "mark" indicating
        that the pipeline is running for the specified subject. This is in contrast to checking
        based upon interaction with the underlying queuing system.
        """
        return os.path.exists(self.path_to_running_marker_file(subject_info))

    @abc.abstractmethod    
    def get_run_status(self, subject_info):
        """
        return an indication of a job status for the specified subject.

        The result of this check is determined by interacting with the underlying queuing system
        in order to determine whether a job is queued or running.

        This method should return an 'R' if there is a job running on the queuing system for the
        specified subject. It should return an 'Q' if there is a job sitting in the queue but not
        yet running for the specified subject.

        If there is no job either running or queued, this method should return None.
        """
        raise NotImplementedError()
    
