#!/usr/bin/env python3

"""
batch_submitter.py: Abstract base class for an object that submits batches of
pipeline processing jobs for HCP projects.
"""

# import of built-in modules
import abc
import logging

# import of third-party modules

# import of local modules
import ccf.batch_submitter

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)

class BatchSubmitter(ccf.batch_submitter.BatchSubmitter):
	"""
	This class is an abstract base class for classes that are used to submit jobs for 
	one pipeline for a batch of subjects for the HCP project.
	"""

	def __init__(self, archive):
		"""Construct a BatchSubmitter"""
		super().__init__(archive)
		
	@abc.abstractmethod
	def submit_jobs(self, subject_list):
		"""
		Submit a batch of jobs for the specified subjects in the subject list.
		"""
		module_logger.error("Calling abstract method submit_jobs")
