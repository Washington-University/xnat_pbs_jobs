#!/usr/bin/env python3

import os

DEFAULT_COMPUTE_PLATFORM = 'CHPC'

class XNAT_Archive:

    def __init__(self):
        self.__compute_platform = os.getenv('COMPUTE', DEFAULT_COMPUTE_PLATFORM)

        if self.__compute_platform == 'CHPC':
            self.__hcp_root = '/HCP'
        elif self.__compute_platform == 'NRG':
            self.__hcp_root = '/data'
        else:
            raise ValueError('Unrecognized value for COMPUTE environment variable: ' + self.__compute_platform)

    @property
    def archive_root(self):
        return self.__hcp_root + '/hcpdb/archive'

    def project_archive_root(self, project_name):
        return self.archive_root + '/' + project_name + '/arc001'

    def project_resources_root(self, project_name):
        return self.archive_root + '/' + project_name + '/resources'

if __name__ == "__main__":
    archive = XNAT_Archive()

    print('archive_root: ' + archive.archive_root)
    print('project_archive_root(\'HCP_Staging_7T\'): ' + archive.project_archive_root('HCP_Staging_7T'))
    print('project_resources_root(\'HCP_Staging_7T\'): ' + archive.project_resources_root('HCP_Staging_7T'))
