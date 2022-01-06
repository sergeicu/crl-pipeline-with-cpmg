#!/bin/sh

#-------------------------------------------
# Init the ScriptDir variable
#-------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1

#-------------------------------------------
# Check that the pipeline can run on this machine
#-------------------------------------------
source "$ScriptDir/common/PipelineUtils.txt" || exit 1

setupThirdPartyTools
checkIfPipelineCanRun
if [ $? -ne 0 ]; then
  exit 1
fi


#-------------------------------------------
# Init the pipeline - get various variables including BaseProcessedDir
#-------------------------------------------
source $ScriptDir/common/PipelineInit.txt || exit 1

echo "---"
echo $T1_REF_DEPS_1_TIMESTAMP
pwd

#-------------------------------------------
# Backup the cache before anything else
#-------------------------------------------
mkdir -p "${BaseProcessedDir}/common-processed/logs"
BackupCache "${BaseProcessedDir}/common-processed/logs"
if [ $? -ne 0 ]; then
  exit 1
fi

#-------------------------------------------
# Setup the log 
#-------------------------------------------
logfile=`GetLogFileName "${BaseProcessedDir}/common-processed/logs"`
if [ -z "$logfile" ]; then
  echo "Error. Cannot determine log file name."
  echo "Cannot continue"
  exit 1
fi
logfile="${logfile}_log.txt"

#-------------------------------------------
# Run!
# Log all output with tee. Use 2>&1 to redirect stderr to stdout
#-------------------------------------------
sh "${ScriptDir}/01.anatomical/anatomical-pipeline.sh" 2>&1 | tee -a $logfile  
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit
fi

sh "${ScriptDir}/02.diffusion/diffusion-pipeline.sh" 2>&1 | tee -a $logfile
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit
fi

sh "${ScriptDir}/03.modules/run-modules.sh" 2>&1 | tee -a $logfile
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  exit
fi


