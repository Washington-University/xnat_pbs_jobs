#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import ccf.one_subject_prereq_checker
import ccf.subject as ccf_subject
import ccf.archive as ccf_archive
import utils.my_argparse as my_argparse


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectPrereqChecker(ccf.one_subject_prereq_checker.OneSubjectPrereqChecker):

	def __init__(self):
		super().__init__()

	def are_prereqs_met(self, archive, subject_info, verbose=False):

		struct_unproc_dir_names = archive.available_structural_unproc_names(subject_info)

		count_of_t1w_resources = 0
		count_of_t2w_resources = 0
		
		for name in struct_unproc_dir_names:
			if name.startswith('T1w'):
				count_of_t1w_resources += 1
			if name.startswith('T2w'):
				count_of_t2w_resources += 1
				
		
		# does at least 1 T1w unprocessed resource exist and
		# at least 1 T2w unprocessed resource exist
		return (count_of_t1w_resources > 0) and (count_of_t2w_resources > 0)

if __name__ == "__main__":
	parser = my_argparse.MyArgumentParser(description="Program to check prerequisites for the Structural Preprocessing.")
	# mandatory arguments
	parser.add_argument('-p', '--project', dest='project', required=True, type=str)
	parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
	parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)

	# parse the command line arguments
	args = parser.parse_args()
	archive = ccf_archive.CcfArchive()
	subject = ccf_subject.SubjectInfo(args.project, args.subject, args.classifier)
	prereq_checker = OneSubjectPrereqChecker()
	print("checking subject: " + str(subject), end=" - ")

	if (prereq_checker.are_prereqs_met(archive, subject, True)):
		print("Prerequisites Met")
	else:
		print("Prerequisites NOT Met")
