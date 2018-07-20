#!/usr/bin/env python3

"""
batch_submitter.py: Abstract base class for an object that submits batches of
pipeline processing jobs for CCF projects.
"""

# import of built-in modules
import abc
import logging
import random

# import of third-party modules

# import of local modules
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility (CCF)"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overidden by log file configuration


class BatchSubmitter(abc.ABC):
    """
    This class is an abstract base class for classes that are used to submit jobs for
    one pipeline for a batch of subjects.
    """

    @property
    def MIN_SHADOW_NUMBER(self):
        """Minimum shadow server number."""
        # return 1
        min_shadow_str=os_utils.getenv_required("XNAT_PBS_JOBS_MIN_SHADOW")
        return int(min_shadow_str)

    @property
    def MAX_SHADOW_NUMBER(self):
        """Maximum shadow server number."""
        # return 2
        max_shadow_str=os_utils.getenv_required("XNAT_PBS_JOBS_MAX_SHADOW")
        return int(max_shadow_str)

    @property
    def BAD_SHADOW_LIST(self):
        """
        List of shadow numbers in the MIN_SHADOW_NUMBER to MAX_SHADOW_NUMBER range that are
        currently unusable.

        NB: If this list contains all numbers from MIN_SHADOW_NUMBER to MAX_SHADOW_NUMBER, then
        the get_and_inc_shadow_number method will go into infinte recursion. So...DO NOT DO THAT!
        """
        bad_shadow_list = list()
        return bad_shadow_list

    def __init__(self, archive):
        """Construct a BatchSumitter"""
        self._archive = archive
        self._shadow_number = random.randint(self.MIN_SHADOW_NUMBER, self.MAX_SHADOW_NUMBER)

    @property
    def shadow_number(self):
        """shadow number"""
        return self._shadow_number

    def increment_shadow_number(self):
        """
        Increments the current shadow number and cycles it around if it goes passed the maximum.
        """
        module_logger.debug("increment_shadow_number: orig shadow_number: " + str(self._shadow_number))
        self._shadow_number = self._shadow_number + 1
        if self._shadow_number > self.MAX_SHADOW_NUMBER:
            self._shadow_number = self.MIN_SHADOW_NUMBER
        module_logger.debug("increment_shadow_number:  new shadow_number: " + str(self._shadow_number))

    def get_and_inc_shadow_number(self):
        current = self.shadow_number
        self.increment_shadow_number()
        if current in self.BAD_SHADOW_LIST:
            return self.get_and_inc_shadow_number()
        else:
            return current

    def get_shadow_prefix(self):
        xnat_server = os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER')
        if xnat_server == 'db.humanconnectome.org':
            put_server_root = 'http://db-shadow'
        elif xnat_server == 'intradb.humanconnectome.org':
            put_server_root = 'http://intradb-shadow'
        else:
            raise ValueError("Unrecognized XNAT_PBS_JOBS_XNAT_SERVER: " + xnat_server)

        return put_server_root

    def get_shadow_suffix(self):
        return '.nrg.mir:8080'
        
    @abc.abstractmethod
    def submit_jobs(self, subject_list):
        """
        Submit a batch of jobs for the specified subjects in the subject_list.
        """
        module_logger.error("Calling abstract method submit_jobs")
