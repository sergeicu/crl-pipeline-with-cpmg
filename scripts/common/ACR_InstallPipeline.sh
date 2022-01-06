#!/bin/sh

if [ $# -ne 1 ]; then
  echo "----------------------------------------------------------"
  echo " Install the ACR pipeline for a new database."
  echo 
  echo " (c) CRL, Benoit Scherrer, 2013"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: ACR_InstallPipeline.sh [dest folder]"
  echo
  exit 1
fi

# LOCAL scripts with a different CUSP processing
SRC_SCRIPT=`dirname $0`
SRC_SCRIPT=`readlink -f "${SRC_SCRIPT}/../"`
DEST_DIR=`readlink -f "$1"`

echo "--------------------------------------------------"
echo "Installing the pipeline in database mode."
echo "SCRIPT SRC FOLDER : <${SRC_SCRIPT}>."
echo "DESTINATION FOLDER: <${DEST_DIR}>."
echo "--------------------------------------------------"

#-------------------------------------------
# Check the setting file
#-------------------------------------------
if [ ! -f "${SRC_SCRIPT}/common/Settings.txt" ]; then
  echo "ERROR. You should copy the file SettingsExample.txt to Settings.txt"
  echo "and modify it to setup the settings for your database."
  exit 1
fi

#-------------------------------------------
# Import the global settings
#-------------------------------------------
source `dirname $0`/Settings.txt || exit 1

echo "Install Pipeline..."

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
cd "$DEST_DIR"

if [ ! -f "DB.sh" ]; then
  echo "" > DB.sh
  chmod g+rw DB.sh
  chmod a+r DB.sh
fi

#-------------------------------------------
# Init the settings
#-------------------------------------------
source `dirname $0`/SettingsManager.txt || exit 1
CURRENT_SETTINGS_FILE="$DEST_DIR/00_ModuleSettings.txt"
initSettings

#-------------------------------------------
# Creates convenient scripts
# We do the test of the mutex HERE so that
# in most cases, when we come back from the
# script (error or no error) the mutex is
# deleted
#-------------------------------------------
echo "#!/bin/sh" > UpdateACR.sh || exit 1
echo "source \"${SRC_SCRIPT}/common/bashMutex.sh\" || exit 1" >> UpdateACR.sh
echo "ScanNumber=\`echo \"\$2\" | sed 's/^0*//g'\`" >> UpdateACR.sh
echo "mutexLockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\" 10" >> UpdateACR.sh
echo "if [ \$? -eq 0 ]; then" >> UpdateACR.sh
echo "  sh ${SRC_SCRIPT}/common/DB_UpdateACR.sh \$1 \${ScanNumber}" >> UpdateACR.sh
echo "  mutexUnlockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\"" >> UpdateACR.sh
echo "else" >> UpdateACR.sh
echo "  echo \"---------------------------------------------------------------\"" >> UpdateACR.sh
echo "  echo \"ERROR. The pipeline seems to be already running on that case.\"" >> UpdateACR.sh
echo "  echo" >> UpdateACR.sh
echo "  echo \"If you are sure it is not, delete the file running_$1_${ScanNumber}.lock.\"" >> UpdateACR.sh
echo "  echo \"This file may still exist if last pipeline execution was \"" >> UpdateACR.sh
echo "  echo \"interrupted with Ctrl+C\"" >> UpdateACR.sh
echo "  echo \"---------------------------------------------------------------\"" >> UpdateACR.sh
echo "  echo" >> UpdateACR.sh
echo "fi" >> UpdateACR.sh
chmod g+rw UpdateACR.sh
chmod a+r UpdateACR.sh

echo "#!/bin/sh" > ConvertCaseScanToNrrd.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_ConvertCaseScanToNrrd.sh \$1 \$2" >> ConvertCaseScanToNrrd.sh
chmod g+rw ConvertCaseScanToNrrd.sh
chmod a+r ConvertCaseScanToNrrd.sh

echo "#!/bin/sh" > RunCaseScan.sh || exit 1
echo "source \"${SRC_SCRIPT}/common/bashMutex.sh\" || exit 1" >> RunCaseScan.sh
echo "ScanNumber=\`echo \"\$2\" | sed 's/^0*//g'\`" >> RunCaseScan.sh
echo "mutexLockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\"" >> RunCaseScan.sh
echo "if [ \$? -eq 0 ]; then" >> RunCaseScan.sh
echo "  sh ${SRC_SCRIPT}/common/DB_RunCaseScan.sh \$1 \${ScanNumber}" >> RunCaseScan.sh
echo "  mutexUnlockFile \"\`dirname \$0\`/running_\$1_\${ScanNumber}\"" >> RunCaseScan.sh
echo "else" >> RunCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> RunCaseScan.sh
echo "  echo \"ERROR. The pipeline seems to be already running on that case.\"" >> RunCaseScan.sh
echo "  echo" >> RunCaseScan.sh
echo "  echo \"If you are sure it is not, delete the file running_$1_${ScanNumber}.lock.\"" >> RunCaseScan.sh
echo "  echo \"This file may still exist if last pipeline execution was \"" >> RunCaseScan.sh
echo "  echo \"interrupted with Ctrl+C\"" >> RunCaseScan.sh
echo "  echo \"---------------------------------------------------------------\"" >> RunCaseScan.sh
echo "  echo" >> RunCaseScan.sh
echo "fi" >> RunCaseScan.sh
chmod g+rw RunCaseScan.sh
chmod a+r RunCaseScan.sh


echo "#!/bin/sh" > ConvertAllDICOMToNrrd.sh || exit 1
echo "sh ${SRC_SCRIPT}/common/DB_ConvertAllDICOMToNrrd.sh" >> ConvertAllDICOMToNrrd.sh
chmod g+rw ConvertAllDICOMToNrrd.sh
chmod a+r ConvertAllDICOMToNrrd.sh


echo "#!/bin/sh" > CreateReportForSite.sh || exit 1
echo "sh ${SRC_SCRIPT}/04.acr/CreateReportForSite.sh \$1" >> CreateReportForSite.sh
chmod g+rw CreateReportForSite.sh
chmod a+r CreateReportForSite.sh



echo ""
echo ""
echo "SETTING FILE: (check if OK)"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
cat "${SRC_SCRIPT}/common/Settings.txt"
echo "- - - - - - - - - - - - - - - - - - - - - - - - - -"
echo ""

echo "Pipeline successfully installed!!"
echo ""
