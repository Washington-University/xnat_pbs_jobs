#!/usr/bin/env python3

# import of built-in modules
import json

# import of third-party modules

# import of local modules
import utils.file_utils as file_utils
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project and The Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


def main():
    parser = my_argparse.MyArgumentParser(description="Get meta data about a file from a corresponding JSON file")

    # required arguments
    parser.add_argument('-f', '--file', dest='file', required=True, type=str)
    parser.add_argument('-k', '--key', dest='key', required=True, type=str)

    args = parser.parse_args()

    meta_data_json_file_name = file_utils.get_meta_data_json_file_name(args.file)
    meta_data_json_file = open(meta_data_json_file_name, "r")
    meta_data = json.load(meta_data_json_file)
    meta_data_json_file.close()
    value = meta_data[args.key]
    print(str(value))
    
if __name__ == '__main__':
    main()
