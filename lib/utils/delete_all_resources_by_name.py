#!/usr/bin/env python3

"""
utils/delete_all_resources_by_name.py: Program to delete all DB resources
of a given name for all sessions in a given ConnectomeDB project."
"""

# import of built-in modules
import glob
import os
import sys

# import of third party modules

# import of local modules
import utils.delete_resource as delete_resource
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils
import xnat.xnat_archive as xnat_archive

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user of this program by outputing a message that is prefixed
    by the file name.
    """
    print(os.path.basename(__file__) + ": " + msg)


def main():
    # create a parser object for getting the command line arguments
    parser = my_argparse.MyArgumentParser(
        description="Program to delete all DB resources of a given name for all sessions in a given ConnectomeDB project.")

    # mandatory arguments
    parser.add_argument('-u', '--user', dest='user', required=True, type=str)
    parser.add_argument('-pw', '--password', dest='password', required=True, type=str)
    parser.add_argument('-pr', '--project', dest='project', required=True, type=str)
    parser.add_argument('-r', '--resource', dest='resource', required=True, type=str)

    # optional arguments
    parser.add_argument('-ser', '--server', dest='server', required=False,
                        default='https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
                        type=str)
    parser.add_argument('-f', '--force', dest='force', action='store_true', required=False, default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # show parsed arguments
    _inform("Parsed arguments:")
    _inform("  Username: " + args.user)
    _inform("  Password: " + "*** password mask ***")
    _inform("    Server: " + args.server)
    _inform("   Project: " + args.project)
    _inform("  Resource: " + args.resource)
    _inform("     Force: " + str(args.force))

    # find all instances of the specified resource in the specified project

    my_xnat_archive = xnat_archive.XNAT_Archive()

    archive_root = my_xnat_archive.project_archive_root(args.project)

    dir_list = glob.glob(archive_root + os.sep + '*')
    for directory in sorted(dir_list):
        resource_dir_to_look_for = directory + os.sep + 'RESOURCES' + os.sep + args.resource

        if os.path.isdir(resource_dir_to_look_for):

            unprefixed = resource_dir_to_look_for.replace(archive_root + os.sep, "")
            sep_loc = unprefixed.find(os.sep)
            session = unprefixed[:sep_loc]

            underscore_loc = session.find('_')
            subject = session[:underscore_loc]

            _inform("Deleting resource: " + args.resource + " for session: " + session)

            delete_resource.delete_resource(args.user, args.password, args.server,
                                            args.project,  subject,  session,
                                            args.resource, args.force)


if __name__ == '__main__':
    main()
