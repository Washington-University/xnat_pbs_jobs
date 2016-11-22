#!/usr/bin/env python3

"""show_duplicate_lines.py: simple program to show lines that are present in two files"""

# import of built-in modules
import os
import argparse

# import of third party modules
pass

# import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    print(os.path.basename(__file__) + ": " + msg)


def main():
    parser = argparse.ArgumentParser(description="Simple program to show lines that are present in two files")

    parser.add_argument('-i1', '--input-file-1', dest='input_file_1', required=True, default=None, type=str)
    parser.add_argument('-i2', '--input-file-2', dest='input_file_2', required=True, default=None, type=str)

    args = parser.parse_args()

    _inform("Input file name 1: " + args.input_file_1)
    _inform("Input file name 2: " + args.input_file_2)

    file_1_lines = []
    with open(args.input_file_1, 'r') as input_file_1:
        for line in input_file_1:
            line = line.rstrip()
            if line not in file_1_lines:
                file_1_lines.append(line)

    duplicate_lines = []
    with open(args.input_file_2, 'r') as input_file_2:
        for line in input_file_2:
            line = line.rstrip()
            if line in file_1_lines:
                duplicate_lines.append(line)

    _inform("Start duplicate lines:")
    for line in duplicate_lines:
        _inform(line)

    _inform("End duplicate lines:")

if __name__ == '__main__':
    main()
