#!/usr/bin/env python3

# import of built-in modules
import os
import sys

# import of third party modules
pass

# import of local modules
import hcp.hcp3t.archive as hcp3t_archive
import hcp.hcp3t.subject as hcp3t_subject

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


def main():
    archive = hcp3t_archive.Hcp3T_Archive()

    project_names = ['HCP_500', 'HCP_900']
    
    for project_name in project_names:

        subject_ids = archive.available_subject_ids(project_name)

        for subject_id in subject_ids:
            subject_info = hcp3t_subject.Hcp3TSubjectInfo(project_name, subject_id)
            available_diffusion_scan_names = archive.available_diffusion_scan_names(subject_info)

            dir95_scan_LR_scan_name = subject_info.subject_id + '_3T_DWI_dir95_LR.nii.gz' 
            dir95_scan_RL_scan_name = subject_info.subject_id + '_3T_DWI_dir95_RL.nii.gz' 

            dir96_scan_LR_scan_name = subject_info.subject_id + '_3T_DWI_dir96_LR.nii.gz' 
            dir96_scan_RL_scan_name = subject_info.subject_id + '_3T_DWI_dir96_RL.nii.gz' 

            dir97_scan_LR_scan_name = subject_info.subject_id + '_3T_DWI_dir97_LR.nii.gz' 
            dir97_scan_RL_scan_name = subject_info.subject_id + '_3T_DWI_dir97_RL.nii.gz' 


            if ((dir95_scan_LR_scan_name in available_diffusion_scan_names) and 
                (dir95_scan_RL_scan_name in available_diffusion_scan_names) and
                (dir96_scan_LR_scan_name in available_diffusion_scan_names) and
                (dir96_scan_RL_scan_name in available_diffusion_scan_names)):

                if ((dir97_scan_LR_scan_name in available_diffusion_scan_names) and
                    (dir97_scan_RL_scan_name not in available_diffusion_scan_names)):
                
                    _inform("Subject: " + str(subject_info) + " has all dir95 and dir96 scans and only dir97_LR.")

                elif ((dir97_scan_LR_scan_name not in available_diffusion_scan_names) and
                      (dir97_scan_RL_scan_name in available_diffusion_scan_names)):

                    _inform("Subject: " + str(subject_info) + " has all dir95 and dir96 scans and only dir97_RL.")
                


if __name__ == "__main__":
    main()
