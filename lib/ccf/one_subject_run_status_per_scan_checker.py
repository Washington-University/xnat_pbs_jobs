#!/usr/bin/env python3

# import of built-in modules
import os

# import of third-party modules

# import of local modules
import ccf.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.archive as ccf_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectRunStatusPerScanChecker(one_subject_run_status_checker.OneSubjectRunStatusChecker):
	"""Determine the run status for a CCF pipeline that is run on each scan.

	This class is an abstract run status checker for pipelines that are run
	separately on a set of scans for a subject/session. See the superclass for
	further documentation.
	"""

	def _path_to_running_marker_file(self, subject_info):

		file_name = self.PIPELINE_NAME
		file_name += '.' + subject_info.subject_id
		file_name += '_' + subject_info.classifier
		file_name += '_' + subject_info.extra
		file_name += '.' + 'RUNNING'

		archive = ccf_archive.CcfArchive()
		self.running_status_dir = archive.running_status_dir_full_path(subject_info)
		path = self.running_status_dir + os.sep + file_name
		#print("path: " + path)
		return path
		