#!/usr/bin/env python3

# import of built-in modules
import getpass
import os

# import of third party modules

# import of local modules
import utils.delete_resource as delete_resource
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils
import utils.str_utils as str_utils

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


def main():
    # create a parser object for getting the command line options
    parser = my_argparse.MyArgumentParser()

    # mandatory arguments
    parser.add_argument('-u', '--user', dest='user', required=True, type=str)
    parser.add_argument(dest='input_file')

    # optional arguments
    parser.add_argument('-ser', '--server', dest='server', required=False,
						default='https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
						type=str)
	
    parser.add_argument('-p', '--password', dest='password', required=False, type=str)

    # parse the command line arguments
    args = parser.parse_args()

    if args.password:
        password = args.password
    else:
        password = getpass.getpass("Password: ")

    # show parsed arguments
    _inform("Parsed arguments:")
    _inform("    Username: " + args.user)
    _inform("    Password: " + "*** password mask ***")
    _inform("      Server: " + args.server)
    _inform("  Input File: " + args.input_file)

    _inform("")

    input_file = open(args.input_file, 'r')
    for line in input_file:
        line = str_utils.remove_ending_new_lines(line)
        line = line.strip()
        
        if line != '' and line[0] != '#':
            (project, subject, session, resource) = line.split('\t')
            _inform("")
            _inform("     Project: " + project)
            _inform("     Subject: " + subject)
            _inform("     Session: " + session)
            _inform("    Resource: " + resource)
            _inform("")

            delete_resource.delete_resource(args.user, password, args.server, 
                                            project, subject, session, resource)


if __name__ == '__main__':
    main()
