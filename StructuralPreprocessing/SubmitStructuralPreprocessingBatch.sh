#!/bin/bash

my_path=$(dirname "${0}")
source activate python3 2>/dev/null
${my_path}/SubmitStructuralPreprocessingBatch.py $@
source deactivate 2>/dev/null
