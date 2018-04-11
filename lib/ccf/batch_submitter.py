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
        return 1

    @property
    def MAX_SHADOW_NUMBER(self):
        """Maximum shadow server number."""
        return 2

    @property
    def BAD_SHADOW_LIST(self):
        """
        List of shadow numbers in the MIN_SHADOW_NUMBER to MAX_SHADOW_NUMBER range that are
        currently unusable.

        NB: If this list contains all number from MIN_SHADOW_NUMBER to MAX_SHADOW_NUMBER, then
        the get_and_inc_shadow_number method will go into infinte recursion. So...DON"T DO THAT!
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

    def check_already_queued(self, subject, run_status_checker):
        """Check whether jobs are already queued and report.

        Note:
            In addition to checking the running status, this method also
            reports information to the user if jobs are already queued
            or running.

        Args:
            subject: CCF subject to check
            run_status_checker: (OneSubjectRunStatusChecker) 
        
        Returns:
            True if jobs are already queued or running for the specified subject
            False otherwise

        """

        if run_status_checker.get_queued_or_running(subject):
            print("-----")
            print("\t NOT SUBMITTING JOBS FOR")
            print("\t               project: " + subject.project)
            print("\t               subject: " + subject.subject_id)
            print("\t    session classifier: " + subject.classifier)
            print("\t JOBS ARE ALREADY QUEUED OR RUNNING")
            
            return True
        
        else:
            return False
        
    @abc.abstractmethod
    def submit_jobs(self, subject_list):
        """
        Submit a batch of jobs for the specified subjects in the subject_list.
        """
        module_logger.error("Calling abstract method submit_jobs")
