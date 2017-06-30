#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_prereq_checker

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectPrereqChecker(ccf.one_subject_prereq_checker.OneSubjectPrereqChecker):

	def __init__(self):
		super().__init__()

	def are_prereqs_met(self, archive, subject_info, verbose=False):

		struct_unproc_dir_paths = archive.available_structural_unproc_names(subject_info)
		print(str(struct_unproc_dir_paths))
			  
		# does at least 1 T1w unprocessed resource exist

		
		# does at least 1 T2w unprocessed resource exist
