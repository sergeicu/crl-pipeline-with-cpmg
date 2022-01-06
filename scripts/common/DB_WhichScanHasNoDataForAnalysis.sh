#!/bin/sh


   echo "--------------------------------------"
   echo " DB_WhichScanHasNoDataForAnalysis"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Go through all scans and print the name"
   echo " of scans without the *bestt1w.nrrd in data_for_analysis"
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
  if [ -z "$CaseFolder" ]; then
    continue;
  fi

  #------------------------------------------
  # Load the case study
  #------------------------------------------
  cd "$CaseFolder"

  if [ -f "`pwd`/CaseInfo.sh" ]; then
    source "`pwd`/CaseInfo.sh" || exit 1
  else
    echo "ERROR. No file `pwd`/CaseInfo.sh" 
  fi

  #------------------------------------------
  # For all scans
  #------------------------------------------
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    ScanFolder=${Scan[$s]};
    cd "$ScanFolder"

    source ./ScanInfo.sh || exit 1

    if [ -d "${ScanRawDir}/data_for_analysis/" ]; then
       check=`find "${ScanRawDir}/data_for_analysis"/ -name '*bestt1w.nrrd' | wc -l`
    elif [ -d "${ScanRawDir}/data_for_analysis/" ]; then
       check=`find "${ScanRawDir}/data_for_analysis"/ -name '*bestt1w.nrrd' | wc -l`
    else
       check=0
    fi

    if [ $check -eq 0 ]; then
      echo "${ScanFolder}"
    fi

  done
  cd "$prevdir"
done
