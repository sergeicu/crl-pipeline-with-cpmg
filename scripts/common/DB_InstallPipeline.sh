#!/bin/sh


  echo "----------------------------------------------------------"
  echo " Install the pipeline for a new database."
  echo " (WARNING: Not for a single subject)"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo


# LOCAL scripts with a different CUSP processing
SRC_SCRIPT=`dirname $0`
SRC_SCRIPT=`readlink -f "${SRC_SCRIPT}/../"`

#-------------------------------------------
# Check the setting file
#-------------------------------------------
if [ ! -f "${SRC_SCRIPT}/common/Settings.txt" ]; then
  echo
  echo "ERROR!"
  echo "You should first copy the file SettingsExample.txt to Settings.txt"
  echo "and modify it to setup the settings for your database."
  echo
  exit 1
fi

#-------------------------------------------
# Import the global settings
#-------------------------------------------
source $SRC_SCRIPT/common/Settings.txt || exit 1


#-------------------------------------------
# Check some variables (CASEID/SCANID can be null)
#-------------------------------------------
if [ ! -d "$BaseRawDir" ]; then
  echo "ERROR. BaseRawDir=$BaseRawDir is not a valid directory in Settings.txt"
  exit 1
fi
if [ ! -d "$BaseProcessedDir" ]; then
  echo "ERROR. BaseProcessedDir=$BaseProcessedDir is not a valid directory in Settings.txt"
  exit 1
fi

s1=`readlink -f "${SrcScriptDir}"`
if [ "$s1" != "$SRC_SCRIPT" ]; then
  echo "ERROR. SrcScriptDir is invalid in Settings.txt. Should be $SRC_SCRIPT"
  exit 1
fi

#-------------------------------------------
# Begin to install
#-------------------------------------------

DEST_DIR=$BaseProcessedDir
echo "--------------------------------------------------"
echo "Installing the pipeline in multiple subjects mode."
echo "SCRIPT SRC FOLDER : <${SRC_SCRIPT}>."
echo "DESTINATION FOLDER: <${DEST_DIR}>."
echo "--------------------------------------------------"


cd "$DEST_DIR"

if [ ! -f "DB.sh" ]; then
  echo "" > DB.sh
  chmod g+rw DB.sh
  chmod a+r DB.sh
fi

#-------------------------------------------
# The default modules
#-------------------------------------------
if [ ! -f "${SRC_SCRIPT}/03.modules/Modules.txt" ]; then
  chmod g+rw "${SRC_SCRIPT}/03.modules/Modules.txt"
  chmod a+r "${SRC_SCRIPT}/03.modules/Modules.txt"
fi

#-------------------------------------------
# Init the settings
#-------------------------------------------
source $SRC_SCRIPT/common/SettingsManager.txt || exit 1
CURRENT_SETTINGS_FILE="$DEST_DIR/00_ModuleSettings.txt"
initSettings
if [ -f "$SRC_SCRIPT/03.modules/Modules.txt" ]; then
  source "$SRC_SCRIPT/03.modules/Modules.txt"
fi

#-------------------------------------------
# Creates convenient scripts
# We do the test of the mutex HERE so that
# in most cases, when we come back from the
# script (error or no error) the mutex is
# deleted
#-------------------------------------------
echo "#!/bin/sh" > UpdateCaseScan.sh || exit 1
echo "source \"${SRC_SCRIPT}/common/bashMutex.sh\" || exit 1" >> UpdateCaseScan.sh
echo "ScanNumber=\`echo \"\$2\" | sed 's/^0*//g'\`" >> UpdateCaseScan.sh
echo "mutexLockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\" 10" >> UpdateCaseScan.sh
echo "if [ \$? -eq 0 ]; then" >> UpdateCaseScan.sh
echo "  sh ${SRC_SCRIPT}/common/DB_UpdateCaseScan.sh \$1 \${ScanNumber}" >> UpdateCaseScan.sh
echo "  mutexUnlockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\"" >> UpdateCaseScan.sh
echo "  exit 0" >> UpdateCaseScan.sh
echo "else" >> UpdateCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> UpdateCaseScan.sh
echo "  echo \"ERROR. The pipeline seems to be already running on that case.\"" >> UpdateCaseScan.sh
echo "  echo" >> UpdateCaseScan.sh
echo "  echo \"If you are sure it is not, delete the file running_$1_${ScanNumber}.lock.\"" >> UpdateCaseScan.sh
echo "  echo \"This file may still exist if last pipeline execution was \"" >> UpdateCaseScan.sh
echo "  echo \"interrupted with Ctrl+C\"" >> UpdateCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> UpdateCaseScan.sh
echo "  echo" >> UpdateCaseScan.sh
echo "  exit 1" >> UpdateCaseScan.sh
echo "fi" >> UpdateCaseScan.sh
chmod g+rwx UpdateCaseScan.sh
chmod a+r UpdateCaseScan.sh

