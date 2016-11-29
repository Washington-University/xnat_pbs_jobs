#!/usr/bin/env python3

"""xnat_archive.py: Provide information to allow direct access to an XNAT data archive."""

# import of built-in modules
import os

# import of third party modules
# None

# path changes and import of local modules
# None

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


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
        elif self._compute_platform == 'TIMS_DESKTOP':
            # self._hcp_root = '/home/tbb/chpc2/HCP'
            self._hcp_root = '/home/tbb/fs01/data'
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


def _simple_interactive_demo():
    archive = XNAT_Archive()

    _inform('archive_root: ' + archive.archive_root)
    _inform('project_archive_root(\'HCP_Staging_7T\'): ' + archive.project_archive_root('HCP_Staging_7T'))
    _inform('project_resources_root(\'HCP_Staging_7T\'): ' + archive.project_resources_root('HCP_Staging_7T'))


if __name__ == "__main__":
    _simple_interactive_demo()
