#!/usr/bin/env python3

# import of built-in modules
import logging
import sys

# import of third-party modules
from PyQt5.QtCore import Qt
from PyQt5.QtCore import pyqtSlot
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QProgressBar
from PyQt5.QtWidgets import QAbstractItemView
from PyQt5.QtWidgets import QAbstractScrollArea
from PyQt5.QtWidgets import QAction
from PyQt5.QtWidgets import QApplication
from PyQt5.QtWidgets import QHBoxLayout
from PyQt5.QtWidgets import QMainWindow
from PyQt5.QtWidgets import QPushButton
from PyQt5.QtWidgets import QTableWidget
from PyQt5.QtWidgets import QTableWidgetItem
from PyQt5.QtWidgets import QVBoxLayout
from PyQt5.QtWidgets import QWidget
from PyQt5.QtWidgets import qApp

# import of local modules
import ccf.archive as ccf_archive
import ccf.structural_preprocessing.one_subject_completion_checker as one_subject_completion_checker
import ccf.structural_preprocessing.one_subject_prereq_checker as one_subject_prereq_checker
import ccf.structural_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.subject as ccf_subject
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
module_logger.setLevel(logging.INFO) # Note: This can be overridden by file configuration

class StatusInfo(object):

    def __init__(self, project, subject_id, classifier,
                 prerequisites_met, output_resource, output_resource_exists,
                 processing_complete, run_status):
        super().__init__()
        self.project = project
        self.subject_id = subject_id
        self.classifier = classifier
        self.prerequisites_met = prerequisites_met
        self.output_resource = output_resource
        self.output_resource_exists = output_resource_exists
        self.processing_complete = processing_complete
        self.run_status = run_status
        
    @property
    def project(self):
        return self._project

    @project.setter
    def project(self, value):
        self._project = value

    @property
    def subject_id(self):
        return self._subject_id

    @subject_id.setter
    def subject_id(self, value):
        self._subject_id = value

    @property
    def classifier(self):
        return self._classifier

    @classifier.setter
    def classifier(self, value):
        self._classifier = value

    @property
    def prerequisites_met(self):
        return self._prerequisites_met

    @prerequisites_met.setter
    def prerequisites_met(self, value):
        self._prerequisites_met = value

    @property
    def output_resource(self):
        return self._output_resource

    @output_resource.setter
    def output_resource(self, value):
        self._output_resource = value

    @property
    def output_resource_exists(self):
        return self._output_resource_exists

    @output_resource_exists.setter
    def output_resource_exists(self, value):
        self._output_resource_exists = value

    @property
    def processing_complete(self):
        return self._processing_complete

    @processing_complete.setter
    def processing_complete(self, value):
        self._processing_complete = value

    @property
    def run_status(self):
        return self._run_status

    @run_status.setter
    def run_status(self, value):
        self._run_status = value
        
        
