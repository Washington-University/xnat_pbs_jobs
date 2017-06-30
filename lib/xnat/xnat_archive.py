#!/usr/bin/env python3

"""
xnat/xnat_archive.py: Provide information to allow direct access to an XNAT data archive.
"""

# import of built-in modules
import logging
import logging.config
import os

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016-2017, Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# create a module logger
module_logger = logging.getLogger(__name__)
module_logger.setLevel(logging.WARNING)  # Note: This can be overridden by log file configuration.
module_logger.setLevel(logging.INFO)  # Note: This can be overriddent by log file configuration.


class XNAT_Archive:
	"""This class provides information about direct access to an XNAT data archive.

	This access goes 'behind the scenes' and uses the actual underlying file system.
	Because of this, a change in XNAT implementation could cause this code to no longer
	be correct.
	"""

	@property
	def DEFAULT_COMPUTE_PLATFORM(self):
		"""The default value used for the compute platform.

		If the COMPUTE environment is not set, this value is used.
		"""
		return 'CHPC'

	def __init__(self):
		"""Constructs an XNAT_Archive object for direct access to an XNAT data archive."""
		module_logger.debug("xnat_archive.__init__")

	@property
	def archive_root(self):
		"""Returns the path to the root of the archive."""
		XNAT_PBS_JOBS_ARCHIVE_ROOT = os.getenv('XNAT_PBS_JOBS_ARCHIVE_ROOT')
		module_logger.debug("XNAT_PBS_JOBS_ARCHIVE_ROOT = " + str(XNAT_PBS_JOBS_ARCHIVE_ROOT))

		if not XNAT_PBS_JOBS_ARCHIVE_ROOT:
			raise RuntimeError("Environment variable XNAT_PBS_JOBS_ARCHIVE_ROOT must be set")

		return XNAT_PBS_JOBS_ARCHIVE_ROOT

	@property
	def build_space_root(self):
		"""Returns the path to the temporary build/processing directory root."""
		XNAT_PBS_JOBS_BUILD_DIR = os.getenv('XNAT_PBS_JOBS_BUILD_DIR')
		module_logger.debug("XNAT_PBS_JOBS_BUILD_DIR = " + str(XNAT_PBS_JOBS_BUILD_DIR))

		if not XNAT_PBS_JOBS_BUILD_DIR:
			raise RuntimeError("Environment variable XNAT_PBS_JOBS_BUILD_DIR must be set")

		return XNAT_PBS_JOBS_BUILD_DIR
	
	def project_archive_root(self, project_name):
		"""Returns the path to the specified project's root directory in the archive.

		:param project_name: name of the project in the XNAT archive
		:type project_name: str
		"""
		par = self.archive_root + os.sep + project_name + os.sep + 'arc001'
		return par

	def project_resources_root(self, project_name):
		"""Returns the path to the specified project's root project-level resources directory in the archive.

		:param project: name of the project in the XNAT archive
		:type project_name: str
		"""
		return self.archive_root + '/' + project_name + '/resources'


def _simple_interactive_demo():
	archive = XNAT_Archive()
	project_name = 'HCP_Staging'
	
	print('archive_root: ' + archive.archive_root)
	print('project_archive_root(\'' + project_name + '\'): ' + archive.project_archive_root(project_name))
	print('project_resources_root(\'' + project_name + '\'): ' + archive.project_resources_root(project_name))
	print('build_space_root: ' + archive.build_space_root)

if __name__ == "__main__":
	logging.config.fileConfig(
		file_utils.get_logging_config_file_name(__file__, False),
		disable_existing_loggers=False)
	_simple_interactive_demo()
