#!/usr/bin/env python3

"""hcp/subject.py: Maintain information about an HCP subject."""

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
# None

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
	"""
	Inform the user by writing out a message that is prefixed by the module's
	file name.
	"""
	print(os.path.basename(__file__) + ": " + msg)


class HcpSubjectInfo:
	"""This class maintains information about an HCP subject."""
	
	@classmethod
	def DEFAULT_SEPARATOR(cls):
		return ":"
	
	def __init__(self, project=None, subject_id=None, extra=None):
		"""Constructs an HcpSubjectInfo object.
		
		:param project: project to which this subject belongs (e.g. HCP_500)
		:type project: str
		
		:param subject_id: subject ID (e.g. 100307)
		:type subject_id: str
		
		:param extra: extra information used for processing the subject
		:type extra: str
		"""
		self._subject_id = subject_id
		self._project = project
		self._extra = extra
		
	@property
	def subject_id(self):
		"""Subject ID"""
		return self._subject_id
	
	@property
	def project(self):
		"""Primary project"""
		return self._project
	
	@property
	def extra(self):
		"""Extra processing information"""
		return self._extra
	
	def __str__(self):
		"""Returns the informal string representation."""
		separator = HcpSubjectInfo.DEFAULT_SEPARATOR()
		return str(self.project + separator + 
				   self.subject_id + separator + 
				   str(self.extra))


def _simple_interactive_demo():

	_inform("-- Creating 2 HcpSubjectInfo objects --")
	subject_info1 = HcpSubjectInfo('HCP_900', '100206')
	subject_info2 = HcpSubjectInfo('HCP_500', '100307')
	
	_inform("-- Showing the HcpSubjectInfo objects --")
	print(str(subject_info1))
	print(str(subject_info2))


if __name__ == '__main__':
	_simple_interactive_demo()
