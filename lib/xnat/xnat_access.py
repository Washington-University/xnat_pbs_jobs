#!/usr/bin/env python3

"""xnat_access.py: Utilities for interacting with and XNAT instance."""

# import of built-in modules
import requests
import os
import inspect
import sys
import json
import time
import xml.etree.ElementTree as ET
import subprocess
import re
import urllib
import socket

from urllib.error import URLError, HTTPError
from ssl import SSLError

# import of third party modules
pass

# path changes and import of local modules
pass

# authorship information
# based on code originally written by either Mohana Ramaratnam or Tony Wilson
__author__ = "Timothy B. Brown"
__copyright__ = "Copyright 2016, The Human Connectome Project"
__maintainer__ = "Timothy B. Brown"


def _inform(msg):
    """Inform the user of this program by outputing a message that is prefixed by the file name.

    :param msg: Message to output
    :type msg: str
    """
    print(os.path.basename(__file__) + ": " + msg)


DEBUG = False


def _debug(msg):
    """ """
    # Note inspect.stack()[1][3] gives the name of the function that called this debug function
    if DEBUG:
        _inform(inspect.stack()[1][3] + ": DEBUG: " + msg)


def get_session_id(server, username, password, project, subject, session):

    request_url = 'https://' + server + '/data/projects/' + project + '/subjects/' + subject + '/experiments'
    _debug("request_url: " + request_url)

    response = requests.get(request_url, auth=(username, password))
    _debug("response: " + str(response))
    _debug("response.headers: " + str(response.headers))
    _debug("response.text: " + str(response.text))

    if (response.status_code != 200):
        _inform(inspect.stack()[0][3] + ": Cannot get response from request: " + request_url)
        sys.exit(1)

    if 'application/json' not in response.headers['content-type']:
        _inform(inspect.stack()[0][3] + ": Unexpected response content-type: " + response.headers['content-type'] +
                " from " + request_url)
        sys.exit(1)

    json_response = json.loads(response.text)
    _debug("json_response: " + str(json_response))

    json_result_set = json_response['ResultSet']
    _debug("json_result_set: " + str(json_result_set))

    json_record_count = int(json_result_set['totalRecords'])
    _debug("json_record_count: " + str(json_record_count))

    json_result = json_result_set['Result']
    _debug("json_result: " + str(json_result))

    session_and_session_id_list = []
    for i in range(0, json_record_count):
        item_list = []
        for key in ['label', 'ID']:
            item_list.append(str(json_result[i][key]))
        session_and_session_id_list.append(item_list)

    _debug("session_and_session_id_list: " + str(session_and_session_id_list))

    for session_and_session_id in session_and_session_id_list:
        if session == session_and_session_id[0]:
            return session_and_session_id[1]

    return 'XNAT SESSION ID NOT FOUND'


def get_jsession_id(server, username, password):

    request_url = 'https://' + server + '/data/JSESSION'
    response = requests.get(request_url, auth=(username, password))

    if (response.status_code != 200):
        _inform(inspect.stack()[0][3] + ": Cannot get response from request: " + request_url)
        _inform(inspect.stack()[0][3] + ": Check username and password")
        sys.exit(1)

    _debug("response.text: " + str(response.text))
    return str(response.text)


