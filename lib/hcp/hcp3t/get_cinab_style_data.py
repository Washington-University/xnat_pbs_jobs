#!/usr/bin/env python3


# import of built-in modules
import logging
import os
import sys
#import shutil
#import distutils.dir_util
import subprocess

# import of third party modules
pass


# import of local modules
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
#log.setLevel(logging.WARNING)
log.setLevel(logging.INFO)
sh = logging.StreamHandler()
sh.setFormatter(logging.Formatter('%(name)s: %(message)s'))
log.addHandler(sh)


def _from_to(get_from, put_to, copy=False, show_log=False):
    if copy:
        os.makedirs(put_to, exist_ok=True)


        #verbose = 1 if show_log else 0
        #distutils.dir_util.copy_tree(get_from, put_to, update=True, verbose=show_log)
        #shutil.copytree(get_from, put_to)

        if show_log:
            rsync_cmd = "rsync -auv "
        else:
            rsync_cmd = "rsync -au "

        rsync_cmd += get_from + os.sep + "*" + " " + put_to
        log.info("rsync_cmd: " + rsync_cmd)

        completed_rsync_process = subprocess.run(rsync_cmd, shell=True, check=True,
                                                 stdout=subprocess.PIPE, universal_newlines=True)
        log.info(completed_rsync_process.stdout)

    else:
        os.makedirs(put_to, exist_ok=True)
        os_utils.lndir(get_from, put_to, show_log=show_log, ignore_existing_dst_files=True)


def get_structural_unproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_structural_unproc_dir_fullpaths(subject_info):

        get_from = directory

        last_sep_loc = get_from.rfind(os.sep)
        unproc_loc = get_from.rfind('_' + archive.UNPROC_SUFFIX)
        sub_dir = get_from[last_sep_loc+1:unproc_loc]
        put_to = study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + archive.TESLA_SPEC + os.sep + sub_dir

        _from_to(get_from, put_to, copy, show_log)


def get_functional_unproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_functional_unproc_dir_fullpaths(subject_info):

        get_from = directory
        
        last_sep_loc = get_from.rfind(os.sep)
        unproc_loc = get_from.rfind('_' + archive.UNPROC_SUFFIX)
        sub_dir = get_from[last_sep_loc+1:unproc_loc]
        put_to = study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + archive.TESLA_SPEC + os.sep + sub_dir

        _from_to(get_from, put_to, copy, show_log)


def get_diffusion_unproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_diffusion_unproc_dir_fullpaths(subject_info):

        get_from = directory

        last_sep_loc = get_from.rfind(os.sep)
        unproc_loc = get_from.rfind('_' + archive.UNPROC_SUFFIX)
        sub_dir = get_from[last_sep_loc+1:unproc_loc]
        put_to = study_dir + os.sep + subject_info.subject_id + os.sep + 'unprocessed' + os.sep + archive.TESLA_SPEC + os.sep + sub_dir

        _from_to(get_from, put_to, copy, show_log)

    
def get_unproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    get_structural_unproc_data(archive, subject_info, study_dir, copy, show_log)
    get_functional_unproc_data(archive, subject_info, study_dir, copy, show_log)
    get_diffusion_unproc_data(archive, subject_info, study_dir, copy, show_log)


def get_structural_preproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_structural_preproc_dir_fullpaths(subject_info):
        
        get_from = directory
        put_to = study_dir + os.sep + subject_info.subject_id
        _from_to(get_from, put_to, copy, show_log)
        

def get_supplemental_structural_preproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_supplemental_structural_preproc_dir_fullpaths(subject_info):

        get_from = directory
        put_to = study_dir + os.sep + subject_info.subject_id
        _from_to(get_from, put_to, copy, show_log)


def get_functional_preproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_functional_preproc_dir_fullpaths(subject_info):

        get_from = directory
        put_to = study_dir + os.sep + subject_info.subject_id
        _from_to(get_from, put_to, copy, show_log)


def get_diffusion_preproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    for directory in archive.available_diffusion_preproc_dir_fullpaths(subject_info):

        get_from = directory
        put_to = study_dir + os.sep + subject_info.subject_id
        _from_to(get_from, put_to, copy, show_log)


def get_preproc_data(archive, subject_info, study_dir, copy=False, show_log=False):

    if not copy:
        # when creating symbolic links (copy == False), must be done in reverse 
        # chronological order
        get_diffusion_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_functional_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_supplemental_structural_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_structural_preproc_data(archive, subject_info, study_dir, copy, show_log)

    else:
        # when copying (via rsync), should be done in chronological order
        get_structural_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_supplemental_structural_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_functional_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_diffusion_preproc_data(archive, subject_info, study_dir, copy, show_log)        
    

def get_full_data(archive, subject_info, study_dir, copy=False, show_log=False):

    if not copy:
        # when created symbolic links (copy == False), must be done in reverse
        # chronological order

        # ici get_msmall_dedrift_and_resample_data
        # ici get_msmall_reg_data
        
        # ici get_resting_state_stats_data
        # ici get_postfix_data

        # ici get_icafix_data
        # ici get_taskfmri_data
        get_preproc_data(archive, subject_info, study_dir, copy, show_log)
        get_unproc_data(archive, subject_info, study_dir, copy, show_log)

    else:
        # copy copying (via rsync), should be done in chronological order
        get_unproc_data(archive, subject_info, study_dir, copy, show_log)
        get_preproc_data(archive, subject_info, study_dir, copy, show_log)


def clean_xnat_specific_files(study_dir):
    for root, dirs, files in os.walk(study_dir):
        for filename in files:
            fullpath = '%s/%s' % (root, filename)
            xnat_catalog_suffix = 'catalog.xml'
            cat_loc = fullpath.rfind(xnat_catalog_suffix)

            provenance_marker = 'Provenance.xml'

            if cat_loc == len(fullpath) - len(xnat_catalog_suffix):
                # This is an XNAT resource catalog file. It should be removed.
                os.remove(fullpath)

            elif provenance_marker in fullpath:
                # This is a provenance file. It should be removed.
                os.remove(fullpath)


def clean_pbs_job_logs(study_dir):
    for root, dirs, files in os.walk(study_dir):
        for filename in files:
            fullpath = '%s/%s' % (root, filename)
            pbs_job_marker = 'XNAT_PBS_job'

            if pbs_job_marker in fullpath:
                os.remove(fullpath)


def main():
    # create a parser object for getting the command line arguments
    parser = my_argparse.MyArgumentParser()

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
    parser.add_argument('-d', '--study-dir', dest='study_dir', required=True, type=str)

    # optional arguments
    parser.add_argument('-c', '--copy', dest='copy', action='store_true', required=False, default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # show parsed arguments
    log.info("Parsed arguments:")
    log.info("    Project: " + args.project)
    log.info("    Subject: " + args.subject)
    log.info("  Study Dir: " + args.study_dir)

    subject_info = hcp3t_subject.Hcp3TSubjectInfo(args.project, args.subject)
    archive = hcp3t_archive.Hcp3T_Archive()

    get_full_data(archive, subject_info, args.study_dir, args.copy, show_log=True)
    clean_xnat_specific_files(args.study_dir)
    clean_pbs_job_logs(args.study_dir)




if __name__ == '__main__':
    main()
