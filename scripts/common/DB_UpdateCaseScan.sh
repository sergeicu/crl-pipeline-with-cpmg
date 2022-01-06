#!/bin/sh


#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 2 ]; then
   echo "--------------------------------------"
   echo " UpdateCaseScan "
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Update the process dir corresponding to a RAW directory."
   echo "--------------------------------------"
   echo " UpdateCaseScan <CaseNumber> <ScanNumber>"
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

echo
setupThirdPartyTools
checkIfPipelineCanRun
if [ $? -ne 0 ]; then
  exit 1
fi
echo

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

source `dirname $0`/PipelineInit.txt || exit 1

#////////////////////////////////////////////////////////
# NOW REPAIR THE STRUCTURE
#////////////////////////////////////////////////////////
echo
echo -e "${VT100BOLD}UPDATING${VT100CLEAR}"
echo "- The output processed directory will be <$ScanProcessedDir>."


#-------------------------------------------
# Extract MRN from DICOM
#-------------------------------------------
PatientMRN=""
dcms=""
if [[ -d "$ScanRawDir/DICOM" ]]; then
  dcms=`find "$ScanRawDir/DICOM"/ -type f -name '*' -print -quit | head -1`
fi
if [ ${#dcms[@]} -eq 0 ]; then
  DicomFile=""
else
  DicomFile=${dcms[0]};
fi

if [ -z "$DicomFile" ]; then
    echo "- WARNING. No dicom file found. Cannot extract MRN."
else
    PatientMRN=`dcdump "$DicomFile" 2>&1 |  grep "0x0010,0x0020" | cut -d'>' -f 3 | cut -d'<' -f 2`
    if [ $? -ne 0 ]; then
       PatientMRN=""
    else
       PatientMRN=`echo "$PatientMRN" | sed "s/\ //g"`
       echo "- OK. The MRN is $PatientMRN"
    fi

    PatientDOB=`dcdump "$DicomFile" 2>&1 |  grep "0x0010,0x0030" | cut -d'>' -f 3 | cut -d'<' -f 2`
    if [ $? -ne 0 ]; then
       PatientDOB=""
    else
       PatientDOB=`echo "$PatientDOB" | sed "s/\ //g"`
       echo "- OK. The patient DOB is $PatientDOB"
    fi

fi


#-------------------------------------------------------------------------
#-------------------------------------------------------------------------
# IF WE ARE HERE EVERYTHING IS CORRECT
#-------------------------------------------------------------------------
#-------------------------------------------------------------------------

#-------------------------------------------
# Create default directories
#-------------------------------------------
mkdir -p "$ScanRawDir/nrrds" || exit 1
mkdir -p "$ScanRawDir/data_for_analysis" || exit 1 
mkdir -p "$ScanProcessedDir/common-processed/" || exit 1 
chmod -f +t "$ScanRawDir/data_for_analysis"            # Add sticky bit

mkdir -p "$ScanProcessedDir" || exit 1


#-------------------------------------------
# Copy the scripts
#-------------------------------------------
echo "- Update the scripts in <$ScanProcessedDir/scripts>"
mkdir -p "$ScanProcessedDir/scripts" || exit 1

ScriptDir=`readlink -f "$ScanProcessedDir/scripts"`

sh $SrcScriptDir/CopyScripts.sh "$ScanProcessedDir/" || exit 1


#-------------------------------------------
# Specific for ACR or human
#-------------------------------------------
if [[ $ACRmode -eq 1 ]]; then

  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/run-all.txt
  echo "sh \"$ScriptDir/04.acr/acr-pipeline.sh\"" >> $ScanProcessedDir/common-processed/run-all.txt

else

  mkdir -p "$ScanProcessedDir/common-processed/anatomical" || exit 1
  mkdir -p "$ScanProcessedDir/common-processed/diffusion" || exit 1
  mkdir -p "$ScanProcessedDir/common-processed/modules" || exit 1

  chmod -f g+rw "$ScanProcessedDir" "$ScanProcessedDir/common-processed" "$ScanProcessedDir/common-processed/anatomical" "$ScanProcessedDir/common-processed/diffusion" "$ScanProcessedDir/common-processed/modules" "$ScanRawDir/data_for_analysis" "$ScanRawDir/nrrds/" 

  #-------------------------------------------
  # Create the script to convert from DICOM
  # NOW IN THE $ScanRawDir/nrrds directory
  #-------------------------------------------
  echo "#!/bin/sh" > $ScanRawDir/nrrds/ConvertFromDICOM.txt
  echo "sh \"$ScriptDir/00.convert_dicom/ConvertFromDICOM.txt\" \"$ScanRawDir/DICOM\" \"$ScanRawDir/nrrds\"" >> $ScanRawDir/nrrds/ConvertFromDICOM.txt

  #-------------------------------------------
  # Create the script to run the common processed
  #-------------------------------------------
  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/run-anatomical.txt
  echo "sh \"$ScriptDir/01.anatomical/anatomical-pipeline.sh\"" >> $ScanProcessedDir/common-processed/run-anatomical.txt

  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/run-diffusion.txt
  echo "sh \"$ScriptDir/02.diffusion/diffusion-pipeline.sh\"" >> $ScanProcessedDir/common-processed/run-diffusion.txt

  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/run-modules.txt
  echo "sh \"$ScriptDir/03.modules/run-modules.sh\"" >> $ScanProcessedDir/common-processed/run-modules.txt

  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/run-all.txt
  #echo "sh \"$SrcScriptDir/common/DB_UpdateCaseScan.sh\" $CaseNumber $ScanNumber"  >> $ScanProcessedDir/common-processed/run-all.txt
  echo "sh ./run-anatomical.txt" >> $ScanProcessedDir/common-processed/run-all.txt
  echo "sh ./run-diffusion.txt" >> $ScanProcessedDir/common-processed/run-all.txt
  echo "sh ./run-modules.txt" >> $ScanProcessedDir/common-processed/run-all.txt

  echo "#!/bin/sh" > $ScanProcessedDir/common-processed/clean-all.txt
  echo "sh \"$SrcScriptDir/common/DB_UpdateCaseScan.sh\" $CaseNumber $ScanNumber"  >> $ScanProcessedDir/common-processed/clean-all.txt
  echo "sh \"$ScriptDir/01.anatomical/clean-pipeline.sh\""  >> $ScanProcessedDir/common-processed/clean-all.txt
  echo "sh \"$ScriptDir/02.diffusion/clean-pipeline.sh\""  >> $ScanProcessedDir/common-processed/clean-all.txt
fi


chmod -f g+rw $ScanProcessedDir/common-processed/*.txt


#-------------------------------------------
# Now save the results
#-------------------------------------------
WriteCaseInfo
WriteScanInfo

echo "FINISHED"
echo ""

exit 0