class ControlPanelWidget(QWidget):

    def __init__(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
        super().__init__()

        self._archive = archive
        self._prereq_checker = prereq_checker
        self._completion_checker = completion_checker
        self._run_status_checker = run_status_checker
        
        self.createTable()

        refresh_button = QPushButton("Refresh", self)
        refresh_button.clicked.connect(self.on_refresh_click)
        
        select_incomplete_button = QPushButton("Select Incomplete", self)
        select_incomplete_button.clicked.connect(self.on_select_incomplete)

        launch_button = QPushButton("Launch", self)
        launch_button.clicked.connect(self.on_launch_click)

        self.layout = QVBoxLayout()
        self.layout.addWidget(self.tableWidget)

        button_box = QHBoxLayout()
        button_box.addWidget(refresh_button)
        button_box.addWidget(select_incomplete_button)
        button_box.addWidget(launch_button)

        self.layout.addLayout(button_box)

        self.setLayout(self.layout)

        self.subject_list = subject_list
        
    @pyqtSlot()
    def on_refresh_click(self):
        print("refreshing")
        new_subject_list = self.subject_list[:]
        self.subject_list = new_subject_list
        print("done refreshing")
        
    @pyqtSlot()
    def on_launch_click(self):
        print("on_launch_click")
        
        launch_subject_list = []
        
        selection = self.tableWidget.selectionModel()

        for selected in selection.selectedRows():
            launch_subject_list.append(self.subject_list[selected.row()])

        if len(launch_subject_list) < 1:
            print("No selected rows")

        else:
            for launch_subject in launch_subject_list:
                print("Launching jobs for subject", launch_subject)

    @pyqtSlot()
    def on_select_incomplete(self):
        print("on_select_incomplete")
    
    @property
    def archive(self):
        return self._archive

    @property
    def prereq_checker(self):
        return self._prereq_checker

    @property
    def completion_checker(self):
        return self._completion_checker

    @property
    def run_status_checker(self):
        return self._run_status_checker

    @property
    def header_labels(self):
        return ["Project", "Subject ID", "Classifier", "Prereqs Met", "Resource", "Exists", "Complete", "Queued/Running"]
    
    def createTable(self):
        self.tableWidget = QTableWidget()
        #self.tableWidget.setRowCount(rows)
        self.tableWidget.setColumnCount(len(self.header_labels))
        self.tableWidget.setSelectionBehavior(QAbstractItemView.SelectRows)
        self.tableWidget.setSizeAdjustPolicy(QAbstractScrollArea.AdjustToContents)
    
    @property
    def subject_list(self):
        return self._subject_list

    @subject_list.setter
    def subject_list(self, value):
        self._subject_list = value
        
        status_list = []

        for subject in self._subject_list:
            prereqs_met = self.prereq_checker.are_prereqs_met(self.archive, subject)
            resource = self.archive.structural_preproc_dir_name(subject)
            resource_exists = self.completion_checker.does_processed_resource_exist(self.archive, subject)
            processing_complete = self.completion_checker.is_processing_marked_complete(self.archive, subject)
            #run_status = self.run_status_checker.get_run_status(subject)
            run_status = self.run_status_checker.get_queued_or_running(subject)
            
            #print("Appending: ", subject.project, subject.subject_id, subject.classifier, prereqs_met, resource, resource_exists, processing_complete, run_status)
            status_list.append(StatusInfo(subject.project, subject.subject_id, subject.classifier,
                                          prereqs_met, resource, resource_exists, processing_complete, run_status))

        self.setStatusList(status_list)

    def setStatusList(self, status_list):
        self.tableWidget.clear()
        self.tableWidget.setHorizontalHeaderLabels(self.header_labels)
        self.tableWidget.setRowCount(0)
        
        self.tableWidget.setRowCount(len(status_list))

        row = 0
        for status_item in status_list:
            self.setStatusItem(status_item, row)
            row += 1

        self.tableWidget.resizeColumnsToContents()

    def setStatusItem(self, status_item, row):
        self.tableWidget.setItem(row, 0, QTableWidgetItem(status_item.project))
        self.tableWidget.item(row, 0).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 1, QTableWidgetItem(status_item.subject_id))
        self.tableWidget.item(row, 1).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 2, QTableWidgetItem(status_item.classifier))
        self.tableWidget.item(row, 2).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 3, QTableWidgetItem(str(status_item.prerequisites_met)))
        self.tableWidget.item(row, 3).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 4, QTableWidgetItem(str(status_item.output_resource)))
        self.tableWidget.item(row, 4).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 5, QTableWidgetItem(str(status_item.output_resource_exists)))
        self.tableWidget.item(row, 5).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 6, QTableWidgetItem(str(status_item.processing_complete)))
        self.tableWidget.item(row, 6).setTextAlignment(Qt.AlignCenter)

        self.tableWidget.setItem(row, 7, QTableWidgetItem(str(status_item.run_status)))
        self.tableWidget.item(row, 7).setTextAlignment(Qt.AlignCenter)

        
class MyMainWindow(QMainWindow):

    def __init__(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
        super().__init__()
        self.title = "Structural Preprocessing Mini Control Panel"

        exitAction = QAction('&Exit', self)
        exitAction.setShortcut('Ctrl+Q')
        exitAction.setStatusTip('Exit Application')
        exitAction.triggered.connect(qApp.quit)
        
        menubar = self.menuBar()
        fileMenu = menubar.addMenu('&File')
        fileMenu.addAction(exitAction)

        self.left = 0
        self.top = 0
        self.width = 600
        self.height = 200

        self.initUI(archive, subject_list, prereq_checker, completion_checker, run_status_checker)

        #self.progress = QProgressBar(self)
        #self.progress.setGeometry(200, 80, 250, 20)
        
        self.show()
        
    def initUI(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)
        
        self.createControlPanel(archive, subject_list, prereq_checker, completion_checker, run_status_checker)

    def createControlPanel(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
        self.controlPanel = ControlPanelWidget(archive, subject_list, prereq_checker, completion_checker, run_status_checker)
        self.setCentralWidget(self.controlPanel)

     
if __name__ == "__main__":

    # get list of subjects to work with
    subject_file_name = file_utils.get_subjects_file_name(__file__)
    print("Retrieving subject list from: " + subject_file_name)
    subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")

    archive = ccf_archive.CcfArchive()
    prereq_checker = one_subject_prereq_checker.OneSubjectPrereqChecker()
    completion_checker = one_subject_completion_checker.OneSubjectCompletionChecker()
    run_status_checker = one_subject_run_status_checker.OneSubjectRunStatusChecker()

    app = QApplication(sys.argv)
    main = MyMainWindow(archive,
                        subject_list,
                        prereq_checker,
                        completion_checker,
                        run_status_checker)

    sys.exit(app.exec_())

