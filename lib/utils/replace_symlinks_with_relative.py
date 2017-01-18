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
__copyright__ = "Copyright 2017, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def main():
    parser = my_argparse.MyArgumentParser()

    parser.add_argument('-d', '--directory', dest='directory', required=True, type=str)

    args = parser.parse_args()

    root_path = os.path.expandvars(os.path.expanduser(args.directory))
    print("root_path: " + root_path)
    os_utils.replace_symlinks_with_relative(root_path)

if __name__ == '__main__':
    main()
