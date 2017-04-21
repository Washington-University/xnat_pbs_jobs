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
module_logger.setLevel(logging.WARNING)  # Note: This can be overriddent by log file configuration.
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
		COMPUTE_PLATFORM = os.getenv('COMPUTE', self.DEFAULT_COMPUTE_PLATFORM)
		module_logger.debug("COMPUTE_PLATFORM = " + COMPUTE_PLATFORM)
		XNAT_DATA_ROOT = os.getenv('XNAT_DATA_ROOT')
		module_logger.debug("XNAT_DATA_ROOT = " + str(XNAT_DATA_ROOT))
		
		if XNAT_DATA_ROOT:
			print("xnat_archive.py: ---------------------------------------")
			print("xnat_archive.py: IMPORTANT IMPORTANT IMPORTANT IMPORTANT")
			print("xnat_archive.py: ")
			print("xnat_archive.py:  XNAT_DATA_ROOT is set to " + XNAT_DATA_ROOT )
			print("xnat_archive.py:  I AM USING THAT AS AN OVERRIDE VALUE  ")
			print("xnat_archive.py:  FOR THE XNAT ARCHIVE'S DATA ROOT !!!  ")
			print("xnat_archive.py:  THIS SHOULD NEVER BE HAPPENING IN A   ")
			print("xnat_archive.py:  PRODUCTION RUN. THIS IS FOR TESTING   ")
			print("xnat_archive.py:  PURPOSES ONLY!!!                      ")
			print("xnat_archive.py: ")
			print("xnat_archive.py: IMPORTANT IMPORTANT IMPORTANT IMPORTANT")
			print("xnat_archive.py: ---------------------------------------")

			self._data_root = XNAT_DATA_ROOT
		else:
			if COMPUTE_PLATFORM == 'CHPC':
				self._data_root = '/HCP'
			elif COMPUTE_PLATFORM == 'NRG':
				self._data_root = '/data'
			elif COMPUTE_PLATFORM == 'TIMS_DESKTOP':
				self._data_root = '/home/tbb/mnt/fs01/data'
			else:
				raise ValueError('Unrecognized value for COMPUTE environment variable: ' + COMPUTE_PLATFORM)

		module_logger.debug("self.data_root = " + self.data_root)
		
	@property
	def data_root(self):
		"""Returns the path to the root of all data."""
		return self._data_root
	
	@property
	def archive_root(self):
		"""Returns the path to the root of the archive."""
		return self.data_root + '/hcpdb/archive'

	@property
	def build_space_root(self):
		"""Returns the temporary build/processing directory root."""
		COMPUTE_PLATFORM = os.getenv('COMPUTE', self.DEFAULT_COMPUTE_PLATFORM)
		module_logger.debug("COMPUTE_PLATFORM = " + COMPUTE_PLATFORM)
		BUILD_DIR = os.getenv('BUILD_DIR')
		module_logger.debug("BUILD_DIR = " + str(BUILD_DIR))
		
		if BUILD_DIR:
			return_value = BUILD_DIR
		else:
			if COMPUTE_PLATFORM == 'CHPC':
				return_value = self.data_root + '/hcpdb/build_ssd/chpc/BUILD'
			elif COMPUTE_PLATFORM == 'NRG':
				return_value = self.data_root + '/hcpdb/build_ssd/chpc/BUILD'
			elif COMPUTE_PLATFORM == 'TIMS_DESKTOP':
				return_value = self.data_root + '/hcpdb/build_ssd/chpc/BUILD'

		module_logger.debug("build_space_root = " + return_value)
		return return_value
	
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
	project_name = 'CCF_AGING'
	
	print('archive_root: ' + archive.archive_root)
	print('project_archive_root(\'' + project_name + '\'): ' + archive.project_archive_root(project_name))
	print('project_resources_root(\'' + project_name + '\'): ' + archive.project_resources_root(project_name))
	print('build_space_root: ' + archive.build_space_root)

if __name__ == "__main__":
	logging.config.fileConfig(
		file_utils.get_logging_config_file_name(__file__),
		disable_existing_loggers=False)
	_simple_interactive_demo()
