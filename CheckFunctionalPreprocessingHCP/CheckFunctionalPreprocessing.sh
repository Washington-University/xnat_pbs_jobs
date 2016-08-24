#!/bin/bash

#~ND~FORMAT~MARKDOWN
#~ND~START~
#
# # Check Functional Preprocessing
#
# ## Script Description
# 
# This script performs a series of tests on the output of the
# functional preprocessing pipeline.  The script checks files
# directly on the file system. (It does not use REST API calls
# to get the resources/files it wants to examine and test.)
#
# If no task is specified for testing, tests will be performed
# on all tasks and scan directions for the specified subject.
#
# By specifying a list of "tasks" (e.g. REST1, WM, GAMBLING, 
# etc.), the user can have tests performed on only those 
# specified tasks, both scan directions, LR and RL. 
#
# By specifying a list of "tasks" _and_ a list of scan directions
# (LR, RL), the user can have tests performed on just the 
# specified tasks and scan directions.
#
# ## Tests Performed
# 
# Search the script comments for "# Test:" to see tests performed
# 
# E.g. $ grep "# Test:" checkFunctionalPreprocessing.sh
#
# ## Script Assumptions
#
#  * For a specified subject to be tested, ${subjId}, only one 
#    session will need to be checked and that session will be 
#    named ${subjId}_3T.
#
#  * The archive directory for the XNAT installation in which 
#    results will be checked is /HCP/hcpdb/archive
#
#  * Session files will be found in a directory named arc001 
#    in the archive project directory
#
# ## Author(s)
#
#  * Timothy B. Brown (tbbrown at wustl dot edu)
#
#~ND~END~

#
# Description:
#  Global variables to define scan types and directions
#
declare -a restingScanTypes=(REST1 REST2 REST3 REST4 REST5 REST6)
declare -a taskScanTypes=(WM GAMBLING MOTOR LANGUAGE RELATIONAL SOCIAL EMOTION)
declare -a allScanTypes=( ${restingScanTypes[@]} ${taskScanTypes[@]} )
declare -a directions=(RL LR)

#
# Description:
#  Global variable for keeping track of test whether there 
#  where any test failures
#
unset didAnyTestsFail

#
# Function Description:
#  Echo output to stderr if in debugging mode
#  (i.e. if the debug variable is set to True)
#
debugEcho() {
    if [ "${debug}" = "True" ]; then
        echo "Debug: $@" 1>&2 
    fi
}

