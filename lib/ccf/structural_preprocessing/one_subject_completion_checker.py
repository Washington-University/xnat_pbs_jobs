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

    def my_resource_time_stamp(self, archive, subject_info):
        return os.path.getmtime(self.my_resource(archive, subject_info))
    
    def latest_prereq_resource_time_stamp(self, archive, subject_info):
        latest_time_stamp = 0
        struct_unproc_dir_paths = archive.available_structural_unproc_dir_full_paths(subject_info)
        
        for full_path in struct_unproc_dir_paths:
            this_time_stamp = os.path.getmtime(full_path)
            if this_time_stamp > latest_time_stamp:
                latest_time_stamp = this_time_stamp

        return latest_time_stamp

    def completion_marker_file_name(self):
        return 'StructuralPreprocessing.XNAT_CHECK.sh.success'

    def starttime_marker_file_name(self):
        return 'StructuralPreprocessing.starttime'
    
    def does_processed_resource_exist(self, archive, subject_info):
        fullpath = self.my_resource(archive, subject_info)
        return os.path.isdir(fullpath)

    def is_processing_marked_complete(self, archive, subject_info):

        # If the processed resource does not exist, then the process is certainly not marked
        # as complete. The file that marks is as complete would be in that resource.
        if not self.does_processed_resource_exist(archive, subject_info):
            return False

        resource_path = self.my_resource(archive, subject_info)
        completion_marker_file_path = resource_path + os.sep + self.completion_marker_file_name()
        starttime_marker_file_path = resource_path + os.sep + self.starttime_marker_file_name()
        
        # If the completion marker file does not exist, then the processing is certainly not marked
        # as complete.
        marker_file_exists = os.path.exists(completion_marker_file_path)
        if not marker_file_exists:
            return False

        # If the completion marker file is older than the starttime marker file, then any mark
        # of completeness is invalid.
        if os.path.getmtime(completion_marker_file_path) < os.path.getmtime(starttime_marker_file_path):
            return False
        
        # If the completion marker file does exist, then look at the contents for further
        # confirmation

        f = open(completion_marker_file_path, "r")
        lines = f.readlines()

        if lines[-1].strip() != 'Completion Check was successful':
            return False
        
        return True

    def list_of_expected_files(self, archive, subject_info):

        file_name_list = []

        # <subject-id>/MNINonLinear
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear'])

        file_name_list.append(check_dir + os.sep + 'aparc.a2009s+aseg.nii.gz')
        file_name_list.append(check_dir + os.sep + 'aparc+aseg.nii.gz')
        file_name_list.append(check_dir + os.sep + 'BiasField.nii.gz')
        file_name_list.append(check_dir + os.sep + 'brainmask_fs.nii.gz')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.164k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.164k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.a2009s.164k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_FS.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMSulc.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.BA.164k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.corrThickness.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.curvature.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_FS.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMSulc.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.a2009s.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_FS.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_MSMSulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.atlasroi.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.BA.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.corrThickness.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.curvature.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_FS.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_MSMSulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.flat.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap_BC.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.RefMyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.refsulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap_BC.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.thickness.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.a2009s.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_FS.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_MSMSulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.atlasroi.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.BA.164k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.corrThickness.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.curvature.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_FS.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_MSMSulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.flat.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap_BC.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.RefMyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.refsulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap_BC.164k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sulc.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.thickness.164k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white.164k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.sulc.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.thickness.164k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + 'ribbon.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T1w.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T1w_restore.2.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T1w_restore_brain.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T1w_restore.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T2w.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T2w_restore.2.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T2w_restore_brain.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T2w_restore.nii.gz')
        file_name_list.append(check_dir + os.sep + 'wmparc.nii.gz')

        # <subject-id>/MNINonLinear/fsaverage
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'fsaverage'])
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.def_sphere.164k_fs_L.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.164k_fs_L.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.def_sphere.164k_fs_R.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.164k_fs_R.surf.gii')

        # <subject-id>/MNINonLinear/fsaverage_LR32k
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'fsaverage_LR32k'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.32k_fs_LR.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.32k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.a2009s.32k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_FS.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMSulc.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.BA.32k_fs_LR.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.corrThickness.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.curvature.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_FS.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMSulc.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.a2009s.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_FS.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_MSMSulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.atlasroi.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.BA.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.corrThickness.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.curvature.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_FS.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_MSMSulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.flat.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap_BC.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap_BC.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.thickness.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.a2009s.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_FS.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_MSMSulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.atlasroi.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.BA.32k_fs_LR.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.corrThickness.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.curvature.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_FS.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_MSMSulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.flat.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap_BC.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap_BC.32k_fs_LR.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sulc.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.thickness.32k_fs_LR.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white.32k_fs_LR.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.sulc.32k_fs_LR.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.thickness.32k_fs_LR.dscalar.nii')

        # <subject-id>/MNINonLinear/Native
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'Native'])

        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.a2009s.native.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.aparc.native.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_FS.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.ArealDistortion_MSMSulc.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.BA.native.dlabel.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.corrThickness.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.curvature.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_FS.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.EdgeDistortion_MSMSulc.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.a2009s.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.aparc.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_FS.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.ArealDistortion_MSMSulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.atlasroi.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.BA.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.BiasField.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.corrThickness.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.curvature.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_FS.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.EdgeDistortion_MSMSulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.inflated.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.midthickness.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap_BC.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.MyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.pial.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.RefMyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.roi.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap_BC.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.SmoothedMyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.MSMSulc.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.reg.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.reg.reg_LR.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sphere.rot.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.sulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.thickness.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.very_inflated.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.L.white.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap_BC.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.MyelinMap.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.native.wb.spec')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.a2009s.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.aparc.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_FS.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.ArealDistortion_MSMSulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.atlasroi.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.BA.native.label.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.BiasField.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.corrThickness.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.curvature.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_FS.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.EdgeDistortion_MSMSulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.inflated.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.midthickness.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap_BC.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.MyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.pial.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.RefMyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.roi.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap_BC.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.SmoothedMyelinMap.native.func.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.MSMSulc.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.reg.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.reg.reg_LR.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sphere.rot.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.sulc.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.thickness.native.shape.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.very_inflated.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.R.white.native.surf.gii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap_BC.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.SmoothedMyelinMap.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.sulc.native.dscalar.nii')
        file_name_list.append(check_dir + os.sep + subject_info.subject_id + '.thickness.native.dscalar.nii')

        # <subject-id>/MNINonLinear/Native/MSMSulc
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'Native',
                                 'MSMSulc'])

        file_name_list.append(check_dir + os.sep + 'R.mat')
        file_name_list.append(check_dir + os.sep + 'R.sphere.LR.reg.surf.gii')
        file_name_list.append(check_dir + os.sep + 'R.sphere.reg.surf.gii')
        file_name_list.append(check_dir + os.sep + 'R.sphere_rot.surf.gii')
        file_name_list.append(check_dir + os.sep + 'R.transformed_and_reprojected.func.gii')

        # <subject-id>/MNINonLinear/Native/MSMSulc/R.logdir
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'Native',
                                 'MSMSulc',
                                 'R.logdir'])

        file_name_list.append(check_dir + os.sep + 'MSM.log')

        # <subject-id>/MNINonLinear/ROIs
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'ROIs'])

        file_name_list.append(check_dir + os.sep + 'Atlas_ROIs.2.nii.gz')
        file_name_list.append(check_dir + os.sep + 'Atlas_wmparc.2.nii.gz')
        file_name_list.append(check_dir + os.sep + 'ROIs.2.nii.gz')
        file_name_list.append(check_dir + os.sep + 'wmparc.2.nii.gz')

        # <subject-id>/MNINonLinear/xfms
        check_dir = os.sep.join([self.my_resource(archive, subject_info),
                                 str(subject_info.subject_id),
                                 'MNINonLinear',
                                 'xfms'])

        file_name_list.append(check_dir + os.sep + '2mmReg.nii.gz')
        file_name_list.append(check_dir + os.sep + 'acpc2MNILinear.mat')
        file_name_list.append(check_dir + os.sep + 'acpc_dc2standard.nii.gz')
        file_name_list.append(check_dir + os.sep + 'IntensityModulatedT1.nii.gz')
        file_name_list.append(check_dir + os.sep + 'log.txt')
        file_name_list.append(check_dir + os.sep + 'NonlinearIntensities.nii.gz')
        file_name_list.append(check_dir + os.sep + 'NonlinearIntensities.nii.gz.txt')
        file_name_list.append(check_dir + os.sep + 'NonlinearRegJacobians.nii.gz')
        file_name_list.append(check_dir + os.sep + 'NonlinearReg.nii.gz')
        file_name_list.append(check_dir + os.sep + 'NonlinearReg.txt')
        file_name_list.append(check_dir + os.sep + 'qa.txt')
        file_name_list.append(check_dir + os.sep + 'standard2acpc_dc.nii.gz')
        file_name_list.append(check_dir + os.sep + 'T1w_acpc_dc_restore_brain_to_MNILinear.nii.gz')

        return file_name_list
    
    def is_processing_complete(self, archive, subject_info, verbose=False, output=sys.stdout, short_circuit=True):
        # If the processed resource does not exist, then the processing is certainly not complete.
        if not self.does_processed_resource_exist(archive, subject_info):
            if verbose:
                print("resource: " + self.my_resource(archive, subject_info) + " DOES NOT EXIST", file=output)
            return False

        # If processed resource is not newer than prerequisite resources, then the processing is not complete
        resource_time_stamp = self.my_resource_time_stamp(archive, subject_info)
        latest_prereq_time_stamp = self.latest_prereq_resource_time_stamp(archive, subject_info)
        
        if resource_time_stamp <= latest_prereq_time_stamp:
            if verbose:
                print("resource: " + self.my_resource(archive, subject_info) + " IS NOT NEWER THAN ALL PREREQUISITES", file=output)
            return False
        
        # If processed resource exists and is newer than all the prerequisite resources, then check
        # to see if all the expected files exist
        expected_file_list = self.list_of_expected_files(archive, subject_info)
        return self.do_all_files_exist(expected_file_list, verbose, output, short_circuit)


if __name__ == "__main__":

    parser = my_argparse.MyArgumentParser(description="Program to check for completion of Structural Preprocessing.")

    # mandatory arguments
    parser.add_argument('-p', '--project', dest='project', required=True, type=str)
    parser.add_argument('-s', '--subject', dest='subject', required=True, type=str)
    parser.add_argument('-c', '--classifier', dest='classifier', required=True, type=str)

    # optional arguments
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', required=False,
                        default=False)
    parser.add_argument('-o', '--output', dest='output', required=False, type=str)
    parser.add_argument('-a', '--check-all', dest='check_all', action='store_true', required=False,
                        default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # check the specified subject for structural preprocessing completion
    archive = ccf_archive.CcfArchive()
    subject_info = ccf.subject.SubjectInfo(args.project, args.subject, args.classifier)
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


