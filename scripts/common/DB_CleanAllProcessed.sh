#!/bin/sh


   echo "--------------------------------------"
   echo " DB_CleanAllProcessed"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Clean all the processed directories"
   echo " (remove temporary files only)"
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
    if [ ! -f "$ScanFolder/ScanInfo.sh" ]; then
      continue;
    fi
    source "$ScanFolder/ScanInfo.sh" || exit 1

    cd "$ScanFolder"
    sh ${ScanProcessedDir}/common-processed/clean-all.txt
  done
  cd "$prevdir"
done
