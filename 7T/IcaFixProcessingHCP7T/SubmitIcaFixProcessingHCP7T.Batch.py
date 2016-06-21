#!/usr/bin/env python3

import os
import sys
import getpass
import random
import subprocess

sys.path.append('../lib')
import hcp7t_subject

PROGRAM_NAME = 'SubmitIcaFixProcessingHCP7T.Batch.py'
START_SHADOW_NUMBER = 1
MAX_SHADOW_NUMBER = 8

def inform(msg):
    print(PROGRAM_NAME + ": " + msg)

if __name__ == "__main__":

    # Get environment variables
    subject_files_dir = os.getenv('SUBJECT_FILES_DIR')

    if subject_files_dir == None:
        inform('Environment variable SUBJECT_FILES_DIR must be set!')
        sys.exit(1)

    scripts_home = os.getenv('SCRIPTS_HOME')

    if scripts_home == None:
        inform('Environment variable SCRIPTS_HOME must be set!')
        sys.exit(1)

    home = os.getenv('HOME')

    if home == None:
        inform('Environment variable HOME must be set!')
        sys.exit(1)

    # Get Connectome DB credentials
    userid = input('Connectome DB Username: ')
    password = getpass.getpass('Connectome DB Password: ')

    # Get list of subjects to process
    subject_file_name = subject_files_dir + os.sep + 'IcaFixProcessingHCP7T.subjects'
    inform('Retrieving subject list from: ' + subject_file_name)
    subject_list = hcp7t_subject.read_subject_info_list(subject_file_name)

    # Process subjects in list
    shadow_number = random.randint(START_SHADOW_NUMBER, MAX_SHADOW_NUMBER)

    for subject in subject_list:
        server = 'db-shadow' + str(shadow_number) + '.nrg.mir:8080'

        scan = subject.extra

        inform("")
        inform("--------------------------------------------------------------------------------")
        inform(" Submitting IcaFixProcessingHCP7T jobs for: ")
        inform("      project: " + subject.project )
        inform("   refproject: " + subject.structural_reference_project )
        inform("      subject: " + subject.subject_id )
        inform("         scan: " + scan )
        inform("       server: " + server )
        inform("--------------------------------------------------------------------------------")

        setup_file = scripts_home + os.sep + 'SetUpHCPPipeline_IcaFixProcessingHCP7T.sh'

        cmd = home + os.sep + 'pipeline_tools' + os.sep + 'xnat_pbs_jobs' + os.sep + '7T' + os.sep + 'IcaFixProcessingHCP7T' + os.sep + 'SubmitIcaFixProcessingHCP7T.OneSubject.sh'
        cmd += ' --user=' + userid
        cmd += ' --password=' + password
        cmd += ' --put-server=' + server
        cmd += ' --project=' + subject.project
        cmd += ' --subject=' + subject.subject_id
        cmd += ' --structural-reference-project=' + subject.structural_reference_project
        cmd += ' --structural-reference-session=' + subject.structural_reference_project + '_3T'
        cmd += ' --setup-script=' + setup_file
        
        if scan == 'all':
            pass

        elif scan == 'incomplete':
            cmd += ' --incomplete-only'

        else:
            cmd += ' --scan=' + scan

        subprocess.run(cmd, shell=True, check=True)

        shadow_number = shadow_number + 1
        if shadow_number > MAX_SHADOW_NUMBER:
            shadow_number = START_SHADOW_NUMBER
