#!/usr/bin/env python3

"""hcp/hcp3t/subject.py: Maintain information about an HCP 3T subject.

The module also provides services for reading and writing lists of such subjects
in simple text files.
"""

# import of built-in modules
import os
import sys


# import of third party modules
# None


# import of local modules
import hcp.subject as hcp_subject
import utils.str_utils as str_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user by writing out a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + str(msg))


class Hcp3TSubjectInfo(hcp_subject.HcpSubjectInfo):
    """This class maintains information about an HCP 3T subject."""


def read_subject_info_list(file_name, separator=Hcp3TSubjectInfo.DEFAULT_SEPARATOR()):
    """Reads a subject information list from the specified file.

    :param file_name: name of file from which to read
    :type file_name: str
    """
    subject_info_list = []

    input_file = open(file_name, 'r')
    for line in input_file:
        # remove new line characters
        line = str_utils.remove_ending_new_lines(line)

        # remove leading and trailing spaces
        line = line.strip()

        # ignore blank lines and comment lines - starting with #
        if line != '' and line[0] != '#':
            (project, subject_id, extra) = line.split(separator)
            # Make the string 'None' in the file translate to a None type instead of just the
            # string itself
            if extra == 'None':
                extra = None
            subject_info = Hcp3TSubjectInfo(project, subject_id, extra)
            subject_info_list.append(subject_info)

    return subject_info_list


def write_subject_info_list(file_name, subject_info_list):
    """Writes a subject list into the specified file.

    :param file_name: name of file to which to write
    :type file_name: str
    :param subject_info_list: list of subject information objects to write
    :type subject_info_list: list of Hcp7TSubjectInfo objects

    The file is overwritten, not appended to.
    """
    output_file = open(file_name, 'w')

    for subject_info in subject_info_list:
        output_file.write(str(subject_info) + os.linesep)

    output_file.close()


def _simple_interactive_demo():

    test_file_name = 'hcp3t_subject.test_subjects.txt'

    _inform(os.linesep)
    _inform("-- Creating 2 Hcp3TSubjectInfo objects --")
    subject_info1 = Hcp3TSubjectInfo('HCP_900', '100206')
    subject_info2 = Hcp3TSubjectInfo('HCP_500', '100307')

    _inform(os.linesep)
    _inform("-- Showing the Hcp3TSubjectInfo objects --")
    _inform(str(subject_info1))
    _inform(str(subject_info2))

    _inform(os.linesep)
    _inform("-- Writing the Hcp3TSubjectInfo objects to a text file: " + test_file_name + " --")
    subject_info_list_out = []
    subject_info_list_out.append(subject_info1)
    subject_info_list_out.append(subject_info2)
    write_subject_info_list(test_file_name, subject_info_list_out)

    _inform(os.linesep)
    _inform("-- Retrieving the list of Hcp3TSubjectInfo objects from the text file: " + test_file_name + " --")
    subject_info_list_in = read_subject_info_list(test_file_name)

    _inform(os.linesep)
    _inform("-- Showing the list of Hcp3TSubjectInfo objects --")
    for subject_info in subject_info_list_in:
        _inform(subject_info)

    _inform(os.linesep)
    _inform("-- Removing text file " + test_file_name + " --")
    os.remove(test_file_name)

if __name__ == '__main__':
    _simple_interactive_demo()