class Workflow():
    """Workflow Handler Class"""

    def __init__(self, user, password, server, jsession_id):
        self._user = user
        self._password = password
        self._server = server
        self._jsession_id = jsession_id
        self._timeout = 8
        self._timeout_max = 1024
        self._timeout_step = 8

    def create_workflow(self, experiment_id, project_id, pipeline, status):
        """Creates a workflow entry and returns the primary key of the inserted workflow"""
        workflow_str_xml = '<wrk:Workflow data_type="xnat:mrSessionData" xmlns:xsi="http://www.w3.org/2001/XMSchema-instance" '
        workflow_str_xml += 'xmlns:wrk="http://nrg.wuslt.edu/workflow" />'
        workflow_data_element = ET.fromstring(workflow_str_xml)

        ET.register_namespace('wrk', 'http://nrg.wustl.edu/workflow')

        workflow_data_element.set('ID', experiment_id)
        workflow_data_element.set('ExternalID', project_id)
        workflow_data_element.set('status', status)
        workflow_data_element.set('pipeline_name', pipeline)

        time_now = time.localtime()
        xml_time = time.strftime('%Y-%m-%dT%H:%M:%S', time_now)
        pretty_time_now = time.strftime('%Y-%m-%dT%H-%M-%S', time_now)

        workflow_data_element.set('launch_time', xml_time)

        workflow_data_str = ET.tostring(workflow_data_element)

        if sys.platform != 'win32':
            workflow_write_str = '/tmp/Workflow_%s_%s.xml' % (experiment_id, pretty_time_now)
            with open(workflow_write_str, 'wb') as output_file_obj:
                output_file_obj.write(workflow_data_str)

            workflow_submit_str = '$PIPELINE_HOME/xnat-tools/XnatDataClient -s %s -m PUT -r "%s/REST/workflows?req_format=xml&inbody=true" -l %s' % (self._jsession_id, self._server, workflow_write_str)  # nopep8
            subprocess.call(workflow_submit_str, shell=True, stdout=open("/dev/null", "w"))
            workflow_id = self.get_queued_workflow_id_as_parameter(pipeline, experiment_id)
            return workflow_id
        else:
            ET.dump(workflow_data_element)
            return -1

    def get_pipeline_name(self, pipeline):
        pipeline.strip()
        slash_index = pipeline.find('/')
        dot_XML_index = pipeline.find('.xml')

        if (slash_index == -1):
            return_string = pipeline
        else:
            return_string = pipeline[slash_index+1:]

        if (dot_XML_index == -1):
            return return_string
        else:
            return return_string[0:dot_XML_index]

    def get_queued_workflow_id_as_parameter(self, pipeline, experiment_id):
        """Get Workflow Data and Parse to extract the Queued Workflow DB primary key"""
        pipeline = self.get_pipeline_name(pipeline)
        rest_url = self._server + '/data/services/workflows/' + pipeline + '?display=LATEST&experiment=' + experiment_id
        workflow_id_str = ' '

        rest_data = self.get_URL_string_using_jsession(rest_url)

        match = re.search('hidden_fields\[wrk_workflowData_id="(\d+)"\]', rest_data)
        if match:
            start_index = match.start()
            end_index = match.end()
            workflow_primary_key_str = rest_data[start_index:end_index]

        match = re.match(r"hidden_fields\[wrk_workflowData_id=\"(\d+)\"\]", workflow_primary_key_str)
        if (match):
            workflow_id_str = match.group(1)
        return workflow_id_str

    def get_URL_string_using_jsession(self, URL):
        """Get URL results as a string"""
        restRequest = urllib.request.Request(URL)
        restRequest.add_header("Cookie", "JSESSIONID=" + self._jsession_id)

        while (self._timeout <= self._timeout_max):
            try:
                restConnHandle = urllib.request.urlopen(restRequest, None, self._timeout)
            except HTTPError as e:
                if (e.code == 400):
                    return '404 Error'
                elif (e.code == 500):
                    return '500 Error'
                elif (e.code != 404):
                    self._timeout += self._timeout_step
                    print('HTTPError code: ' + str(e.code) + '. Timeout increased to ' + str(self._timeout) + ' seconds for ' + URL)
                else:
                    print(str(e))
                    break

            except URLError as e:
                self._timeout += self._timeout_step
                print('URLError code: ' + str(e.reason) + '. Timeout increased to ' + str(self._timeout) + ' seconds for ' + URL)
            except SSLError as e:
                self._timeout += self._timeout_step
                print('SSLError code: ' + str(e.message) + '. Timeout increased to ' + str(self._timeout) + ' seconds for ' + URL)
            except socket.timeout:
                self._timeout += self._timeout_step
                print('Socket timed out. Timeout increased to ' + str(self._timeout) + ' seconds for ' + URL)

            else:
                try:
                    ReadResults = restConnHandle.read()
                    return str(ReadResults)

                except HTTPError as e:
                    print('READ HTTPError code: ' + str(e.code) + '. File read timeout for ' + str(self._timeout) + ' seconds for ' + URL)  # nopep8
                except URLError as e:
                    print('READ URLError code: ' + str(e.reason) + '. File read timeout for ' + str(self._timeout) + ' seconds for ' + URL)  # nopep8
                except SSLError as e:
                    print('READ SSLError code: ' + str(e.message) + '. File read timeout for ' + str(self._timeout) + ' seconds for ' + URL)  # nopep8
                except socket.timeout:
                    print('READ Socket timed out. File read timeout for ' + str(self._timeout) + ' seconds for ' + URL)

        print('ERROR: No reasonable timeout limit could be found for ' + URL)
        sys.exit()


def _simple_interactive_demo():
    _inform("Interactive Demo TBW")


if __name__ == '__main__':
    _simple_interactive_demo()
