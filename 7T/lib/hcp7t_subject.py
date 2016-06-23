#!/usr/bin/env python3

"""hcp7t_subject.py: Maintain information about an HCP 7T subject.

The module also provides services for reading and writing lists of such subjects 
in simple text files.
"""

# import of built-in modules
import os
import shutil

# import of third party modules
pass

# path changes and import of local modules
pass

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"

"""Field separator used for reading and writing subject information in simple text files."""
__SEPARATOR__ = ':'

class Hcp7TSubjectInfo:
    """This class maintains information about an HCP 7T subject."""

    def __init__(self, project = None, structural_reference_project = None, subject_id = None, extra = None): 
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
        self.__subject_id = subject_id
        self.__project = project
        self.__structural_reference_project = structural_reference_project
        self.__extra = extra

    @property
    def subject_id(self):
        """Subject ID"""
        return self.__subject_id

    @subject_id.setter 
    def subject_id(self, subject_id):
        """Sets the subject_id property

        Note: May want to add a check later to make sure id is a 6 character 
              string consisting of only digit characters.
              
        """
        self.__subject_id = subject_id
        
    @property
    def project(self):
        """Primary 7T project"""
        return self.__project

    @project.setter
    def project(self, project):
        """Sets the project property"""
        self.__project = project

    @property
    def structural_reference_project(self):
        """Project in which subject's structural reference scans exist."""
        return self.__structural_reference_project

    @structural_reference_project.setter
    def structural_reference_project(self, structural_reference_project):
        """Sets the structural_reference_project property"""
        self.__structural_reference_project = structural_reference_project

    @property
    def extra(self):
        """Extra processing information"""
        return self.__extra

    @extra.setter
    def extra(self, extra):
        """Sets the extra property"""
        self.__extra = extra

    def __str__(self):
        """Returns the informal string representation."""
        return str(self.project + __SEPARATOR__ + self.structural_reference_project + __SEPARATOR__ + self.subject_id + __SEPARATOR__ + str(self.extra))

def read_subject_info_list(file_name):
    """Reads a subject information list from the specified file.

    :param file_name: name of file from which to read
    :type file_name: str
    """
    subject_info_list = []

    input_file = open(file_name, 'r')
    for line in input_file:
        # remove new line character
        if os.linesep == line[-1]:
            line = line[:-1]

        # ignore comment lines - starting with #
        if line[0] != '#':
            (project, structural_ref_project, subject_id, extra) = line.split(__SEPARATOR__)
            # Make the string 'None' in the file translate to a None type instead of just the 
            # string itself
            if extra == 'None':
                extra = None
            subject_info = Hcp7TSubjectInfo(project, structural_ref_project, subject_id, extra)
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

if __name__ == "__main__":
    test_file_name = 'hcp7t_subject.test_subjects.txt'

    print(os.linesep + '-- Creating 2 Hcp7TSubjectInfo objects --')
    subject_info1 = Hcp7TSubjectInfo()
    subject_info2 = Hcp7TSubjectInfo()

    subject_info1.subject_id = '100206'
    subject_info1.project = 'HCP_Staging_7T'
    subject_info1.structural_reference_project = 'HCP_900'

    subject_info2.subject_id = '100307'
    subject_info2.project = 'HCP_Staging_7T'
    subject_info2.structural_reference_project = 'HCP_500'

    print(os.linesep + '-- Showing the Hcp7TSubjectInfo objects --')
    print(str(subject_info1))
    print(str(subject_info2))

    print(os.linesep + '-- Writing the Hcp7TSubjectInfo objects to a text file: ' + test_file_name + ' --')
    subject_info_list_out = []
    subject_info_list_out.append(subject_info1)
    subject_info_list_out.append(subject_info2)
    write_subject_info_list(test_file_name, subject_info_list_out)

    print(os.linesep + '-- Retrieving the list of Hcp7TSubjectInfo objects from the text file: ' + test_file_name + ' --') 
    subject_info_list_in = read_subject_info_list(test_file_name)

    print(os.linesep + '-- Showing the list of Hcp7TSubjectInfo objects --')
    for subject_info in subject_info_list_in:
        print(subject_info)
    
    print(os.linesep + '-- Removing text file ' + test_file_name + ' --')
    os.remove(test_file_name)

 