echo "#!/bin/sh" > ConvertCaseScanToNrrd.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_ConvertCaseScanToNrrd.sh \$1 \$2" >> ConvertCaseScanToNrrd.sh
chmod g+rwx ConvertCaseScanToNrrd.sh
chmod a+r ConvertCaseScanToNrrd.sh

echo "#!/bin/sh" > RunCaseScan.sh || exit 1
echo "source \"${SRC_SCRIPT}/common/bashMutex.sh\" || exit 1" >> RunCaseScan.sh
echo "ScanNumber=\`echo \"\$2\" | sed 's/^0*//g'\`" >> RunCaseScan.sh
echo "mutexLockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\" 10" >> RunCaseScan.sh
echo "if [ \$? -eq 0 ]; then" >> RunCaseScan.sh
echo "  sh ${SRC_SCRIPT}/common/DB_RunCaseScan.sh \$1 \${ScanNumber}" >> RunCaseScan.sh
echo "  mutexUnlockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\"" >> RunCaseScan.sh
echo "  exit 0" >> RunCaseScan.sh
echo "else" >> RunCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> RunCaseScan.sh
echo "  echo \"ERROR. The pipeline seems to be already running on that case.\"" >> RunCaseScan.sh
echo "  echo" >> RunCaseScan.sh
echo "  echo \"If you are sure it is not, delete the file running_$1_${ScanNumber}.lock.\"" >> RunCaseScan.sh
echo "  echo \"This file may still exist if last pipeline execution was \"" >> RunCaseScan.sh
echo "  echo \"interrupted with Ctrl+C\"" >> RunCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> RunCaseScan.sh
echo "  echo" >> RunCaseScan.sh
echo "  exit 1" >> RunCaseScan.sh
echo "fi" >> RunCaseScan.sh
chmod g+rwx RunCaseScan.sh
chmod a+r RunCaseScan.sh

#Not valid anymore - !!tmp remove common/DB_RunCaseInterval.sh
#echo "#!/bin/sh" > RunCaseInterval.sh || exit 1
#echo "sh ${SRC_SCRIPT}/common/DB_RunCaseInterval.sh \$1 \$2" >> RunCaseInterval.sh
#chmod g+rw RunCaseInterval.sh
#chmod a+r RunCaseInterval.sh

echo "#!/bin/sh" > ConvertAllDICOMToNrrd.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_ConvertAllDICOMToNrrd.sh" >> ConvertAllDICOMToNrrd.sh
chmod g+rwx ConvertAllDICOMToNrrd.sh
chmod a+r ConvertAllDICOMToNrrd.sh

echo "#!/bin/sh" > DB_InitQueue.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_InitQueue.sh" >> DB_InitQueue.sh
chmod g+rwx DB_InitQueue.sh
chmod a+r DB_InitQueue.sh

echo "#!/bin/sh" > DB_RunNextInQueue.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_RunNextInQueue.sh" >> DB_RunNextInQueue.sh
chmod g+rwx DB_RunNextInQueue.sh
chmod a+r DB_RunNextInQueue.sh


echo ""
echo ""
echo "SETTING FILE: (check if OK)"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
cat "${SRC_SCRIPT}/common/Settings.txt"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
echo ""

echo "Pipeline successfully installed!!"
echo ""
echo "Check if pipeline can run on this machine..."
source ${SRC_SCRIPT}/common/PipelineUtils.txt || exit 1
setupThirdPartyTools
checkIfPipelineCanRun

