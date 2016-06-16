#!/usr/bin/env python3

import os

DEFAULT_COMPUTE_PLATFORM = 'CHPC'

def xnat_archive_root():
    compute = os.getenv('COMPUTE', DEFAULT_COMPUTE_PLATFORM)

    if compute == 'CHPC':
        hcp_root = '/HCP'
    elif compute == 'NRG':
        hcp_root = '/data'
    else:
        raise ValueError('Unrecognized value for COMPUTE environment variable: ' + compute)

    return hcp_root + '/hcpdb/archive'

def project_archive_root(project_name):
    return xnat_archive_root() + '/' + project_name + '/arc001'

def project_resources_root(project_name):
    return xnat_archive_root() + '/' + project_name + '/resources'

if __name__ == "__main__":
    print('xnat_archive_root(): ' + xnat_archive_root())
    print('project_archive_root(\'HCP_Staging_7T\'): ' + project_archive_root('HCP_Staging_7T'))
    print('project_resources_root(\'HCP_Staging_7T\'): ' + project_resources_root('HCP_Staging_7T'))
