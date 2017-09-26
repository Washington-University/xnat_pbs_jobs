#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules

# import of local modules
import hcp.hcp7t.archive as hcp7t_archive
import hcp.hcp7t.subject as hcp7t_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


expected_retinotopy_scans = ['tfMRI_RETCCW_AP',
                             'tfMRI_RETCW_PA',
                             'tfMRI_RETEXP_AP',
                             'tfMRI_RETCON_PA',
                             'tfMRI_RETBAR1_AP',
                             'tfMRI_RETBAR2_PA']

if __name__ == '__main__':

    project = 'HCP_1200'
    archive = hcp7t_archive.Hcp7T_Archive()

    subject_ids = archive.available_subject_id_list(project)

    for subject_id in subject_ids:
        subject_info = hcp7t_subject.Hcp7TSubjectInfo(project=project, subject_id=subject_id)
        available_retinotopy_task_names = archive.available_retinotopy_preproc_names(subject_info)

        # print(subject_info, available_retinotopy_task_names)

        for expected_scan in expected_retinotopy_scans:
            if expected_scan not in available_retinotopy_task_names:
                print(subject_info, "is missing", expected_scan)

        
