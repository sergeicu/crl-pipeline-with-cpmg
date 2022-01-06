#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 2 ]; then
   echo "--------------------------------------"
   echo " RunCaseScan "
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Update the process dir and run the common"
   echo " process pipeline."
   echo "--------------------------------------"
   echo " RunCaseScan <CaseNumber> <ScanNumber>"
   echo ""
   exit 1
fi
CaseNumber=$1
ScanNumber=`echo "$2" | sed 's/^0*//g'`

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


#-------------------------------------------
# First update structure
#-------------------------------------------
echo -e "${VT100BLUE}-------------------------------"
echo -e "(1) FIRST UPDATE"
echo -e "-------------------------------${VT100CLEAR}"
sh `dirname $0`/DB_UpdateCaseScan.sh $1 $2

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
echo -e "${VT100BLUE}-------------------------------"
echo -e "(2) NOW RUN"
echo -e "-------------------------------${VT100CLEAR}"
getCaseScan $CaseNumber $ScanNumber || exit 1
if [ $? -ne 0 ]; then
  exit 1
fi


if [ ! -d "$ScanProcessedDir" ]; then
  echo "FATAL ERROR. Cannot find <$ScanProcessedDir>"
  exit 1
fi

#-------------------------------------------
# Backup the cache before anything else
#-------------------------------------------
mkdir -p "$ScanProcessedDir/common-processed/logs"
BackupCache "$ScanProcessedDir/common-processed/logs"
if [ $? -ne 0 ]; then
  exit 1
fi

#-------------------------------------------
# Setup the log file
#-------------------------------------------
logfile=`GetLogFileName "$ScanProcessedDir/common-processed/logs"`
if [ -z "$logfile" ]; then
  echo "Error. Cannot determine log file name."
  echo "Cannot continue"
  exit 1
fi
logfile="${logfile}_log.txt"

#-------------------------------------------
# Init the pipeline
#-------------------------------------------
source `dirname $0`/PipelineInit.txt || exit 1

#-------------------------------------------
# Update and run !
# run-all will update the scripts and run 
# everything
#-------------------------------------------
cd "$ScanProcessedDir/common-processed/"
sh run-all.txt | tee -a ${logfile}	# Remark: run-all.txt calls DB_UpdateCaseScan


