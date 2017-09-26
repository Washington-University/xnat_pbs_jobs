#!/usr/bin/env python3

# import of built-in modules
import sys

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def main():
    parser = my_argparse.MyArgumentParser()
    parser.add_argument("full_path")
    parser.add_argument("-v", "--verbose", dest="verbose", action='store_true',
                        required=False, default=False)
    
    args = parser.parse_args()
    
    file_utils.make_all_links_into_copies(args.full_path, verbose=args.verbose)
    
if __name__ == '__main__':
    main()
