#!/usr/bin/env python3

# import of built-in modules
import datetime
import logging
import os
import sys
import subprocess

# import of third-party modules
from PyQt5.QtCore import Qt
from PyQt5.QtCore import pyqtSlot
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QAbstractItemView
from PyQt5.QtWidgets import QAbstractScrollArea
from PyQt5.QtWidgets import QAction
from PyQt5.QtWidgets import QApplication
from PyQt5.QtWidgets import QDialog
from PyQt5.QtWidgets import QErrorMessage
from PyQt5.QtWidgets import QFileDialog
from PyQt5.QtWidgets import QHBoxLayout
from PyQt5.QtWidgets import QMainWindow
from PyQt5.QtWidgets import QProgressBar
from PyQt5.QtWidgets import QPushButton
from PyQt5.QtWidgets import QTableWidget
from PyQt5.QtWidgets import QTableWidgetItem
from PyQt5.QtWidgets import QVBoxLayout
from PyQt5.QtWidgets import QWidget
from PyQt5.QtWidgets import qApp

# import of local modules
import ccf.archive as ccf_archive
import ccf.functional_preprocessing.SubmitFunctionalPreprocessingBatch as SubmitFunctionalPreprocessingBatch
import ccf.functional_preprocessing.one_subject_completion_checker as one_subject_completion_checker
import ccf.functional_preprocessing.one_subject_prereq_checker as one_subject_prereq_checker
import ccf.functional_preprocessing.one_subject_run_status_checker as one_subject_run_status_checker
import ccf.subject as ccf_subject
import qt_utils.login_dialog as login_dialog
import utils.file_utils as file_utils
import utils.my_configparser as my_configparser

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
# Note: The following can be overridden by file configuration
module_logger.setLevel(logging.INFO) 

DNM = "---"  # Does Not Matter
NA = "N/A"  # Not Available
DATE_FORMAT = '%Y-%m-%d %H:%M:%S'


