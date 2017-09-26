#!/usr/bin/env python3

# import of built-in modules
import os

# import of third-party modules

# import of local modules
import ccf.one_subject_completion_checker as one_subject_completion_checker
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.multirun_icafix.one_subject_job_submitter as one_subject_job_submitter
import hcp.hcp7t.subject as hcp7t_subject
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    @property
    def PIPELINE_NAME(self):
        return one_subject_job_submitter.OneSubjectJobSubmitter.MY_PIPELINE_NAME()

    def my_resource(self, archive, subject_info):
        return archive.multirun_icafix_proc_dir_full_path(subject_info)

    def my_prerequisite_dir_full_paths(self, archive, subject_info):
        return archive.available_retinotopy_preproc_dir_full_paths(subject_info)

    def completion_marker_file_name(self):
        return self.PIPELINE_NAME + '.XNAT_CHECK.success'

    def starttime_marker_file_name(self):
        return self.PIPELINE_NAME + '.starttime'

    def list_of_expected_files(self, archive, subject_info):

        l = []

        subj_dir = os.sep.join([self.my_resource(archive, subject_info), subject_info.subject_id])


        # ...
        
        return l

    
if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(
        description="Program to check for completion of 7T MultiRunICAFIX7THCP Processing.")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)

    # optional arguments
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
                        required=False, default=False)
    parser.add_argument('-o', '--output', dest='output', required=False, type=str)
    parser.add_argument('-a', '--check-all', dest='check_all', action='store_true',
                        required=False, default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # check the specified subject for processing completion
    archive = hcp7t_archive.Hcp7T_Archive()
    subject_info = hcp7t_subject.SubjectInfo(project=args.project, subject_id=args.subject)
    completion_checker = OneSubjectCompletionChecker()

    if args.output:
        processing_output = open(args.output, 'w')
    else:
        processing_output = sys.stdout

    if completion_checker.is_processing_complete(
            archive=archive,
            subject_info=subject_info,
            verbose=args.verbose,
            output=processing_output,
            short_circuit=not args.check_all):
        print("Exiting with 0 code - Completion Check Successful")
        exit(0)
    else:
        print("Exiting with 1 code - Completion Check Unsuccessful")
        exit(1)
