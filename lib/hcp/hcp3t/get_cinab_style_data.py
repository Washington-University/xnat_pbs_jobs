#!/usr/bin/env python3
"""
hcp.hcp3t.get_cinab_style_data.py: Get (copy or link) a CinaB style directory tree of data
for a specified subject within a specified project.
"""


# import of built-in modules
import logging
import os
import sys
import subprocess


# import of third party modules
# None


# import of local modules
import hcp.get_cinab_style_data
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils


# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


# create and configure a module logger
log = logging.getLogger(__file__)
# log.setLevel(logging.WARNING)
log.setLevel(logging.INFO)
sh = logging.StreamHandler(sys.stdout)
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
# sh.setFormatter(logging.Formatter('[%(filename)s:%(lineno)s - %(funcName)20s()] %(message)s'))
log.addHandler(sh)


class CinabStyleDataRetriever(hcp.get_cinab_style_data.CinabStyleDataRetriever):

    def __init__(self, archive):
        super().__init__(archive)

    def get_structural_unproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_structural_unproc_dir_fullpaths(subject_info):

            get_from = directory

            last_sep_loc = get_from.rfind(os.sep)
            unproc_loc = get_from.rfind('_' + self.archive.UNPROC_SUFFIX)
            sub_dir = get_from[last_sep_loc+1:unproc_loc]
            put_to = output_study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + \
                os.sep + self.archive.TESLA_SPEC + os.sep + sub_dir

            self._from_to(get_from, put_to)

    def get_unproc_data(self, subject_info, output_study_dir):

        self.get_structural_unproc_data(subject_info, output_study_dir)
        self.get_functional_unproc_data(subject_info, output_study_dir)
        self.get_diffusion_unproc_data(subject_info, output_study_dir)

    def get_structural_preproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_structural_preproc_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

    def get_supplemental_structural_preproc_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_supplemental_structural_preproc_dir_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)

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

    def get_data_through_STRUCT_PREPROC(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order
            self.get_supplemental_structural_preproc_data(subject_info, output_study_dir)
            self.get_structural_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)

        else:
            # when copying (via rsync), should be done in chronological ordere
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_structural_preproc_data(subject_info, output_study_dir)
            self.get_supplemental_structural_preproc_data(subject_info, output_study_dir)

    def get_data_through_DIFFUSION_PREPROC(self, subject_info, output_study_dir):

        if not self.copy:
            self.get_diffusion_preproc_data(subject_info, output_study_dir)
            self.get_data_through_STRUCT_PREPROC(subject_info, output_study_dir)

        else:
            self.get_data_through_STRUCT_PREPROC(subject_info, output_study_dir)
            self.get_diffusion_preproc_data(subject_info, output_study_dir)






    def get_full_data(self, subject_info, output_study_dir):

        if not self.copy:
            # when creating symbolic links (copy == False), must be done in reverse
            # chronological order

            self.get_handreclassification_data(subject_info, output_study_dir)
            self.get_bedpostx_data(subject_info, output_study_dir)
            self.get_msmall_dedrift_and_resample_data(subject_info, output_study_dir)
            self.get_msmall_reg_data(subject_info, output_study_dir)
            self.get_resting_state_stats_data(subject_info, output_study_dir)
            self.get_postfix_data(subject_info, output_study_dir)
            self.get_taskfmri_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_unproc_data(subject_info, output_study_dir)

        else:
            # when copying (via rsync), should be done in chronological order
            self.get_unproc_data(subject_info, output_study_dir)
            self.get_preproc_data(subject_info, output_study_dir)
            self.get_icafix_data(subject_info, output_study_dir)
            self.get_taskfmri_data(subject_info, output_study_dir)
            self.get_postfix_data(subject_info, output_study_dir)
            self.get_resting_state_stats_data(subject_info, output_study_dir)
            self.get_msmall_reg_data(subject_info, output_study_dir)
            self.get_msmall_dedrift_and_resample_data(subject_info, output_study_dir)
            self.get_bedpostx_data(subject_info, output_study_dir)
            self.get_handreclassification_data(subject_info, output_study_dir)

    def get_diffusion_bedpostx_data(self, subject_info, output_study_dir):

        for directory in self.archive.available_bedpostx_fullpaths(subject_info):

            get_from = directory
            put_to = output_study_dir + os.sep + subject_info.subject_id
            self._from_to(get_from, put_to)


def main():
    # create a parser object for getting the command line arguments
    parser = my_argparse.MyArgumentParser()

    # mandatory arguments
    parser.add_argument('-p', '--project',   dest='project',          required=True, type=str)
    parser.add_argument('-s', '--subject',   dest='subject',          required=True, type=str)
    parser.add_argument('-d', '--study-dir', dest='output_study_dir', required=True, type=str)

    # optional arguments
    parser.add_argument('-c',  '--copy',  dest='copy',  action='store_true', required=False, default=False)

    phase_choices = ["FULL", "full",
                     "DIFFUSION_PREPROC_VETTING", "diffusion_preproc_vetting", 
                     "STRUCT_PREPROC", "struct_preproc",
                     "DIFFUSION_PREPROC", "diffusion_preproc",
                     "DIFFUSION_BEDPOSTX", "diffusion_bedpostx"]
    default_phase_choice = phase_choices[0]

    parser.add_argument('-ph', '--phase', dest='phase', required=False,
                        choices=phase_choices, default=default_phase_choice)

    # parse the command line arguments
    args = parser.parse_args()

    # show arguments
    log.info("Arguments:")
    log.info("          Project: " + args.project)
    log.info("          Subject: " + args.subject)
    log.info(" Output Study Dir: " + args.output_study_dir)
    log.info("             Copy: " + str(args.copy))
    log.info("            Phase: " + args.phase)

    subject_info = hcp3t_subject.Hcp3TSubjectInfo(args.project, args.subject)
    archive = hcp3t_archive.Hcp3T_Archive()

    # create and configure CinabStyleDataRetriever
    data_retriever = CinabStyleDataRetriever(archive)
    data_retriever.copy = args.copy
    data_retriever.show_log = False

    # retrieve data based on phase requested
    if (args.phase.upper() == "FULL"):
        data_retriever.get_full_data(subject_info, args.output_study_dir)
        #data_retriever.clean_xnat_specific_files(args.output_study_dir)

    elif (args.phase.upper() == "DIFFUSION_PREPROC_VETTING"):
        data_retriever.get_diffusion_preproc_vetting_data(subject_info, args.output_study_dir)
        #data_retriever.clean_xnat_specific_files(args.output_study_dir)

    elif (args.phase.upper() == "STRUCT_PREPROC"):
        data_retriever.get_data_through_STRUCT_PREPROC(subject_info, args.output_study_dir)

    elif (args.phase.upper() == "DIFFUSION_PREPROC"):
        data_retriever.get_data_through_DIFFUSION_PREPROC(subject_info, args.output_study_dir)

    elif (args.phase.upper() == "DIFFUSION_BEDPOSTX"):
        data_retriever.get_diffusion_bedpostx_data(subject_info, args.output_study_dir)

if __name__ == '__main__':
    main()
