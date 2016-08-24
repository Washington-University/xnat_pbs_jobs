#!/usr/bin/env python

# 
# Given a single TSV package report for a package type (e.g. Structural_unproc.PackageReport.tsv)
# as its input file (-i or --input-file), this code will "analyze" the package report for that
# package type and generate a summary report for the package type with indications of 
# such things as:
# 
# * how many packages should exist but do not
# * how many checksum files should exist but do not
# * how many of the checksum files are incorrect
# * how many of the package files are smaller than they should be and are unexplained
#
# A package is deemed smaller than it should be if it is less than the lower_bound_percent%
# of the median size of all packages of the package type.  The lower_bound_percent value
# can be specified using the -p/--lower-bound-percent command line argument.  If unspecified,
# it defaults to 75%
#
# A package that is deemed smaller than it should be is considered "explained" if there is a 
# note that starts with "SMALL_OK:" as part of the record for the package.
#

import argparse
import csv
import ast
import scipy

def show_retrieved_params( args ):
    print("\nInput Parameters")
    print("\tinput_file: " + args.input_file)
    
def retrieve_params( ):
    parser = argparse.ArgumentParser();
    parser.add_argument("-i", "--input-file", dest="input_file", required=True, type=str)
    parser.add_argument("-c", "--concise", dest="concise", action="store_true")
    parser.add_argument("-p", "--lower-bound-percent", dest="lower_bound_percent", default=75, type=int)
    args = parser.parse_args()
    return args

def parse_bool( input_string ):
    return input_string[0].upper() == 'T'

def compute_size( input_string ):
    mult_factor = 1
    if input_string.endswith('K'):
        mult_factor = 1024
    elif input_string.endswith('M'):
        mult_factor = 1048576
    elif input_string.endswith('G'):
        mult_factor = 1073741824
    elif input_string.endswith('T'):
        mult_factor = 1099511627776

    size_spec_str = input_string[0:-1] 
    size_spec = float(size_spec_str)
    # print("size_spec: " + str(size_spec))
    # print("mult_factor: " + str(mult_factor))
    
    bytes = size_spec * mult_factor
    # print("bytes: " + str(bytes))
    return bytes

class PackageStatus:

    def __init__(self,
                 subject_id_init,
                 package_init,
                 package_exists_str_init,
                 package_size_str_init,
                 package_date_str_init,
                 checksum_exists_str_init,
                 checksum_correct_str_init,
                 notes_str_init):
        self.subject_id = subject_id_init
        self.package = package_init
        self.package_exists_str = package_exists_str_init
        self.package_size_str = package_size_str_init
        self.package_date_str = package_date_str_init
        self.checksum_exists_str = checksum_exists_str_init
        self.checksum_correct_str = checksum_correct_str_init
        self.notes_str = notes_str_init


        if (self.package_exists_str == "TRUE"):
            self.package_exists = parse_bool(self.package_exists_str)
            self.package_size = compute_size(self.package_size_str)
            self.checksum_exists = parse_bool(self.checksum_exists_str)
            if self.checksum_exists:
                self.checksum_correct = parse_bool(self.checksum_correct_str)
            else:
                self.checksum_correct = FALSE
        elif (self.package_exists_str == "---"):
            self.package_exists = False
            self.package_size = 0
            self.checksum_exists = False
            self.checksum_correct = True
        else:
            self.package_exists = False
            self.package_size = 0
            self.checksum_exists = False
            self.checksum_correct = True
        
    def __str__(self):
        string_rep = self.subject_id
        string_rep += "\t" + self.package
        string_rep += "\t" + self.package_exists_str
        string_rep += "\t" + self.package_size_str
        string_rep += "\t" + self.package_date_str
        string_rep += "\t" + self.checksum_exists_str
        string_rep += "\t" + self.checksum_correct_str
        string_rep += "\t" + self.notes_str
        return string_rep
        
            
# Main functionality
args = retrieve_params()
if not args.concise:
    show_retrieved_params(args)

full_subject_status_list = []

# subjects_with_package_list = []
# size_list = []
# subjects_with_package_notes_list = []
# should_not_exist_count = 0
# should_exist_but_does_not_count = 0
# non_existent_checksum_count = 0
# incorrect_checksum_count = 0

