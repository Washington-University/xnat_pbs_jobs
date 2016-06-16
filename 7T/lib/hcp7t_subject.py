#!/usr/bin/env python3

import os
import shutil

SEPARATOR = ':'

class Hcp7TSubjectInfo:
    
    def __init__(self, project = None, structural_reference_project = None, subject_id = None): 
        self.__subject_id = subject_id
        self.__project = project
        self.__structural_reference_project = structural_reference_project

    @property
    def subject_id(self):
        return self.__subject_id

    @subject_id.setter 
    def subject_id(self, subject_id):
        # may want to add a check later to make sure id is a 6 character 
        # string consisting of only digit characters.
        self.__subject_id = subject_id
        
    @property
    def project(self):
        return self.__project

    @project.setter
    def project(self, project):
        self.__project = project

    @property
    def structural_reference_project(self):
        return self.__structural_reference_project

    @structural_reference_project.setter
    def structural_reference_project(self, structural_reference_project):
        self.__structural_reference_project = structural_reference_project

    def __str__(self):
        return str(self.project + SEPARATOR + self.structural_reference_project + SEPARATOR + self.subject_id)


def read_subject_info_list(file_name):
    subject_info_list = []

    input_file = open(file_name, 'r')
    for line in input_file:
        if os.linesep == line[-1]:
            line = line[:-1]
        (project, structural_ref_project, subject_id) = line.split(SEPARATOR)
        subject_info = Hcp7TSubjectInfo(project, structural_ref_project, subject_id)
        subject_info_list.append(subject_info)

    return subject_info_list

def write_subject_info_list(file_name, subject_info_list):
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

 


