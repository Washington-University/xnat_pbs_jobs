#!/usr/bin/env python3

# import of built-in modules
import os
import sys

# import of third-party modules

# import of local modules
import ccf.archive as ccf_archive
import ccf.one_subject_completion_checker
import ccf.subject
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class OneSubjectCompletionChecker(ccf.one_subject_completion_checker.OneSubjectCompletionChecker):

    def __init__(self):
        super().__init__()

    def my_resource(self, archive, subject_info):
        return archive.structural_preproc_dir_full_path(subject_info)
    
    def does_processed_resource_exist(self, archive, subject_info):
        fullpath = self.my_resource(archive, subject_info)
        return os.path.isdir(fullpath)

    def is_processing_complete(self, archive, subject_info, verbose=False):
        # If the processed resource does not exist, then the process is certainly not complete.
        if not self.does_processed_resource_exist(archive, subject_info):
            if verbose:
                print("resource: " + self.my_resource(archive, subject_info) + " DOES NOT EXIST")
            return False

        # Build a list of expected files
        file_name_list = []

        # <subject-i>/MNINonLinear
        check_dir = os.sep.join([archive.structural_preproc_dir_full_path(subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.164k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.164k_fs_LR.dlable.nii')
                              
        # TO DO - more files to check - once you have successful run to use as a model


        return self.do_all_files_exist(file_name_list, verbose)
        

if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(description="Program to check for completion of Structural Preprocessing.")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
    parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)

    # optional arguments
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', required=False,
                        default=False)
    
    # parse the command line arguments
    args = parser.parse_args()

    # check the specified subject for structural preprocessing completion
    archive = ccf_archive.CcfArchive()
    subject_info = ccf.subject.SubjectInfo(args.project, args.subject, args.classifier)
    completion_checker = OneSubjectCompletionChecker()

    if completion_checker.is_processing_complete(archive, subject_info, args.verbose):
        sys.exit(0)
    else:
        sys.exit(1)
        

