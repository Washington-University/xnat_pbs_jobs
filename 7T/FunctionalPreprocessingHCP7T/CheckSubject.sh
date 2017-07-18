#!/bin/bash

subject="${1}"

rm *.txt*
echo ""
./CheckForFunctionalPreprocessingHCP7TCompletion.sh --project=HCP_1200 --subject=${subject}
echo ""
qstat -u HCPpipeline | grep ${subject}
