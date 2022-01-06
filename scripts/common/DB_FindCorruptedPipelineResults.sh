#!/bin/sh


   echo "--------------------------------------"
   echo " DB_RepairAllCases"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo "--------------------------------------"
   echo " DB_FindCorruptedPipelineResults"
   echo ""

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ReadDBStudy

if [ -z "$CaseCount" ] || [ $CaseCount -eq 0 ]; then
  echo "ERROR. Invalid $BaseProcessedDir/DB.sh file."
  echo "CaseCount is null or not set"
  echo "run scripts/DB_RepairAllCases.sh to fix DB.sh"
  echo
  exit 1
fi


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

  source "`pwd`/CaseInfo.sh" 
  if [ $? -ne 0 ]; then
    echo "- Invalid CaseInfo.sh ($CaseName)"
    continue
  fi

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
    if [ $? -ne 0 ]; then
      echo "- Invalid ScanInfo.sh ($CaseName $ScanName)"
      continue
    fi

    f=`find "$ScanFolder/common-processed" -maxdepth 1 -type f -name '*_PipelineResults.txt' |head -1`
    source "$f" 
    if [ $? -ne 0 ]; then
      echo "- Invalid PipelineResults ($CaseName $ScanName)"
      continue
    fi
  done
  cd "$prevdir"
done
