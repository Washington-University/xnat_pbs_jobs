#!/usr/bin/env python3

"""xnat_archive.py: Provide information to allow direct access to an XNAT data archive."""

# import of built-in modules
import os

# import of third party modules
pass

# path changes and import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

class XNAT_Archive:
    """This class provides information about direct access to an XNAT data archive.

    This access goes 'behind the scenes' and uses the actual underlying file system.
    Because of this, a change in XNAT implementation could cause this code to no longer
    be correct.
    """

    @property
    def DEFAULT_COMPUTE_PLATFORM(self):
        """The default value used for the compute platform.

        If the COMPUTE environment is not set, this value is used.
        """
        return 'CHPC' 

    def __init__(self):
        """Constructs an XNAT_Archive object for direct access to an XNAT data archive."""
        self._compute_platform = os.getenv('COMPUTE', self.DEFAULT_COMPUTE_PLATFORM)

        if self._compute_platform == 'CHPC':
            self._hcp_root = '/HCP'
        elif self._compute_platform == 'NRG':
            self._hcp_root = '/data'
        else:
            raise ValueError('Unrecognized value for COMPUTE environment variable: ' + self._compute_platform)

    @property
    def archive_root(self):
        """Returns the path to the root of the archive."""
        return self._hcp_root + '/hcpdb/archive'

    @property
    def build_space_root(self):
        """Returns the temporary build/processing directory root."""
        return self._hcp_root + '/hcpdb/build_ssd/chpc/BUILD'


    def project_archive_root(self, project_name):
        """Returns the path to the specified project's root directory in the archive.

        :param project_name: name of the project in the XNAT archive
        :type project_name: str
        """
        return self.archive_root + '/' + project_name + '/arc001'

    def project_resources_root(self, project_name):
        """Returns the path to the specified project's root project-level resources directory in the archive.

        :param project: name of the project in the XNAT archive
        :type project_name: str
        """
        return self.archive_root + '/' + project_name + '/resources'

if __name__ == "__main__":
    archive = XNAT_Archive()

    print('archive_root: ' + archive.archive_root)
    print('project_archive_root(\'HCP_Staging_7T\'): ' + archive.project_archive_root('HCP_Staging_7T'))
    print('project_resources_root(\'HCP_Staging_7T\'): ' + archive.project_resources_root('HCP_Staging_7T'))
