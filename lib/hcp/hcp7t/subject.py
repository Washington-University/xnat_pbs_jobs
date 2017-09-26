#!/usr/bin/env python3

"""hcp/hcp7t/subject.py: Maintain information about an HCP 7T subject.

The module also provides services for reading and writing lists of such subjects
in simple text files.
"""

# import of built-in modules
import os
import sys

# import of third party modules

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


class Hcp7TSubjectInfo(hcp_subject.HcpSubjectInfo):
    """This class maintains information about an HCP 7T subject."""

    def __init__(self, project=None, structural_reference_project=None, subject_id=None, extra=None):
        """Constructs an Hcp7TSubjectInfo object.

        :param project: project to which this subject belongs (e.g. HCP_Staging_7T)
        :type project: str

        :param structural_reference_project: project where this subjects structural reference scans exist (e.g. HCP_900)
        :type structural_reference_project: str

        :param subject_id: subject id (e.g. 100307)
        :type subject_id: str

        :param extra: extra information used for processing the subject
                      (e.g. incomplete = means only process scans for which the current processing is incomplete)
        :type extra: str
        """
        super().__init__(project, subject_id, extra)
        self._structural_reference_project = structural_reference_project

    @property
    def structural_reference_project(self):
        """Project in which subject's structural reference scans exist."""
        return self._structural_reference_project

    def __str__(self):
        """Returns the informal string representation."""
        separator = super().DEFAULT_SEPARATOR()
        project = 'None'
        ref_project = 'None'
        subject_id = 'None'
        extra = 'None'
        
        if self.project:
            project = self.project

        if self.structural_reference_project:
            ref_project = self.structural_reference_project

        if self.subject_id:
            subject_id = self.subject_id

        if self.extra:
            extra = self.extra

        result_str = separator.join([project, ref_project, subject_id, extra])
        return result_str

def read_subject_info_list(file_name, separator=Hcp7TSubjectInfo.DEFAULT_SEPARATOR()):
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
            try:
                (project, structural_ref_project, subject_id, extra) = line.split(separator)
            except ValueError as e:
                if str(e) == 'not enough values to unpack (expected 4, got 3)':
                    (project, structural_ref_project, subject_id) = line.split(separator)
                    extra = None
                else:
                    raise

            # Make the string 'None' in the file translate to a None type instead of just the
            # string itself
            if project == 'None':
                project = None
            if structural_ref_project == 'None':
                structural_ref_project = None
            if subject_id == 'None':
                subject_id = None
            if extra == 'None':
                extra = None

            subject_info = Hcp7TSubjectInfo(project, structural_ref_project, subject_id, extra)
            subject_info_list.append(subject_info)

    input_file.close()
    return subject_info_list


def read_subject_id_list(file_name):
    """Reads a subject id list from the specified file."""

    subject_id_list = []

    input_file = open(file_name, 'r')
    for line in input_file:
        # remove new line characters
        line = str_utils.remove_ending_new_lines(line)

        # remove leading and trailing spaces
        line = line.strip()

        # ignore blank lines and comment lines - starting with #
        if line != '' and line[0] != '#':
            subject_id = line
            subject_id_list.append(subject_id)

    input_file.close()
    return subject_id_list


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

    test_file_name = 'hcp7t_subject.test_subjects.txt'

    _inform(os.linesep)
    _inform("-- Creating 2 Hcp7TSubjectInfo objects --")
    subject_info1 = Hcp7TSubjectInfo('HCP_Staging_7T', 'HCP_900', '100206')
    subject_info2 = Hcp7TSubjectInfo('HCP_Staging_7T', 'HCP_500', '100307')

    _inform(os.linesep)
    _inform("-- Showing the Hcp7TSubjectInfo objects --")
    _inform(str(subject_info1))
    _inform(str(subject_info2))

    _inform(os.linesep)
    _inform("-- Writing the Hcp7TSubjectInfo objects to a text file: " + test_file_name + " --")
    subject_info_list_out = []
    subject_info_list_out.append(subject_info1)
    subject_info_list_out.append(subject_info2)
    write_subject_info_list(test_file_name, subject_info_list_out)

    _inform(os.linesep)
    _inform("-- Retrieving the list of Hcp7TSubjectInfo objects from the text file: " + test_file_name + " --")
    subject_info_list_in = read_subject_info_list(test_file_name)

    _inform(os.linesep)
    _inform("-- Showing the list of Hcp7TSubjectInfo objects --")
    for subject_info in subject_info_list_in:
        _inform(subject_info)

    _inform(os.linesep)
    _inform("-- Removing text file " + test_file_name + " --")
    os.remove(test_file_name)


if __name__ == '__main__':
    _simple_interactive_demo()
