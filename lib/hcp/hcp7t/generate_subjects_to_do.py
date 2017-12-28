#!/usr/bin/env python3

# import of built-in modules

# import of third party modules

# import of local modules
import hcp.hcp7t.subject as hcp7t_subject
import utils.my_argparse as my_argparse

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Connectome Coordination Facility/Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

def main():
    # create a parser object for getting the command line arguments
    parser = my_argparse.MyArgumentParser()

    parser.add_argument('-a', '--all-subjects=', dest='all_subjects', required=True, type=str)
    parser.add_argument('-t', '--todo-subjects=', dest='todo_subjects', required=True, type=str)

    args = parser.parse_args()

    # print("Retrieving all subjects from: " + args.all_subjects)
    all_subjects_list = hcp7t_subject.read_subject_info_list(args.all_subjects, separator=":")

    # print("Retrieving subject ids in TODO list from: " + args.todo_subjects)
    to_do_subjects_list = []

    to_do_ids_file = open(args.todo_subjects, "r")
    for line in to_do_ids_file:
        subject_id = line[:-1]

        for subject in all_subjects_list:
            if subject_id == subject.subject_id:
                print(str(subject))
                break
            

if __name__ == '__main__':
    main()
    
