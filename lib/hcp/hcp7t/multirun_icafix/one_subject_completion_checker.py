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

        scan = subject_info.extra

        available_retinotopy_scans = archive.available_retinotopy_preproc_names(subject_info)

        retinotopy_scan_dirs = []
        for ret_scan in available_retinotopy_scans:
            scan_type, task_type, phase_encoding_dir = ret_scan.split('_')
            retinotopy_scan_dirs.append('_'.join([scan_type, task_type, '7T', phase_encoding_dir]))

        root_dir = os.sep.join([self.my_resource(archive, subject_info), subject_info.subject_id])

        l.append(os.sep.join([root_dir, 'MNINonLinear']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results']))

        for ret_scan in retinotopy_scan_dirs:
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan]))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, 'Movement_Regressors_demean.txt']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_Atlas_demean.dtseries.nii']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_Atlas_hp2000_clean.dtseries.nii']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_Atlas_hp2000_clean.README.txt']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_Atlas_hp2000.dtseries.nii']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_demean.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000_clean.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica', 'filtered_func_data.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica', 'mc']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica', 'mc', 'prefiltered_func_data_mcf_conf_hp.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica', 'mc', 'prefiltered_func_data_mcf_conf.nii.gz']))
            l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', ret_scan, ret_scan + '_hp2000.ica', 'mc', 'prefiltered_func_data_mcf.par']))
            
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan]))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, 'Movement_Regressors_demean.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas_demean.dtseries.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas.dtseries.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas_hp2000_clean.dtseries.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas_hp2000.dtseries.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_Atlas_mean.dscalar.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_demean.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000_clean.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_SBRef.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'Atlas.dtseries.nii']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix4melview_HCP7T_hp2000_thr10.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'mask.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'mean_func.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'eigenvalues_percent']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'log.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'mask.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'mean.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_dewhite']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_FTdewhite']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_FTmix']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_IC.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_ICstats']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_mix']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_oIC.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_pcaD']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_pcaE']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_pca.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_PPCA']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_Tmodes']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_unmix']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'melodic_white']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'Noise__inv.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'report']))
        # ... not checking all files in the report subdirectory
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'filtered_func_data.ica', 'stats']))
        # ... not checking all files in the stats subdirectory
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'edge1.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'edge2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'edge3.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'edge4.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'edge5.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_mixeltype.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_pve_0.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_pve_1.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_pve_2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_pveseg.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'fastsg_seg.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'features.csv']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'features_info.csv']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'features.mat']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'highres2std.mat']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'hr2exf.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'hr2exfTMP.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'hr2exfTMP.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'logMatlab.txt']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'maske1.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'maske2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'maske3.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'maske4.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'maske5.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc0dil2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc0dil.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc0.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc1dil2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc1dil.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc1.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc2dil2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc2dil.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc3dil2.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc3dil.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std1mm2exfunc3.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std2exfunc.mat']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'std2highres.mat']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'fix', 'subcort.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'mc']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'mc', 'prefiltered_func_data_mcf_conf_hp.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'mc', 'prefiltered_func_data_mcf_conf.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg', 'example_func.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg', 'highres2example_func.mat']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg', 'veinbrainmask.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg', 'veins_exf.nii.gz']))
        l.append(os.sep.join([root_dir, 'MNINonLinear', 'Results', scan, scan + '_hp2000.ica', 'reg', 'veins.nii.gz']))
        
        return l

    
if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(
        description="Program to check for completion of 7T MultiRunICAFIX7THCP Processing.")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
    parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)
    parser.add_argument('-n', '--scan', dest='scan', required=True, type=str)
    
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
    subject_info = hcp7t_subject.Hcp7TSubjectInfo(
        project=args.project, subject_id=args.subject, extra=args.scan)
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
