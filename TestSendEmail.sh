#!/bin/bash

g_notify_email=tbbrown@wustl.edu
g_subject=100307

if [ -n "${g_notify_email}" ]; then
	echo "should be sending the mail now"
	mail -s "RestingStateStats PUT Completion for ${g_subject}" ${g_notify_email} <<EOF
This is a test email 
Subject: ${g_subject}
EOF

fi

