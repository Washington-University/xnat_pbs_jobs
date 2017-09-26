#!/usr/bin/env python3

# import of built-in modules

# import of third-party modules
from PyQt5.QtWidgets import QDialog
from PyQt5.QtWidgets import QDialogButtonBox
from PyQt5.QtWidgets import QGridLayout
from PyQt5.QtWidgets import QLabel
from PyQt5.QtWidgets import QLineEdit

# import of local modules

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2017, The Human Connectome Project/Connectome Coordination Facility"
__maintainer__ = "Timothy B. Brown"


class LoginDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)

        self._username = None
        self._password = None

        self.label_username = QLabel(self)
        self.label_username.setText("Username")
        self.text_username = QLineEdit(self)

        self.label_password = QLabel(self)
        self.label_password.setText("Password")
        self.text_password = QLineEdit(self)
        self.text_password.setEchoMode(QLineEdit.Password)

        self.buttons = QDialogButtonBox(self)
        self.buttons.addButton(QDialogButtonBox.Ok)
        self.buttons.addButton(QDialogButtonBox.Cancel)

        self.buttons.button(QDialogButtonBox.Ok).clicked.connect(self.ok_pressed)
        self.buttons.button(QDialogButtonBox.Cancel).clicked.connect(self.cancel_pressed)
 
        layout = QGridLayout(self)
       
        layout.addWidget(self.label_username, 0, 0)
        layout.addWidget(self.text_username, 0, 1)
        layout.addWidget(self.label_password, 1, 0)
        layout.addWidget(self.text_password, 1, 1)
        layout.addWidget(self.buttons, 2, 0, 1, 2)

    @property
    def username(self):
        return self._username

    @property
    def password(self):
        return self._password

    @property
    def has_values(self):
        return self._username != None and self._password != None
    
    def ok_pressed(self):
        self._username = self.text_username.text()
        self._password = self.text_password.text()
        self.accept()

    def cancel_pressed(self):
        self.close()
        
