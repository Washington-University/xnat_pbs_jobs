#!/usr/bin/env python3

# import of built-in modules
import logging
import sys

# import of third-party modules
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QAction
from PyQt5.QtWidgets import QApplication
from PyQt5.QtWidgets import QTableWidget
from PyQt5.QtWidgets import QTableWidgetItem
from PyQt5.QtWidgets import QVBoxLayout
from PyQt5.QtWidgets import QWidget
from PyQt5.QtWidgets import qApp
from PyQt5.QtCore import Qt

# import of local modules
import utils.file_utils as file_utils

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"

# configure logging and create a module logger
module_logger = logging.getLogger(file_utils.get_logger_name(__file__))
module_logger.setLevel(logging.INFO) # Note: This can be overridden by file configuration

class StatusInfo(object):

    def __init__(self, project, subject_id):
        super().__init__()
        self.project = project
        self.subject_id = subject_id

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

        
class MyMainWindow(QWidget):

    def __init__(self):
        super().__init__()
        self.title = "Structural Preprocessing Control Panel"
        self.left = 0
        self.top = 0
        self.width = 400
        self.height = 200
        self.initUI()
        self.show()

    def initUI(self):

        # exitAction = QAction('&Exit', self)
        # exitAction.setShortcut('Ctrl+Q')
        # exitAction.setStatusTip('Exit Application')
        # exitAction.triggered.connect(qApp.quit)

        # menubar = self.menuBar()
        # fileMenu = menubar.addMenu('&File')
        # fileMenu.addAction(exitAction)

        self.setWindowTitle(self.title)
        self.setGeometry(self.left, self.top, self.width, self.height)

        self.createTable()
        
        self.layout = QVBoxLayout()
        self.layout.addWidget(self.tableWidget)
        self.setLayout(self.layout)
        
    def createTable(self):
        self.tableWidget = QTableWidget()
        self.tableWidget.setRowCount(4)
        self.tableWidget.setColumnCount(2)
        self.tableWidget.setHorizontalHeaderLabels(["Project", "Subject ID"])
        
        self.tableWidget.move(0,0)
        
    def setStatusItem(self, status_item, row):
        self.tableWidget.setItem(row, 0, QTableWidgetItem(status_item.project))
        self.tableWidget.item(row, 0).setTextAlignment(Qt.AlignCenter)
        
        self.tableWidget.setItem(row, 1, QTableWidgetItem(status_item.subject_id))
        self.tableWidget.item(row, 1).setTextAlignment(Qt.AlignCenter)

    def setStatusList(self, status_list):

        self.tableWidget.setRowCount(len(status_list))
        
        row = 0
        for status_item in status_list:
            self.setStatusItem(status_item, row)
            row += 1
            
    
if __name__ == "__main__":

    app = QApplication(sys.argv)
    main = MyMainWindow()


    status_list = []
    status_list.append(StatusInfo("HCP_1200", "123456"))
    status_list.append(StatusInfo("HCP_1200", "789012"))
    status_list.append(StatusInfo("HCP_1200", "345678"))
    status_list.append(StatusInfo("HCP_1200", "109287"))
    status_list.append(StatusInfo("HCP_1200", "888888"))
    status_list.append(StatusInfo("HCP_1200", "999000"))
    

    main.setStatusList(status_list)
    
    sys.exit(app.exec_())
    
