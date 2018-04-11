#!/usr/bin/env python3

"""user_utils.py: Some simple and hopefully useful utilities for interacting with the user."""

# import of built-in modules
import getpass
import os

# import of third-party modules

# import of local modules
import utils.my_configparser as my_configparser

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def should_proceed():
    proceed = input("Proceed? [n]: ").lower()
    return proceed == 'y' or proceed == 'yes'


def get_credentials_from_credentials_file(system_id):

    home_dir = os.getenv('HOME')
    if not home_dir:
        return (None, None)

    credentials_file_name = home_dir + os.sep + '.' + system_id + '.credentials'

    if not os.path.isfile(credentials_file_name):
        return (None, None)
    
    config = my_configparser.MyConfigParser()
    config.read(credentials_file_name)

    username = config.get_value(system_id, 'Username')
    password = config.get_value(system_id, 'Password')
    return (username, password)


def get_credentials(system_id):

    userid, password = get_credentials_from_credentials_file(system_id)

    if userid:
        return (userid, password)

    userid = input(system_id + " Username: ")
    password = getpass.getpass(system_id + " Password: ")

    return (userid, password)