class StatusInfo(object):

	def __init__(self, project, subject_id, classifier, scan,
				 prerequisites_met, output_resource, output_resource_exists, output_resource_date,
				 processing_complete, run_status):
		super().__init__()
		self.project = project
		self.subject_id = subject_id
		self.classifier = classifier
		self.scan = scan
		self.prerequisites_met = prerequisites_met
		self.output_resource = output_resource
		self.output_resource_exists = output_resource_exists
		self.output_resource_date = output_resource_date
		self.processing_complete = processing_complete
		self.run_status = run_status

	def __str__(self):
		return "\t".join([self.project,
						  self.subject_id,
						  self.classifier,
						  self.scan,
						  str(self.prerequisites_met),
						  self.output_resource,
						  str(self.output_resource_exists),
						  self.output_resource_date,
						  str(self.processing_complete),
						  str(self.run_status)])
		
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
	def scan(self):
		return self._scan

	@scan.setter
	def scan(self, value):
		self._scan = value
		
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
	def output_resource_date(self):
		return self._output_resource_date

	@output_resource_date.setter
	def output_resource_date(self, value):
		self._output_resource_date = value
		
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

		self._login = login_dialog.LoginDialog(self)
		
		self._archive = archive
		self._prereq_checker = prereq_checker
		self._completion_checker = completion_checker
		self._run_status_checker = run_status_checker
		
		self.createTable()

		export_button = QPushButton("Export", self)
		export_button.clicked.connect(self.on_export_click)

		refresh_button = QPushButton("Refresh", self)
		refresh_button.clicked.connect(self.on_refresh_click)
		
		select_button = QPushButton("Select Runnable, Incomplete, and Not Running", self)
		select_button.clicked.connect(self.on_select_click)

		launch_button = QPushButton("Launch", self)
		launch_button.clicked.connect(self.on_launch_click)

		self.layout = QVBoxLayout()
		self.layout.addWidget(self.tableWidget)

		button_box = QHBoxLayout()
		button_box.addWidget(export_button)
		button_box.addWidget(refresh_button)
		button_box.addWidget(select_button)
		button_box.addWidget(launch_button)

		self.layout.addLayout(button_box)

		self.setLayout(self.layout)

		self.subject_list = subject_list

	@pyqtSlot()
	def on_export_click(self):
		self.exportTable()
		
	@pyqtSlot()
	def on_refresh_click(self):
		new_subject_list = self.subject_list[:]
		self.subject_list = new_subject_list
		
	@pyqtSlot()
	def open_config_file(self):
		control_location = os.getenv('XNAT_PBS_JOBS_CONTROL', default="")

		options = QFileDialog.Options()
		config_file_name, other_stuff = QFileDialog.getOpenFileName(self, "Open Config File", control_location, "Config Files (*.ini);;All Files (*)", options=options)
		if config_file_name:
			print("Reading configuration from file: " + config_file_name)
			self.config = my_configparser.MyConfigParser()
			self.config.read(config_file_name)		
			return True
	
	@pyqtSlot()
	def on_launch_click(self):
		
		launch_subject_list = []
		
		selection = self.tableWidget.selectionModel()

		for selected in selection.selectedRows():
			launch_subject_list.append(self.subject_list[selected.row()])

		if len(launch_subject_list) < 1:
			error_dialog = QErrorMessage(self)
			error_dialog.showMessage("No selected rows!\nTo launch processing, please select the rows for the sessions/scans you want to launch.")
			error_dialog.show()
			
		else:
			if self.open_config_file(): 
				if self._login.exec_() == QDialog.Accepted:
					for one_subject in launch_subject_list:
						project,subject_id,classifier,extra = str(one_subject).split(":")
					
						clean_output_first = self.config.get_bool_value(subject_id, 'CleanOutputFirst')
						processing_stage = self.config.get_value(subject_id, 'ProcessingStage')
						walltime_limit_hrs = self.config.get_value(subject_id, 'WalltimeLimitHours')
						vmem_limit_gbs = self.config.get_value(subject_id, 'VmemLimitGbs')
						output_resource_suffix = self.config.get_value(subject_id, 'OutputResourceSuffix')

						self.submitJob(self._login.username, self._login.password, project, subject_id, classifier, extra,
												str(clean_output_first), processing_stage, walltime_limit_hrs, vmem_limit_gbs,
												output_resource_suffix)			
					self.on_refresh_click()	
			
	@pyqtSlot()
	def on_select_click(self):

		self.tableWidget.clearSelection()
		
		for index, subject in enumerate(self.subject_list):
			prereqs_met = self.prereq_checker.are_prereqs_met(self.archive, subject)
			processing_complete = self.completion_checker.is_processing_marked_complete(self.archive, subject)
			queued_or_running = self.run_status_checker.get_queued_or_running(subject)

			if prereqs_met and (not processing_complete) and (not queued_or_running):
				self.tableWidget.selectRow(index)
		
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
		return ["Project", "Subject ID", "Classifier", "Scan", "Prereqs Met", "Resource", "Exists", "Resource Date", "Complete", "Queued/Running"]
	
	def createTable(self):
		self.tableWidget = QTableWidget()
		#self.tableWidget.setRowCount(rows)
		self.tableWidget.setColumnCount(len(self.header_labels))
		self.tableWidget.setSelectionBehavior(QAbstractItemView.SelectRows)
		self.tableWidget.setSelectionMode(QAbstractItemView.MultiSelection)
		self.tableWidget.setSizeAdjustPolicy(QAbstractScrollArea.AdjustToContents)
	
	@property
	def subject_list(self):
		return self._subject_list

	def build_status_list(self, subject_list):

		status_list = []

		for subject in self._subject_list:
			prereqs_met = self.prereq_checker.are_prereqs_met(self.archive, subject)
			resource = self.archive.functional_preproc_dir_name(subject)
			resource_exists = self.completion_checker.does_processed_resource_exist(self.archive, subject)

			if resource_exists:
				resource_fullpath = self.archive.functional_preproc_dir_full_path(subject)
				timestamp = os.path.getmtime(resource_fullpath)
				resource_date = datetime.datetime.fromtimestamp(timestamp).strftime(DATE_FORMAT)
			else:
				resource = DNM
				resource_date = NA
			
			processing_complete = self.completion_checker.is_processing_marked_complete(self.archive, subject)
			run_status = self.run_status_checker.get_queued_or_running(subject)
			
			status_list.append(StatusInfo(subject.project, subject.subject_id,
										  subject.classifier, subject.extra,
										  prereqs_met, resource, resource_exists, resource_date,
										  processing_complete, run_status))

		return status_list
	
	@subject_list.setter
	def subject_list(self, value):
		self._subject_list = value		
		status_list = self.build_status_list(self._subject_list)
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

		self.tableWidget.setItem(row, 3, QTableWidgetItem(status_item.scan))
		self.tableWidget.item(row, 3).setTextAlignment(Qt.AlignCenter)
		
		self.tableWidget.setItem(row, 4, QTableWidgetItem(str(status_item.prerequisites_met)))
		self.tableWidget.item(row, 4).setTextAlignment(Qt.AlignCenter)

		self.tableWidget.setItem(row, 5, QTableWidgetItem(str(status_item.output_resource)))
		self.tableWidget.item(row, 5).setTextAlignment(Qt.AlignCenter)

		self.tableWidget.setItem(row, 6, QTableWidgetItem(str(status_item.output_resource_exists)))
		self.tableWidget.item(row, 6).setTextAlignment(Qt.AlignCenter)

		self.tableWidget.setItem(row, 7, QTableWidgetItem(str(status_item.output_resource_date)))
		self.tableWidget.item(row, 7).setTextAlignment(Qt.AlignCenter)

		self.tableWidget.setItem(row, 8, QTableWidgetItem(str(status_item.processing_complete)))
		self.tableWidget.item(row, 8).setTextAlignment(Qt.AlignCenter)

		self.tableWidget.setItem(row, 9, QTableWidgetItem(str(status_item.run_status)))
		self.tableWidget.item(row, 9).setTextAlignment(Qt.AlignCenter)

	def exportTable(self):
		status_list = self.build_status_list(self._subject_list)
		options = QFileDialog.Options()
		status_file_name, other_stuff = QFileDialog.getSaveFileName(self, "Save Status File", "", "Status Files (*.status);;All Files (*)", options=options)

		if status_file_name:
			status_file = open(status_file_name, "w")

			header_string = "\t".join(self.header_labels)
			print(header_string, file=status_file)
			for status_info in status_list:
				print(status_info, file=status_file)
				
	def submitJob(self, username, password, project, subject_id, classifier, scan, clean_output_first, processing_stage, walltime_limit_hrs, vmem_limit_gbs, output_resource_suffix):
		result = subprocess.call([os.environ["XNAT_PBS_JOBS"] + "/lib/ccf/functional_preprocessing/submit_job.py", username, password, 
									project, subject_id, classifier, scan, clean_output_first, processing_stage, 
									walltime_limit_hrs, vmem_limit_gbs, output_resource_suffix])
		print (result)
		
