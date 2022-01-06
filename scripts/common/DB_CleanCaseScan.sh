#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 2 ]; then
   echo "--------------------------------------"
   echo " CleanCaseScan "
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Clean the processed directory"
   echo " (remove temporary files only)"
   echo "--------------------------------------"
   echo " CleanCaseScan <CaseNumber> <ScanNumber>"
   echo ""
   exit 1
fi
CaseNumber=$1
ScanNumber=$2

#-------------------------------------------
# Import the global settings
#-------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ScriptDir=$SrcScriptDir
source `dirname $0`/PipelineUtils.txt || exit 1

setupThirdPartyTools
checkIfPipelineCanRun
if [ $? -ne 0 ]; then
  exit 1
fi

#////////////////////////////////////////////////////////
# LOCATE CASE/SCAN FOLDER (Exit if error)
# Sets the variables:
# $PatientName, $CaseName, $ScanName, $CaseRawDir,
# $CaseProcessedDir, $CaseRelativeDir, $ScanRawDir,
# $ScanProcessedDir, $ScanRelativeDir
#////////////////////////////////////////////////////////

getCaseScan $CaseNumber $ScanNumber || exit 1
if [ $? -ne 0 ]; then
  exit 1
fi

#-------------------------------------------
# Now that we have the patient name, take the scan folder
#-------------------------------------------
if [ ! -d "$ScanProcessedDir" ]; then
  echo "FATAL ERROR. Cannot find $ScanProcessedDir"
  exit 1
fi

#-------------------------------------------
# Update and run !
# run-all will update the scripts and run 
# everything
#-------------------------------------------
cd "$ScanProcessedDir/common-processed/"
sh clean-all.txt	# Remark: clean-all.txt calls DB_UpdateCaseScan


