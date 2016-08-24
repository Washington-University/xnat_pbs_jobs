#./CheckFunctionalPreprocessing.sh --debug --project PipelineTest --subjects "355239"
#
#./CheckFunctionalPreprocessing.sh --debug --project PipelineTest --subjects "100307,101915"

#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "100307,101915,103414,105115,106016,110411,111312,113619,115320,117122" | grep FAIL
#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "118730,118932,120111,122317,123117,124422,125525,128632,129028,130013" | grep FAIL
#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "130316,133928,135932,136833,139637,140824,148335,149337,149539,151223" | grep FAIL
#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "151627,153025,159340,162733,163129,178950,188347,189450,199655,201414" | grep FAIL
#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "211720,217126,280739,355239,497865,545345,547046,749361,951457" | grep FAIL

#./CheckFunctionalPreprocessing.sh --resourcepath /HCP/hcpdb/archive/PipelineTest/arc001/100307_3T/RESOURCES
#echo "Did any tests fail: $?"

#./CheckFunctionalPreprocessing.sh --resourcepath /HCP/hcpdb/archive/PipelineTest/arc001/100307_3T/RESOURCES --tasks GAMBLING
#echo "Did any tests fail: $?"


#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "211720,101915"
#echo "Did any tests fail: $?"

#./CheckFunctionalPreprocessing.sh --project PipelineTest --subjects "129028" 
#echo "Did any tests fail: $?"

#./CheckFunctionalPreprocessing.sh --resourcepath /HCP/hcpdb/archive/PipelineTest/arc001/129028_3T/RESOURCES
#echo "Did any tests fail: $?"

./CheckFunctionalPreprocessing.sh --resultspath /HCP/hcpdb/archive/PipelineTest/arc001/129028_3T/RESOURCES/tfMRI_LANGUAGE_LR_preproc/MNINonLinear/Results/tfMRI_LANGUAGE_LR --tasks=LANGUAGE --dirs=LR
echo "Did any tests fail: $?"
