#!/usr/bin/env python3

"""remove_duplicate_lines.py: simple program to remove duplicate lines from a file"""

# import of built-in modules
import os

# import of third party modules
# None

# import of local modules
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name."""
    print(os.path.basename(__file__) + ": " + msg)


def main():
    parser = my_argparse.MyArgumentParser(description="Simple program to delete duplicate lines in a text file. Unlike the Linux/Unix uniq utility, it doesn't require duplicates to be adjacent.")

    # optional arguments
    parser.add_argument('-i', '--input-file', dest='input_file_name', required=False, default=None, type=str)
    parser.add_argument('-o', '--output-file', dest='output_file_name', required=False, default=None, type=str)

    # parse the command line arguments
    args = parser.parse_args()

    if not args.input_file_name:
        args.input_file_name = input("Input file name: ")

    if not args.output_file_name:
        args.output_file_name = input("Output file name: ")

    _inform(" Input file name: " + args.input_file_name)
    _inform("Output file name: " + args.output_file_name)

    output_lines = []
    with open(args.input_file_name, 'r') as input_file:
        for line in input_file:
            line = line.rstrip()
            if line not in output_lines:
                output_lines.append(line)

    with open(args.output_file_name, 'w') as output_file:
        for line in output_lines:
            output_file.write(line + os.linesep)


if __name__ == '__main__':
    main()
