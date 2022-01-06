#!/bin/sh


   echo "--------------------------------------"
   echo " DB_ConvertAllDICOMToNrrd"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Convert all the DICOMs to nrrds for a DB"
   echo "--------------------------------------"
   echo ""

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ReadDBStudy

prevdir=`pwd`

#------------------------------------------
# For all cases
#------------------------------------------
for (( c=1; c<=$CaseCount ; c++ ));
do
  CaseFolder=${Case[$c]};

  #------------------------------------------
  # Load the case study
  #------------------------------------------
  cd "$CaseFolder"
  if [ ! -f "`pwd`/CaseInfo.sh" ]; then
    echo "SKIP c${c}"
    continue;
  fi

  source "`pwd`/CaseInfo.sh" || exit 1

  #------------------------------------------
  # For all scans
  #------------------------------------------
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    ScanFolder=${Scan[$s]};
    cd "$ScanFolder"
  
    if [ ! -f "`pwd`/ScanInfo.sh" ]; then
      continue;
    fi
    source "`pwd`/ScanInfo.sh" || exit 1

#    check=`ls -d $ScanRawDir/nrrds/* | wc -l`
#    if [ $check -lt 2 ]; then    

    if [ -f "$ScanRawDir/nrrds/ConvertFromDICOM.txt" ]; then
      sh `dirname $0`/DB_UpdateCaseScan.sh $CaseNumber $ScanNumber
      cd "$ScanRawDir/nrrds"
      sh ConvertFromDICOM.txt
    else

      sh ${ScriptDir}/00.convert_dicom/ConvertFromDICOM.txt "$ScanRawDir/DICOM" "."
    fi

    #cd "$ScanRawDir/nrrds"
    #sh ConvertFromDICOM.txt

  done
  cd "$prevdir"
done