with open(args.input_file, 'r') as tsv:
    rows = [line.strip().split('\t') for line in tsv]

    for row in rows:
        subject_id = row[0]
        package = row[1]
        package_exists_str = row[2]
        package_size_str = row[3]
        package_date_str = row[4]
        checksum_exists_str = row[5]
        checksum_correct_str = row[6]
        try:
            notes_str = row[7]
        except IndexError:
            notes_str = ''
            pass
        
        if subject_id == 'Subject ID':
            # ignore header row
            continue

        package_status = PackageStatus(
            subject_id, package, package_exists_str, package_size_str, package_date_str, checksum_exists_str, checksum_correct_str, notes_str)
        
        full_subject_status_list.append(package_status)

    # How many packages exist
    package_exist_count = 0
    for subject_status in full_subject_status_list:
        if subject_status.package_exists:
            package_exist_count += 1
    
    # How many subjects don't need packages
    should_not_have_packages_count = 0
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str == "---":
            should_not_have_packages_count += 1

    # How many subjects should have packages but don't
    should_have_packages_but_dont_count = 0
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str != "---" and not subject_status.package_exists:
            should_have_packages_but_dont_count += 1

    # How many subjects should have a checksum but don't
    should_have_checksum_but_dont_count = 0
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str != "---" and not subject_status.checksum_exists:
            should_have_checksum_but_dont_count += 1

    # How many subjects have an incorrect checksum
    incorrect_checksum_count = 0
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str != "---" and not subject_status.checksum_correct:
            incorrect_checksum_count += 1

    # Calculate median package size
    size_list = []
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str != "---":
            size_list.append(subject_status.package_size)

    if len(size_list) > 0:
        median_package_size = scipy.median(size_list)
    else:
        median_package_size = 0.0

    lower_bound_package_size_percent = args.lower_bound_percent
    lower_bound_package_size = (lower_bound_package_size_percent/100.0) * median_package_size

    # build a list of subjects with small packages
    subjects_with_small_packages_list = []
    for subject_status in full_subject_status_list:
        if subject_status.package_exists_str != "---" and subject_status.package_exists:
            if subject_status.package_size < lower_bound_package_size:
                subjects_with_small_packages_list.append(subject_status)

    # build a list of subjects with unexplained small packages
    subjects_with_unexplained_small_packages_list = []
    for subject_status in subjects_with_small_packages_list:
        if not subject_status.notes_str.startswith("SMALL_OK:"):
            subjects_with_unexplained_small_packages_list.append(subject_status)

    # output
    if not args.concise:
        print("Total Subjects Count: " + str(len(full_subject_status_list)))
        print("Package Count: " + str(package_exist_count))
        print("Subjects who shouldn't have packages: " + str(should_not_have_packages_count))
        print("Subjects who should have packages but don't: " + str(should_have_packages_but_dont_count))
        print("Subjects who should have a checksum but don't: " + str(should_have_checksum_but_dont_count))
        print("Subjects with incorrect checksums: " + str(incorrect_checksum_count))
        print("Median Package Size: " + str(median_package_size))
        print("Lower Bound Package Size Percent: " + str(lower_bound_package_size_percent) + "%")
        print("Lower Bound Package Size: " + str(lower_bound_package_size))
        print("Subjects with Small Packages Count: " + str(len(subjects_with_small_packages_list)))
        print("Subjects with UNEXPLAINED Small Packages Count: " + str(len(subjects_with_unexplained_small_packages_list)))
        print("Subjects with UNEXPLAINED small packages:")
        for subject_status in subjects_with_unexplained_small_packages_list:
            print(str(subject_status))
            
    else:
        output_str = args.input_file.split('/',1)[-1]
        output_str += "\t" + str(len(full_subject_status_list))
        output_str += "\t" + str(package_exist_count)
        output_str += "\t" + str(should_not_have_packages_count)
        output_str += "\t" + str(should_have_packages_but_dont_count)
        output_str += "\t" + str(should_have_checksum_but_dont_count)
        output_str += "\t" + str(incorrect_checksum_count)
        output_str += "\t" + str(len(subjects_with_unexplained_small_packages_list))
        print(output_str)


    



        
        
