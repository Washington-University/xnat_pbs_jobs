#!/usr/bin/env python3

"""utils/delete_resource.py: Delete a Connectome DB Resource."""

# import of built-in modules
import getpass
import os
import subprocess
import sys

# import of third party modules

# import of local modules
import utils.my_argparse as my_argparse
import utils.os_utils as os_utils
import utils.str_utils as str_utils
import utils.user_utils as user_utils
import xnat.xnat_access as xnat_access

# authorship information
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
	"""Inform the user of this program by outputing a message that is prefixed by the file name.

	:param msg: Message to output
	:type msg: str
	"""
	print(os.path.basename(__file__) + ": " + msg)


def delete_resource(user, password, server, project, subject, session, resource, perform_delete=True):
	# get XNAT session id
	xnat_session_id = xnat_access.get_session_id(server=str_utils.get_server_name(server), username=user, password=password,
												 project=project, subject=subject, session=session)

	resource_url = ''
	resource_url += 'https://' + str_utils.get_server_name(server)
	resource_url += '/REST/projects/' + project
	resource_url += '/subjects/' + subject
	resource_url += '/experiments/' + xnat_session_id
	resource_url += '/resources/' + resource

	variable_values = '?removeFiles=true'

	resource_uri = resource_url + variable_values

	pipeline_engine = os_utils.getenv_required('XNAT_PBS_JOBS_PIPELINE_ENGINE')

	delete_cmd = 'java -Xmx1024m -jar ' + pipeline_engine + os.sep + 'lib' + os.sep + 'xnat-data-client-1.6.4-SNAPSHOT-jar-with-dependencies.jar'
	delete_cmd += ' -u ' + user
	delete_cmd += ' -p ' + password
	delete_cmd += ' -m DELETE'
	delete_cmd += ' -r ' + resource_uri

	if perform_delete:
		_inform("Deleting")
		_inform("    Server: " + server)
		_inform("   Project: " + project)
		_inform("   Subject: " + subject)
		_inform("   Session: " + session)
		_inform("  Resource: " + resource)

		completed_delete_process = subprocess.run(delete_cmd, shell=True, check=True)

	else:
		_inform("delete_cmd: " + delete_cmd)
		_inform("Deletion not attempted")


def main():
	# create a parser object for getting the command line options
	parser = my_argparse.MyArgumentParser(description="Program to delete a DB resource.")

	# mandatory arguments
	parser.add_argument('-u', '--user', dest='user', required=True, type=str)
	parser.add_argument('-pr', '--project', dest='project', required=True, type=str)
	parser.add_argument('-sub', '--subject', dest='subject', required=True, type=str)
	parser.add_argument('-ses', '--session', dest='session', required=True, type=str)
	parser.add_argument('-r', '--resource', dest='resource', required=True, type=str)

	# optional arguments
	parser.add_argument('-ser', '--server', dest='server', required=False,
						default='https://' + os_utils.getenv_required('XNAT_PBS_JOBS_XNAT_SERVER'),
						type=str)
	parser.add_argument('-f', '--force', dest='force', action="store_true", required=False, default=False)
	parser.add_argument('-pw', '--password', dest='password', required=False, type=str)

	# parse the command line arguments
	args = parser.parse_args()

	if args.password:
		password = args.password
	else:
		password = getpass.getpass("Password: ")

	# show parsed arguments
	_inform("Parsed arguments:")
	_inform("  Username: " + args.user)
	_inform("  Password: " + "*** password mask ***")
	_inform("    Server: " + args.server)
	_inform("   Project: " + args.project)
	_inform("   Subject: " + args.subject)
	_inform("   Session: " + args.session)
	_inform("  Resource: " + args.resource)
	_inform("     Force: " + str(args.force))

	if args.force:
		delete_it = True
	elif user_utils.should_proceed():
		delete_it = True
	else:
		delete_it = False

	delete_resource(args.user, password, args.server,
					args.project, args.subject, args.session, args.resource,
					delete_it)


if __name__ == '__main__':
	main()
