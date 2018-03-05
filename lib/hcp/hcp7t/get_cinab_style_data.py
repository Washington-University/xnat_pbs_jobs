#!/usr/bin/env python3
"""
hcp.hcp7t.get_cinab_style_data.py: Get (copy or link) a CinaB style directory tree of
data for a specified subject within a specified project.
"""


# import of built-in modules
import logging
import os
import sys
import subprocess

# import of third party modules

# import of local modules
import hcp.get_cinab_style_data
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject
import utils.my_argparse as my_argparse
import hcp.hcp3t.get_cinab_style_data as hcp3t_data_retriever


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

# create and configure a module logger
log = logging.getLogger(__file__)
log.setLevel(logging.WARNING)
sh = logging.StreamHandler(sys.stdout)
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)


class CinabStyleDataRetriever(hcp.get_cinab_style_data.CinabStyleDataRetriever):

    def __init__(self, archive_7T, archive_3T):
        super().__init__(archive_7T)
        self._reference_archive = archive_3T
        self._reference_data_retriever = hcp3t_data_retriever.CinabStyleDataRetriever(self._reference_archive)

    def get_unproc_data(self, subject_info, output_study_dir):

        self.get_functional_unproc_data(subject_info, output_study_dir)
        self.get_diffusion_unproc_data(subject_info, output_study_dir)

    def get_supplemental_structural_preproc_data(self, subject_info, output_study_dir):
        # supplemental structural preprocessed data for HCP 7T subjects
        # is in the (3T) structural reference archive and project
        reference_3T_subject = hcp3t_subject.Hcp3TSubjectInfo(
            subject_info.structural_reference_project, subject_info.subject_id, subject_info.extra)
        self._reference_data_retriever.get_supplemental_structural_preproc_data(
            reference_3T_subject, output_study_dir)
        
    def get_structural_preproc_data(self, subject_info, output_study_dir):
        # structural preprocessed data for HCP 7T subjects
        # is in the (3T) structural reference archive and project
        reference_3T_subject = hcp3t_subject.Hcp3TSubjectInfo(
            subject_info.structural_reference_project, subject_info.subject_id, subject_info.extra)
        self._reference_data_retriever.get_structural_preproc_data(
            reference_3T_subject, output_study_dir)
        
    def get_preproc_data(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_diffusion_preproc_data(subject_info, output_study_dir)
            self.get_functional_preproc_data(subject_info, output_study_dir)
            self.get_supplemental_structural_preproc_data(subject_info, output_study_dir)
            self.get_structural_preproc_data(subject_info, output_study_dir)
            
        else:
            # when copying (via rsync), should be done in chronological order
            self.get_structural_preproc_data(subject_info, output_study_dir)
            self.get_supplemental_structural_preproc_data(subject_info, output_study_dir)
            self.get_functional_preproc_data(subject_info, output_study_dir)
            self.get_diffusion_preproc_data(subject_info, output_study_dir)

    def get_multirunicafix_prereqs(self, subject_info, output_dir):
        """
        Get the data necessary to run the MultiRunICAFIX pipeline
        """
        if self.copy:
            # when copying (via rsync), data should be retrieved in chronological order
            # (i.e. the order in which the pipelines are run)
            self.get_unproc_data(subject_info, output_dir)
            self.get_preproc_data(subject_info, output_dir)

        else:
            # when creating symbolic links, data should be retrieved in reverse
            # chronological order
            self.get_preproc_data(subject_info, output_dir)
            self.get_unproc_data(subject_info, output_dir)
            
    def get_full_data(self, subject_info, output_study_dir):
        # TODO: there is more to do here, this is not a complete copy

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_resting_state_stats_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info,  output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info,  output_study_dir)

        else:
            # when copying (via rsync), should be done in chronological order
            self.get_unproc_data(subject_info,  output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info,  output_study_dir)
            self.get_resting_state_stats_data(subject_info, output_study_dir)

    def get_data_through_ICAFIX(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_icafix_data(subject_info,  output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info,  output_study_dir)

        else:
            # when copying (via rsync), should be done in chronological order
            self.get_unproc_data(subject_info,  output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info,  output_study_dir)

    def get_data_through_multirun_ICAFIX(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_multirun_icafix_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)
        else:
            # when copying (via rsync), should be done in chronological order
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_multirun_icafix_data(subject_info, output_study_dir)

    def get_data_through_PostFix(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_postfix_data(subject_info, output_study_dir)
            self.get_multirun_icafix_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)
        else:
            # when copying (via rsync), should be done in chronological order
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_multirun_icafix_data(subject_info, output_study_dir)
            self.get_postfix_data(subject_info, output_study_dir)
            
    def remove_non_subdirs(self, directory):
        cmd = 'find ' + directory + ' -maxdepth 1 -not -type d -print -delete'
        completed_process = subprocess.run(
            cmd, shell=True, check=True, stdout=subprocess.PIPE,
            universal_newlines=True)
        return
    

def main():
    # create a parser object for getting the command line arguments
    parser = my_argparse.MyArgumentParser()

    # mandatory arguments
    parser.add_argument('-p', '--project',     dest='project',            required=True, type=str)
    parser.add_argument('-s', '--subject',     dest='subject',            required=True, type=str)
    parser.add_argument('-d', '--study-dir',   dest='output_study_dir',   required=True, type=str)
    parser.add_argument('-t', '--structural-reference-project', dest='structural_reference_project',
                        required=True, type=str)

    # optional arguments
    parser.add_argument('-c', '--copy', dest='copy', action='store_true', required=False, default=False)
    parser.add_argument('-l', '--log', dest='log', action='store_true', required=False, default=False)
    parser.add_argument('-r', '--remove-non-subdirs', dest='remove_non_subdirs', action='store_true',
                        required=False, default=False)
    parser.add_argument('-j', '--remove-job-and-catalog-files', dest='remove_job_and_catalog_files',
                        action='store_true', required=False, default=False)
    
    phase_choices = [
        "FULL", "full",
        "DIFFUSION_PREPROC_VETTING", "diffusion_preproc_vetting",
        "MULTIRUNICAFIX_PREREQS", "multirunicafix_prereqs",
        "ICAFIX", "icafix",
        "MULTIRUNICAFIX", "multirunicafix",
        "POSTFIX", "postfix"
    ]

    parser.add_argument('-ph', '--phase', dest='phase', required=False,
                        choices=phase_choices, default="full")

    # parse the command line arguments
    args = parser.parse_args()
    
    # show arguments
    log.info("Arguments:")
    log.info("                Project: " + args.project)
    log.info(" Structural Ref Project: " + args.structural_reference_project)
    log.info("                Subject: " + args.subject)
    log.info("       Output Study Dir: " + args.output_study_dir)
    log.info("                   Copy: " + str(args.copy))
    log.info("                  Phase: " + args.phase)
    log.info("                    Log: " + str(args.log))
    log.info("     Remove Non-Subdirs: " + str(args.remove_non_subdirs))
    
    subject_info = hcp7t_subject.Hcp7TSubjectInfo(
        project=args.project,
        structural_reference_project=args.structural_reference_project,
        subject_id=args.subject)
    archive = hcp7t_archive.Hcp7T_Archive()
    reference_archive = hcp3t_archive.Hcp3T_Archive()
    
    # create and configure CinabStyleDataRetriever
    data_retriever = CinabStyleDataRetriever(archive, reference_archive)
    data_retriever.copy = args.copy
    data_retriever.show_log = args.log

    # retrieve data based on phase requested

    args.phase = args.phase.upper()
    
    if args.phase == "FULL":
        data_retriever.get_full_data(subject_info, args.output_study_dir)

    elif args.phase == "DIFFUSION_PREPROC_VETTING":
        data_retriever.get_diffusion_preproc_vetting_data(subject_info, args.output_study_dir)

    elif args.phase == "MULTIRUNICAFIX_PREREQS":
        data_retriever.get_multirunicafix_prereqs(subject_info, args.output_study_dir)
        
    elif args.phase == "ICAFIX":
        data_retriever.get_data_through_ICAFIX(subject_info, args.output_study_dir)

    elif args.phase == "MULTIRUNICAFIX":
        data_retriever.get_data_through_multirun_ICAFIX(subject_info, args.output_study_dir)

    elif args.phase == "POSTFIX":
        data_retriever.get_data_through_PostFix(subject_info, args.output_study_dir)

    if args.remove_non_subdirs:
        # remove any non-subdirectory data at the output study directory level
        data_retriever.remove_non_subdirs(args.output_study_dir)
        data_retriever.remove_non_subdirs(args.output_study_dir + os.sep + subject_info.subject_id)

    if args.remove_job_and_catalog_files:
        # remove any PBS job files and XNAT catalog files
        data_retriever.remove_pbs_job_files(args.output_study_dir)
        data_retriever.remove_xnat_catalog_files(args.output_study_dir)
        
if __name__ == '__main__':
    main()
