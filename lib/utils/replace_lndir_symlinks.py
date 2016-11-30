#!/usr/bin/env python3

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def main():
    parser = my_argparse.MyArgumentParser()

    # optional arguments
    parser.add_argument('-d', '--directory', dest='directory', required=False, default=None, type=str)

    # parse the command line arguments
    args = parser.parse_args()

    if not args.directory:
        args.directory = input("Directory: ")

    root_path = os.path.expandvars(os.path.expanduser(args.directory))
    print("root_path: " + root_path)
    os_utils.replace_lndir_symlinks(root_path)


if __name__ == '__main__':
    main()