#
# Function Description:
#  Determine whether the specified string element is in
#  the specified array
#
# Input Parameters:
#  All parameters but the last - The set of values to check to see if 
#                                another value is a member 
#  Last parameter - The value to check to see if it is a member of 
#                   the previously listed parameters
#
# Return:
#  "True" if last parameter is in the earlier parameters, 
#  "False" otherwise
#
# Example Calls:
#  if [ $(contains "${restingScanTypes[@]}" ${task}) == "True" ]; then
#      echo "${task} is in the restingScanTypes array"
#  fi
#
#  if [ $(contains "hello" "there" "you" "hello") == "True" ]; then
#      echo "hello is there"
#  else
#      echo "hello is not there"
#  fi
#
contains() {
    local n=$#
    local value=${!n}
    local i
    for ((i=1;i < $#;i++)) {
        if [ "${!i}" == "${value}" ]; then
            echo "True"
            return 0
        fi
    }
    echo "False"
    return 1
}

# 
# Function Description:
#  Show usage information for this script
#
usage() {
    local scriptName=$(basename ${0})
    echo ""
    echo "  Perform a series of tests on output of functional pre-processing"
    echo ""
    echo "  Usage: ${scriptName} <options>"
    echo ""
    echo "  Options: [ ] = optional; < > = user supplied value"
    echo ""
    echo "    [--help]  : show usage information and exit"
    echo ""
    echo "    [--debug] : show debugging information on stderr"
    echo ""
    echo "    [--project <project-name> | --project=<project-name>]"
    echo "    : name of project to check" 
    echo ""
    echo "    [--subjects <subject-ids> | --subjects=<subject-ids>]"
    echo "    : list of IDs of subjects to check (comma separated, NO WHITESPACE)"
    echo ""
    echo "    [--resourcepath <resource-path> | --resourcepath=<resource-path>]"
    echo "    : path to where functionally preprocessed directories that will be checked reside"
    echo "      e.g. /HCP/hcpdb/archive/PipelineTest/arc001/100307_3T/RESOURCES"
    echo ""
    echo "    [--resultspath <results-path> | --resultspath=<results-path>]"
    echo "    : path to exact results directory - the root of all results for a particular task and scan"
    echo "      direction"
    echo ""
    echo "    Notes: If neither <resource-path> or <results-path> are specified, then <project-name> and"
    echo "           <subject-ids> are required and are used to create a <resource-path> value as follows:"
    echo ""
    echo "           /HCP/hcpdb/archive/<project-name>/arc001/<subject-id>_3T/RESOURCES"
    echo ""
    echo "           In that <resource-path>, task and direction directories are expected to exist that"
    echo "           are named based on <task-ids> and <dir-ids> (see below). So, for example, if one"
    echo "           of the listed <task-ids> is LANGUAGE and both RL and LR are listed as the <dir-ids>,"
    echo "           then two directories with the following names: tfMRI_LANGUAGE_RL_preproc and "
    echo "           tfMRI_LANGUAGE_LR_preproc will be expected to be found in the <resource-path>."
    echo ""
    echo "           In each of those directories a results directory is expected named: "
    echo "           MNINonLinear/Results/tfMRI_LANGUAGE_RL or MNINonLinear/Results/tfMRI_LANGUAGE_LR"
    echo "           respectively. It is in these results directories that tests are actually performed."
    echo ""
    echo "           If a <resource-path> is specified, then the process of building a <resource-path>"
    echo "           described above is bypassed, and any specified values for <project-name> and "
    echo "           <subject-ids> are ignored."
    echo ""
    echo "           If a <results-path> is specified, then the process of building results directories"
    echo "           described above is bypassed, and any specified values for <project-name> and "
    echo "           <subject-ids> are ignored."
    echo ""
    echo "    [--tasks <task-ids> | --tasks=<task-ids>]"
    echo "    : Identification of task to test (comma separated, NO WHITESPACE)"
    echo "      If unspecified, all tasks are tested."
    echo ""
    echo "    Recognized task ids: "
    local aTaskId
    for aTaskId in "${allScanTypes[@]}"; do
        echo "                         ${aTaskId}"
    done
    echo ""
    echo "    [--dirs <direction-ids> | --dirs=<direction-ids>]"
    echo "    : Identification of scan directions to test for each task tested"
    echo "      (comma separated, NO WHITESPACE)"
    echo "      If unspecified, all directions are tested"
    echo ""
    echo "    Recognized scan directions: "
    local aScanDir
    for aScanDir in "${directions[@]}"; do
        echo "                         ${aScanDir}"
    done
    echo ""
    echo "  Output: (stdout)"
    echo ""
    echo "    For each functional scan and direction tested, one line per test performed"
    echo "    is sent to stdout describing the test and containing PASSED if the test"
    echo "    succeeded and FAILED if the test failed."
    echo ""
    echo "    Thus, greping the stdout from this script for FAILED should provide only"
    echo "    lines relevant to failed tests."
    echo ""
    echo "  Return Code:"
    echo ""
    echo "    0 if help was not requested, all parameters were properly formed, and all"
    echo "      tests performed passed"
    echo "    1 otherwise - malformed parameters, help requested, or at least one test"
    echo "      failed"
    echo ""
}

#
# Function Description:
#  Get the command line options for this script.
#  Shows usage information an exits if command line 
#  is malformed.
#
# Global Output Variables:
#  ${debug}        - Set to "True" if user has requested debugging information
#  ${projectName}  - User specified project name
#  ${subjectIds}   - User specified list of subject ids (Comma Separated)
#  ${resourcePath} - path to the location of preprocessed directories
#  ${resultsPath}  - path to the location of a results directory
#  ${taskIds}      - User specified (or default) list of task ids 
#  ${dirIds}       - User specified (or default) list of scan direction ids
#
get_options() {
    local arguments=($@)

    # initialize global output variables
    unset debug
    unset projectName
    unset subjectIds
    unset resourcePath
    unset resultsPath

    unset taskIds
    for aTaskId in "${allScanTypes[@]}"; do
        if [ "${taskIds}" == "" ]; then
            taskIds="${aTaskId}"
        else
            taskIds="${taskIds},${aTaskId}"
        fi
    done

    unset dirIds
    for aDirId in "${directions[@]}"; do
        if [ "${dirIds}" == "" ]; then
            dirIds="${aDirId}"
        else
            dirIds="${dirIds},${aDirId}"
        fi
    done

    # parse arguments
    local index=0
    local numArgs=${#arguments[@]}
    local argument

    while [ ${index} -lt ${numArgs} ]; do
        argument=${arguments[index]}

        case ${argument} in
            --help)
                usage
                exit 1
                ;;
            --debug)
                debug="True"
                index=$(( index + 1 ))
                ;;
            --project)
                projectName=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --project=*)
                projectName=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --subjects)
                subjectIds=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --subjects=*)
                subjectIds=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --resourcepath)
                resourcePath=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --resourcepath=*)
                resourcePath=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --resultspath)
                resultsPath=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --resultspath=*)
                resultsPath=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --tasks)
                taskIds=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --tasks=*)
                taskIds=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            --dirs)
                dirIds=${arguments[$(( index + 1 ))]}
                index=$(( index + 2 ))
                ;;
            --dirs=*)
                dirIds=${argument/*=/""}
                index=$(( index + 1 ))
                ;;
            *)
                echo "Unrecognized Option: ${argument}"
                usage
                exit 1
                ;;
        esac
    done

    # check required parameters
    if [ -z ${resourcePath} ] && [ -z ${resultsPath} ]; then
        if [ -z ${projectName} ] || [ -z ${subjectIds} ]; then
            usage
            echo ""
            echo "ERROR: If neither <resource-path> nor <results-path> are specified,"
            echo "ERROR: then <project-name> and <subject-ids> are required."
            echo ""
            exit 1
        fi
    fi

    # check task ids
    oldIFS=${IFS}
    IFS=","
    local aTaskId
    for aTaskId in ${taskIds}; do
        if [ $(contains "${allScanTypes[@]}" ${aTaskId}) != "True" ]; then
            usage
            echo ""
            echo "ERROR: Unrecognized task id: ${aTaskId}"
            echo ""
            exit 1
        fi
    done
    IFS=${oldIFS}

    # check scan directions
    oldIF=${IFS}
    IFS=","
    local aDirId
    for aDirId in ${dirIds}; do 
        if [ $(contains "${directions[@]}" ${aDirId}) != "True" ]; then
            usage
            echo ""
            echo "ERROR: Unrecognized direction id: ${aDirId}"
            echo ""
            exit 1
        fi
    done
    IFS=${oldIFS}

    # report options
    debugEcho "${FUNCNAME}: projectName: ${projectName}"
    debugEcho "${FUNCNAME}: subjectIds: ${subjectIds}"
    debugEcho "${FUNCNAME}: resourcePath: ${resourcePath}"
    debugEcho "${FUNCNAME}: resultsPath: ${resultsPath}"
    debugEcho "${FUNCNAME}: taskIds: ${taskIds}"
    debugEcho "${FUNCNAME}: dirIds: ${dirIds}"
}

#
# Function Description:
#  Setup environment for running FSL commands
#
setupfsl() {
    . ${FSLDIR}/etc/fslconf/fsl.sh
}

#
# Function Description:
#  Get the number of frames in a preprocessed image file
#
# Input Parameters:
#  ${1} - Preprocessing results directory in which to look
#  ${2} - Base name of scan type
#
# Output Parameters:
#  ${3} - Return variable in which to place the retrieved
#         number of frames
#
# Prerequisites:
#  - FSL must be properly setup by calling the setupfsl function
#
# Example Call:
#  getNumberOfPreProcessedFrames ${resultsDir} ${scanBaseName} frameCount
#
getNumberOfPreProcessedFrames() {
    local dir=${1}
    local filebasename=${2}
    local __functionResultVar=${3}
    
    local imageFile="${dir}/${filebasename}.nii.gz"
    debugEcho "${FUNCNAME}: Checking number of frames in file: ${imageFile}"
    local numFrames=`fslnvols ${imageFile}`
    debugEcho "${FUNCNAME}: Number of Frames in image: ${numFrames}"
    
    # Return the retrieved number of frames
    eval $__functionResultVar="'${numFrames}'"
}

# 
# Function Description:
#  Get the number of FSF points
#
# Input Parameters:
#  ${1} - Preprocessing results directory in which to look
#
# Output Parameters:
#  ${2} - Return variable in which to place the retrieved
#         number of FSF points
#
# Example Call:
#  getNumberOfFsfPoints ${resultsDir} fsfPointCount
#
getNumberOfFsfPoints() {
    local dir=${1}
    local __functionResultVar=${2}

    local fsfFiles="${dir}/*.fsf"
    local npts="0"

    if [ -e ${fsfFiles} ]; then
        local npts=`grep npts ${fsfFiles} | cut -d ' ' -f3`
    fi

    # Return the retrieved number of FSF points
    eval $__functionResultVar="'${npts}'"
}

#
# Function Description:
#  Derive/Create the base file name for the preprocessed image
#
# Input Parameters:
#  ${1} - subject state: e.g. [RESTING | TASK]
#  ${2} - task: e.g. [REST1, REST2, WM, GAMBLING, MOTOR, ...]
#  ${3} - scan direction: e.g. [RL | LR]
#
# Return:
#  Return (as string) the base file name of the preprocessed
#         image
#
# Example Call:
#  scanBaseName=$(derivePreprocessedScanBaseName "RESTING" ${task} ${dir})
#
derivePreprocessedScanBaseName() {
    local subjectState=${1}
    local task=${2}
    local scanDir=${3}

    local scanBaseName=""
    local typeLetter=""

    if [ "${subjectState}" = "RESTING" ]; then
        typeLetter="r"
    elif [ "${subjectState}" = "TASK" ]; then
        typeLetter="t"
    else
        echo "${@} - Unrecognized subjectState: '${subjectState}'"
        exit 1
    fi

    scanBaseName="${typeLetter}fMRI_${task}_${scanDir}"
    echo ${scanBaseName}
}

#
# Function Description:
#  Derive/Create the name of the direcgtory in which unprocessed
#  data for the scan will be found
#
# Input Parameters:
#  ${1} - session archive directory
#  ${2} - scan base name
#
# Return:
#  Return (as a string) the directory in which unprocessed data
#         should be found
#
# Example Call:
#  unprocDir=$(deriveUnprocessedDirectoryName ${sessionDirectory} ${scanBaseName})
#
deriveUnprocessedDirectoryName() {
    local sessionArchiveDir=${1}
    local scanBaseName=${2}

    local unprocDirName=""
    local unprocDir=""

    unprocDirName="${scanBaseName}_unproc"
    unprocDir="${sessionArchiveDir}/RESOURCES/${unprocDirName}"

    echo ${unprocDir}
}

#
# Function Description:
#  Derive/Create the name of the directory in which preprocessing
#  results will be found
#
# Input Parameters:
#  ${1} - session archive directory
#  ${2} - scan base name 
#
# Return:
#  Return (as a string) the directory in which preprocessed 
#         results should be found
#
# Example Call:
#  resultsDir=$(deriveResultsDirectoryName ${sessionDirectory} ${scanBaseName})
#
deriveResultsDirectoryName() {
    local sessionArchiveDir=${1}
    local scanBaseName=${2}

    local preprocDirName=""
    local resultsDir=""

    preprocDirName="${scanBaseName}_preproc"

    resultsDir="${sessionArchiveDir}/RESOURCES/${preprocDirName}/MNINonLinear/Results/${scanBaseName}"
    echo ${resultsDir}
}

#
# Function Description:
#  List the EV files referenced in the FSF files in the 
#  specified results directory
#
# Input Parameters:
#  ${1} - directory in which preprocessed results 
#         should be found
#
# Return:
#  Space separated list of paths to referenced EV files
#  (path relative to preprocessed results directory)
#
# Example Call:
#  fsfTxtFiles=$(listTxtFilesReferencedInFsfFiles ${resultsDir}) 
#
listTxtFilesReferencedInFsfFiles() {
    local resultsDir=${1}

    local evFiles=""
    if [ -e ${resultsDir}/*.fsf ]; then
        local evFiles=`grep txt ${resultsDir}/*.fsf | sed -e 's|\"||g' | cut -d'/' -f2-3`
    fi
        
    echo ${evFiles}
}

#
# Function Description:
#  Get the number of lines in the specified file
#
# Input Parameters:
#  ${1} - path to file
#
# Return:
#  Number of unique lines in the file
#
# Example Call:
#  lineCount=$(getFileLineCount ${file})
#
getFileLineCount() {
    local file=${1}

    # Note: We use the technique of cat'ing the file out and piping
    # the result to wc -l so that the name of the file is not
    # included in the output of the wc command.
    numLines=`cat ${file} | wc -l`
    echo ${numLines}
}

#
# Function Description:
#  Get the maximum number of columns in the specified file
#
# Input Parameters:
#  ${1} - path to file
#
# Return:
#  Maximum number of columns in the lines (rows) in the file
#
# Example Call:
#  maxNumColumns=$(getFileMaxColumnCount ${file})
#
getFileMaxColumnCount() {
    local file=${1}
    
    # The awk system variable NF contains the number of fields
    # for each input record (line). So the awk portion of the
    # below generates a field count for each line in the file.
    # Then the sort -nr sorts the resulting values numerically
    # (-n) and in reverse order (-r) to put the maximum NF value
    # first in the sorted output. Finally, we take the first
    # such value (the maximum) using the head -1 command.
    maxColumns=`awk '{print NF}' ${file} | sort -nr | head -1`
    echo ${maxColumns}
}

#
# Function Description:
#  Get the minimum number of columns in the specified file
#
# Input Parameters:
#  ${1} - path to file
#
# Return:
#  Minimum number of columns in the lines (rows) in the file
#
# Example Call:
#  minNumColumns=$(getFileMinColumnCount ${file})
#
getFileMinColumnCount() {
    local file=${1}
    
    # The awk system variable NF contains the number of fields
    # for each input record (line). So the awk portion of the
    # below generates a field count for each line in the file.
    # Then the sort -n sorts the resulting values numerically
    # (-n) to put the minimum NF value first in the sorted output.
    # Finally, we take the first such value (the minimum) using 
    # the head -1 command.
    minColumns=`awk '{print NF}' ${file} | sort -n | head -1`
    echo ${minColumns}
}

#
# Function Description:
#  Get number of columns in the specified file
#
# Input Parameters:
#  ${1} - path to file
#
# Return:
#  Number of columns in the lines (rows) in the file.
#  Only returns this column count value if the file has
#  the same number of columns in each row.  Returns -1
#  if the maximum number of columns in any row in the file
#  doesn't match the minimum number of columns in any
#  row in the file.
#
# Example Call:
#  numColumns=$(getFileColumnCount ${file})
#
getFileColumnCount() {
    local file=${1}

    maxNumColumns=$(getFileMaxColumnCount ${file})
    minNumColumns=$(getFileMinColumnCount ${file})

    if [ $((maxNumColumns)) -ne $((minNumColumns)) ]; then
        echo -1
    else
        echo ${maxNumColumns}
    fi
}

#
# Function Description:
#  Create the session id from the subject id
# 
# Input Parameters:
#  ${1} - subject id
#
# Return:
#  Return (as a string) the session id
#
# Example Call:
#  sessionId=$(deriveSessionId ${subjId})
#
deriveSessionId() {
    local subjId=${1}

    local sessionId=""

    sessionId="${subjId}_3T"
    echo ${sessionId}
}

# 
# Function Description:
#  Create the session directory path from the project name
#  and the session id
#
# Input Parameters:
#  ${1} - project name
#  ${2} - session id
#
# Return:
#  Return (as a string) the session directory path
# 
# Example Call:
#  sessionDirectory=$(deriveSessionDirectory ${prjName} ${sessionId})
#
deriveSessionDirectory() {
    local prjName=${1}
    local sessionId=${2}

    local sessionDirectory=""

    sessionDirectory="/HCP/hcpdb/archive/${prjName}/arc001/${sessionId}"
    echo ${sessionDirectory}
}

#
# Function Description:
#  Test whether Results Directory exists
#
# Input Parameters:
#  ${1} - scan description
#  ${2} - results directory
#
# Output:
#  Sends test description and PASS/FAIL indication to stdout
# 
# Example Call:
#  testResultsDirectoryExists "${scanDesc}" "${resultsDir}"
#
testResultsDirectoryExists() {
    local scanDesc=${1}
    local resultsDir=${2}

    local testDesc="Results directory exists"


    echo "${FUNCNAME}: resultsDir = ${resultsDir}"

    if [ -e ${resultsDir} ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    else
        echo "${scanDesc}, Test: ${testDesc}: FAILED"
        didAnyTestsFail="True"
    fi
}

#
# Function Description:
#  Test whether FSF point count is as expected
#
# Input Parameters:
#  ${1} - scan description
#  ${2} - results directory
#  ${3} - expected FSF point count
#
# Output:
#  Sends test description and PASS/FAIL indication to stdout
#
# Example Call:
#  testFsfPointCount "${scanDesc}" "${resultsDir}" 0
#
testFsfPointCount() {
    local scanDesc=${1}
    local resultsDir=${2}
    local expectedFsfPointCount=${3}

    local testDesc="FSF point count is ${expectedFsfPointCount}"
    
    local fsfPointCount
    getNumberOfFsfPoints ${resultsDir} fsfPointCount
    debugEcho "${FUNCNAME}: fsfPointCount: ${fsfPointCount}"

    if [ $((fsfPointCount)) -eq $((expectedFsfPointCount)) ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    else
        echo "${scanDesc}, Test: ${testDesc}: FAILED"
        didAnyTestsFail="True"
    fi
}

#
# Function Description:
#  Verify that no EV Text files are referenced
#
# Input Parameters:
#  ${1} - scan description
#  ${2} - results directory
#
# Output:
#  Sends test description and PASS/FAIL indication to stdout
#
# Example Call:
#  testFsfPointCount "${scanDesc}" "${resultsDir}" 0
#
testNoEvTextFilesReferenced() {
    local scanDesc=${1}
    local resultsDir=${2}

    local testDesc="No EV Text files referenced"
    local fsfTxtFiles=$(listTxtFilesReferencedInFsfFiles ${resultsDir})
    debugEcho "${FUNCNAME}: fsfTxtFiles: ${fsfTxtFiles}"

    if [ "${fsfTxtFiles}" = "" ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    else
        echo "${scanDesc}, Test: ${testDesc}: FAILED"
        didAnyTestsFail="True"
    fi
}

#
# Function Description:
#  Verify that EV Text files are referenced by FSF files
#
# Input Parameters:
#  ${1} - scan description
#  ${2} - results directory
#
# Output:
#  Sends test description and PASS/FAIL indication to stdout
#
# Example Call:
#  testFsfPointCount "${scanDesc}" "${resultsDir}" 0
#
testEvTextFilesAreReferencedByFsfFiles() {
    local scanDesc=${1}
    local resultsDir=${2}

    local testDesc="EV Text Files are referenced by FSF Files"
    local fsfReferencedTxtFiles=$(listTxtFilesReferencedInFsfFiles ${resultsDir})
    debugEcho "${FUNCNAME}: fsfReferencedTxtFiles: ${fsfReferencedTxtFiles}"

    if [ "${fsfReferencedTxtFiles}" = "" ]; then
        echo "${scanDesc}, Test: ${testDesc}: FAILED"
        didAnyTestsFail="True"
    else
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    fi
}

#
# Function Description:
#  Run tests on a specified results directory
#
# Input Parameters:
#  ${1} - results directory
#  ${2}

testResults() {
    local resultsDir=${1}
    local task=${2}
    local dir=${3}

    # Determine base name of scan for this task and direction
    if [ $(contains "${restingScanTypes[@]}" ${task}) == "True" ]; then
        # This is a resting state scan
        scanBaseName=$(derivePreprocessedScanBaseName "RESTING" ${task} ${dir})
    else
        # This is a task scan
        scanBaseName=$(derivePreprocessedScanBaseName "TASK" ${task} ${dir})
    fi
    debugEcho "${FUNCNAME}: scanBaseName: ${scanBaseName}"

    # Determine number of frames in scan image
    getNumberOfPreProcessedFrames ${resultsDir} ${scanBaseName} frameCount
    debugEcho "${FUNCNAME}: frameCount: ${frameCount}"

    # Establish scan description for test outputs
    scanDesc="Path: ${resultsDir}, Scan: ${scanBaseName}"

    # Test: Results directory exists
    testResultsDirectoryExists "${scanDesc}" "${resultsDir}"
    
    if [ $(contains "${restingScanTypes[@]}" ${task}) == "True" ]; then
        # This is a resting state scan, perform resting state specific tests

        # Test: FSF point count is 0
        testFsfPointCount "${scanDesc}" "${resultsDir}" 0

        # Test: No EV Text files referenced
        testNoEvTextFilesReferenced "${scanDesc}" "${resultsDir}"
        
    else
        # This is a task scan, perform task scan specific tests

        # Test: FSF point count equals image frame count
        testFsfPointCount "${scanDesc}" "${resultsDir}" $((frameCount))

        # Test: EV Text Files are referenced by FSF Files
        testEvTextFilesAreReferencedByFsfFiles "${scanDesc}" "${resultsDir}"

        # Test referenced txt files
        # Cycle through referenced txt files
        local fsfReferencedTxtFiles=$(listTxtFilesReferencedInFsfFiles ${resultsDir})
        debugEcho "${FUNCNAME}: fsfReferencedTxtFiles: ${fsfReferencedTxtFiles}"

        for referenceToEvFile in ${fsfReferencedTxtFiles}; do
            debugEcho "${FUNCNAME}: referenceToEvFile: ${referenceToEvFile}"

            #
            # Test: Referenced EV Text file exists
            #
            testDesc="Referenced EV Text file exists"

            evFile=${resultsDir}/${referenceToEvFile}

            if [ -e ${evFile} ]; then
                echo "${scanDesc}, Test: ${testDesc}: PASSED [${referenceToEvFile}]"
                evLineCount=$(getFileLineCount ${evFile})
                evColumnCount=$(getFileColumnCount ${evFile})
            else
                echo "${scanDesc}, Test: ${testDesc}: FAILED [${referenceToEvFile}]"
                didAnyTestsFail="True"
                evLineCount=0;
                evColumnCount=0;
            fi

            debugEcho "${FUNCNAME}: evLineCount: ${evLineCount}"
            debugEcho "${FUNCNAME}: evColumnCount: ${evColumnCount}"

            # 
            # Test: EV Text file has non-zero number of lines
            #
            testDesc="EV Text file has non-zero number of lines"

            if [ ${evLineCount} -eq 0 ]; then
                echo "${scanDesc}, Test: ${testDesc}: FAILED [EV lines in file ${referenceToEvFile} = ${evLineCount}]"
                didAnyTestsFail="True"
            else
                echo "${scanDesc}, Test: ${testDesc}: PASSED [EV lines in file ${referenceToEvFile} = ${evLineCount}]"
            fi

            #
            # Test: EV Text file has 3 columns
            #
            testDesc="EV Text file has 3 columns"

            if [ ${evColumnCount} -eq 3 ]; then
                echo "${scanDesc}, Test: ${testDesc}: PASSED"
            else
                echo "${scanDesc}, Test: ${testDesc}: FAILED"
                didAnyTestsFail="True"
            fi
        done # for referenceToEvFile in ${fsfReferencedTxtFiles}
    fi

    #
    # Test: Movement Regressor file exists
    #
    testDesc="Movement Regressor file exists"

    mvmtRegressorFile=${resultsDir}/Movement_Regressors.txt
            
    if [ -e ${mvmtRegressorFile} ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    else 
        echo "${scanDesc}, Test: ${testDesc}: FAILED"
        didAnyTestsFail="True"
    fi

    #
    # Test: Movement Regressor line count equals image frame count
    #
    testDesc="Movement Regressor line count equals image frame count"

    regLineCount=$(getFileLineCount ${mvmtRegressorFile})
    debugEcho "${FUNCNAME}: regLineCount: ${regLineCount}"
    
    if [ $((regLineCount)) -eq $((frameCount)) ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED [regLineCount (${regLineCount}) == frameCount (${frameCount})]"
    else
        echo "${scanDesc}, Test: ${testDesc}: FAILED [regLineCount (${regLineCount}) != frameCount (${frameCount})]"
        didAnyTestsFail="True"
    fi

    #
    # Test: Movement Regressor file has 12 columns
    #
    testDesc="Movement Regressor file has 12 columns"

    regColumnCount=$(getFileColumnCount ${mvmtRegressorFile})
    debugEcho "${FUNCNAME}: regColumnCount: ${regColumnCount}"
    
    if [ $((regColumnCount)) -ne 12 ]; then
        echo "${scanDesc}, Test: ${testDesc}: FAILED [regColumnCount = ${regColumnCount}]"
        didAnyTestsFail="True"
    else
        echo "${scanDesc}, Test: ${testDesc}: PASSED"
    fi

    #
    # Test: Movement Regressor file has 12 x frameCount words in it
    #
    testDesc="Movement Regressor file has (12 x number of frames) words"

    expectedWordCount=$(( 12 * $((frameCount)) ))
    debugEcho "${FUNCNAME}: expectedWordCount: ${expectedWordCount}"

    actualWordCount=`cat ${mvmtRegressorFile} | wc -w`
    debugEcho "${FUNCNAME}: actualWordCount: ${actualWordCount}"

    if [ $((expectedWordCount)) -eq $((actualWordCount)) ]; then
        echo "${scanDesc}, Test: ${testDesc}: PASSED [expectedWordCoung (${expectedWordCount}) == actualWordCount (${actualWordCount})]"
    else
        echo "${scanDesc}, Test: ${testDesc}: FAILED [expectedWordCoung (${expectedWordCount}) != actualWordCount (${actualWordCount})]"
        didAnyTestsFail="True"
    fi
}

#
# Function Description:
#  Run tests on specified scan in a resource directory
#
# Input Parameters:
#  ${1} - resource path or "" if resource path is to be derived
#  ${2} - project name
#  ${3} - subject id
#  ${4} - task
#  ${5} - direction
#
# Output:
#  See Output: (stdout) section of usage() funciton
#
# Example Call:
#  testResourceScan ${projectName} ${subjectId} ${task} ${dir}
#
testResourceScan() {
    local path=${1}
    local prjName=${2}
    local subjId=${3}
    local task=${4}
    local dir=${5}

    # Create variables indicating where to find session results
    sessionId=$(deriveSessionId ${subjId})
    sessionDirectory=$(deriveSessionDirectory ${prjName} ${sessionId})

    # Determine base name of scan for this task and direction
    if [ $(contains "${restingScanTypes[@]}" ${task}) == "True" ]; then
        # This is a resting state scan
        scanBaseName=$(derivePreprocessedScanBaseName "RESTING" ${task} ${dir})
    else
        # This is a task scan
        scanBaseName=$(derivePreprocessedScanBaseName "TASK" ${task} ${dir})
    fi
    debugEcho "${FUNCNAME}: scanBaseName: ${scanBaseName}"

    # Determine path to unprocessed directory
    if [ "${path}" = "" ]; then
        unprocDir=$(deriveUnprocessedDirectoryName ${sessionDirectory} ${scanBaseName})
    else
        unprocDir="${path}/${scanBaseName}_unproc"
    fi
    debugEcho "${FUNCNAME}: unprocDir: ${unprocDir}"

    # Determine if the unprocessed directory exists. 
    # If it doesn't exist, then there will be no further testing that 
    # can be done for this scan type and direction for this subject.
    if [ ! -e ${unprocDir} ]; then
        debugEcho "${FUNCNAME}: unprocDir: ${unprocDir} does not exist - no further tests performed for ${scanBaseName}"
        return
    fi

    # Determine path to results directory
    if [ "${path}" = "" ]; then
        resultsDir=$(deriveResultsDirectoryName ${sessionDirectory} ${scanBaseName})
    else
        resultsDir="${path}/${scanBaseName}_preproc/MNINonLinear/Results/${scanBaseName}"
    fi
    debugEcho "${FUNCNAME}: resultsDir: ${resultsDir}"

    # Perform tests in results directory
    testResults ${resultsDir} ${task} ${dir}
}

#
# Function Description:
#  Main processing of script.
#
#  Gets user specified command line options, sets up necessary environment,
#  and runs tests on specified subjects.
#
main() {
    # Get Command Line Options
    #
    # Global Variables Set:
    #  ${debug}        - Set to "True" if user has requested debugging information
    #  ${projectName}  - User specified project name
    #  ${subjectIds}   - User specified list of subject ids (Comma Separated)
    #  ${resourcePath} - path to the location of preprocessed directories
    #  ${resultsPath}  - path to the location of a results directory
    #  ${taskIds}      - User specified (or default) list of task ids 
    #  ${dirIds}       - User specified (or default) list of scan direction ids
    get_options $@

    # Setup FSL Environment
    setupfsl

    # Build lists of subject ids, task ids, and direction ids
    #
    #  Since subjectIds, taskIds, and dirIds are comma separated
    #  lists, we  change the internal field separator (IFS) to a 
    #  comma so that we can use a simple for-loop to cycle through
    #  these lists.
    #
    #  But we don't want to actually have the IFS set to something
    #  other than the default when testing individual scans because
    #  some of the code for testing an individual scan depends upon
    #  cycling through normal (space separated) lists
    #
    #  So we have the IFS set to a comma just long enough to build 
    #  the space delimited lists we need, then reset the IFS.
    oldIFS=${IFS}
    IFS=","

    local subjectIdsToTest=""
    local aSubjectId
    for aSubjectId in ${subjectIds}; do
        if [ "${subjectIdsToTest}" == "" ]; then
            subjectIdsToTest="${aSubjectId}"
        else
            subjectIdsToTest="${subjectIdsToTest} ${aSubjectId}"
        fi
    done

    local taskIdsToTest=""
    local aTaskId
    for aTaskId in ${taskIds}; do
        if [ "${taskIdsToTest}" == "" ]; then
            taskIdsToTest="${aTaskId}"
        else
            taskIdsToTest="${taskIdsToTest} ${aTaskId}"
        fi
    done

    local dirIdsToTest=""
    local aDirId
    for aDirId in ${dirIds}; do
        if [ "${dirIdsToTest}" == "" ]; then
            dirIdsToTest="${aDirId}"
        else
            dirIdsToTest="${dirIdsToTest} ${aDirId}"
        fi
    done

    # Reset the Internal Field Separator
    IFS=${oldIFS}

    debugEcho "${FUNCNAME}: resourcePath: ${resourcePath}"
    debugEcho "${FUNCNAME}: resultsPath: ${resultsPath}"
    debugEcho "${FUNCNAME}: subjectIdsToTest: ${subjectIdsToTest}"
    debugEcho "${FUNCNAME}: taskIdsToTest: ${taskIdsToTest}"
    debugEcho "${FUNCNAME}: dirIdsToTest"

    # Cycle through the list of subject ids to test
    if [ "${resourcePath}" = "" ] && [ "${resultsPath}" = "" ]; then
        for testSubjectId in ${subjectIdsToTest}; do
            # Cycle through the list of task ids to test
            for testTaskId in ${taskIdsToTest}; do
                # Cycle through the list of scan direction ids to test
                for testScanDirId in ${dirIdsToTest}; do
                    testResourceScan "${resourcePathPath}" "${projectName}" "${testSubjectId}" "${testTaskId}" "${testScanDirId}"
                done
            done
        done
    elif [ ! "${resourcePath}" = "" ]; then
        # Cycle through list of task ids to test
        for testTaskId in ${taskIdsToTest}; do
            # Cycle through the list of scan direction ids to test
            for testScanDirId in ${dirIdsToTest}; do
                testResourceScan "${resourcePath}" "${projectName}" "${testSubjectId}" "${testTaskId}" "${testScanDirId}"
            done
        done
    else # [ ! "${resultsPath}" = "" ]
        for testTaskId in ${taskIdsToTest}; do
            # Cycle through the list of scan direction ids to test
            for testScanDirId in ${dirIdsToTest}; do
                testResults "${resultsPath}" "${testTaskId}" "${testScanDirId}"
            done
        done
    fi
}

#
# Invoke the main function to get things started
#
main $@

if [ "${didAnyTestsFail}" = "True" ]; then
    exit 1
else
    exit 0
fi
