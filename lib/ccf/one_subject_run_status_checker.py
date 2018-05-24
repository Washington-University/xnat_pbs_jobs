#!/usr/bin/env python3

"""
ccf/one_subject_run_status_checker.py: Abstract base class for an object
that checks to see if a pipeline run is currently submitted or running
for one subject.
"""

# import of built-in modules
import abc
import os

# import of third-party modules

# import of local modules
import utils.os_utils as os_utils
import ccf.archive as ccf_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility (CCF)"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusChecker(abc.ABC):
	"""Determine the run status for a subject for a CCF pipeline.

	This class is an abstract base class for classes that are used to check for
	the run status for one pipeline for one subject/session.

	The implemented methods of this abstract class assume that there will be one
	set of jobs for the pipeline for each subject/session (e.g. Structural
	Preprocessing or Diffusion Preprocessing that have one pipeline run per
	subject/session).  This is as opposed to pipelines that have independent
	pipeline runs per scan within a subject/session (e.g. Functional
	Preprocessing).

	There are two potential ways to determine the run status of a pipeline for a
	given subject.

	First, the get_run_status method can be used to simply determine whether a
	'running marker' file exists for the pipeline for the specified
	subject. Such a 'running marker' file will be in the directory specified in
	the XNAT_PBS_JOBS_RUNNING_STATUS_DIR environment variable.  The 'running
	marker' file name is determined by combining the pipeline name with
	information about the specified subject to come up with a unique name for
	the pipeline and subject. Using this method, you simply get a boolean return
	value indicating whether the set of jobs are marked as currently
	queued/running. In this view, a queued set of jobs is effectively the same
	as a running set of jobs.

	The second technique, implemented in the get_run_status method, is to
	actually interact with the queuing system to determine if jobs for the
	subject have been submitted and, if so, what state the jobs are currently
	in: running ('R') or queued ('Q'). This method should return None if there
	is no job either running or queued for the specified subject; should return
	'R' if there are running jobs; and should return 'Q' if there are submitted
	jobs that are not (yet) actually running.

	This second method can be very tricky to implement (as it depends on the
	underlying queuing system and perhaps on names of queued jobs) and,
	importantly, can be very time consuming to run.  Thus it is acceptable for a
	subclass of this abstract class to either not implement the get_run_status
	method or implement it such that it returns some string such as 'IDONTKNOW'.
	"""

	@property
	@abc.abstractmethod
	def PIPELINE_NAME(self):
		raise NotImplementedError()

	def _path_to_running_marker_file(self, subject_info):
		"""Return the full path to the marker file for the specified subject."""

		file_name = self.PIPELINE_NAME
		file_name += '.' + subject_info.subject_id
		file_name += '_' + subject_info.classifier
		file_name += '.' + 'RUNNING'
 
		archive = ccf_archive.CcfArchive()
		self.running_status_dir = archive.running_status_dir_full_path(subject_info)
		path = self.running_status_dir + os.sep + file_name
		
		#print("path: " + path)		
		return path

	def get_queued_or_running(self, subject_info):
		"""Whether the pipeline is marked as running for specified subject.

		The result of this check is determined based upon whether the is a
		"mark" indicating that the pipeline is running for the specified
		subject. This is in contrast to checking based upon interaction with the
		underlying queuing system.
		"""
		return os.path.exists(self._path_to_running_marker_file(subject_info))

	def get_run_status(self, subject_info):
		"""Indication of job status for the specified subject.

		The result of this check is determined by interacting with the
		underlying queuing system in order to determine whether a job is queued
		or running.

		This method should return an 'R' if there is a job running on the
		queuing system for the specified subject. It should return an 'Q' if
		there is a job sitting in the queue but not yet running for the
		specified subject.

		If there is no job either running or queued, this method should return
		None.
		"""
		raise NotImplementedError()
	