class MyMainWindow(QMainWindow):

	def __init__(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
		super().__init__()
		self.title = "CCF Functional Preprocessing Control"

		exitAction = QAction('&Exit', self)
		exitAction.setShortcut('Ctrl+Q')
		exitAction.setStatusTip('Exit Application')
		exitAction.triggered.connect(qApp.quit)

		openAction = QAction('&Open...', self)
		openAction.setShortcut('Ctrl+O')
		openAction.setStatusTip('Open Subjects File')
		openAction.triggered.connect(self.open_subjects_file)

		menubar = self.menuBar()
		fileMenu = menubar.addMenu('&File')
		fileMenu.addAction(openAction)
		fileMenu.addAction(exitAction)
		
		self.left = 0
		self.top = 0
		self.width = 900
		self.height = 500

		self.initUI(archive, subject_list, prereq_checker, completion_checker, run_status_checker)

		self.show()

	def open_subjects_file(self):
		control_location = os.getenv('XNAT_PBS_JOBS_CONTROL', default="")

		options = QFileDialog.Options()
		#options |= QFileDialog.DontUseNativeDialog
		#subject_file_name, other_stuff = QFileDialog.getOpenFileName(self, "Open Subject File", "", "Subject Files (*.subjects);;All Files (*)", options=options)
		subject_file_name, other_stuff = QFileDialog.getOpenFileName(self, "Open Subject File", control_location, "Subject Files (*.subjects);;All Files (*)", options=options)
		if subject_file_name:
			new_subject_list = ccf_subject.read_subject_info_list(subject_file_name, separator=":")
			self.controlPanel.subject_list = new_subject_list
		
	def initUI(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
		self.setWindowTitle(self.title)
		self.setGeometry(self.left, self.top, self.width, self.height)
		
		self.createControlPanel(archive, subject_list, prereq_checker, completion_checker, run_status_checker)

	def createControlPanel(self, archive, subject_list, prereq_checker, completion_checker, run_status_checker):
		self.controlPanel = ControlPanelWidget(archive, subject_list, prereq_checker, completion_checker, run_status_checker)
		self.setCentralWidget(self.controlPanel)

		
if __name__ == "__main__":

	subject_list = []
	
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

