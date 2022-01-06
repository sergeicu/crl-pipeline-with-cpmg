#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 2 ]; then
   echo "--------------------------------------------"
   echo " ConvertCaseScanToNrrd "
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Convert the DICOMs of a scan given "
   echo " by its case number and scan number to Nrrd"
   echo "--------------------------------------------"
   echo " DB_ConvertCaseScanToNrrd <CaseNumber> <ScanNumber>"
   echo ""
   exit 1
fi

umask 002

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
# Update and run !
#-------------------------------------------
source `dirname $0`/PipelineInit.txt || exit 1
cd "$ScanProcessedDir/" || exit 1
source "${ScanProcessedDir}/ScanInfo.sh" || exit 1

cd "$ScanRawDir" || exit 1
mkdir -p "${ScanProcessedDir}/nrrds"
cd nrrds

echo
if [ -f "$ScanRawDir/nrrds/ConvertFromDICOM.txt" ]; then
  echo "Run $ScanRawDir/nrrds/ConvertFromDICOM.txt"
  sh "$ScanRawDir/nrrds/ConvertFromDICOM.txt"
else
  echo "Run ${ScriptDir}/00.convert_dicom/ConvertFromDICOM.txt \"$ScanRawDir/DICOM\" \".\""
  sh ${ScriptDir}/00.convert_dicom/ConvertFromDICOM.txt "$ScanRawDir/DICOM" "."
fi



