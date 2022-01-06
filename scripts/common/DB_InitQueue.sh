#!/bin/sh


echo "--------------------------------------"
echo " DB_InitQueue"
echo " (c) Benoit Scherrer, 2009"
echo " benoit.scherrer@childrens.harvard.edu"
echo "--------------------------------------"
echo ""

umask 002

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ReadDBStudy

prevdir=`pwd`

rm -f "$BaseProcessedDir/queue.txt"


echo "$CaseCount"
#------------------------------------------
# For all cases
#------------------------------------------
for (( c=1; c<=$CaseCount ; c++ ));
do
  CaseFolder=${Case[$c]};
  echo "$CaseFolder"
  #------------------------------------------
  # Load the case study
  #------------------------------------------
  if [ ! -d "$CaseFolder" ]; then
    continue;
  fi

  cd "$CaseFolder"

  source "`pwd`/CaseInfo.sh" || exit 1

  #------------------------------------------
  # For all scans
  #------------------------------------------
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    ScanFolder=${Scan[$s]};
    if [ ! -d "$ScanFolder" ]; then
      continue;
    fi

    source "$ScanFolder/ScanInfo.sh" || exit 1

    #------------------------------------------
    # Check mutex
    #------------------------------------------
    if [ -f "$BaseProcessedDir/running_${c}_${s}.lock" ]; then
      echo "ERROR. Cannot initialize the queue system."
      echo "The analysis is currently running for Case $c Scan $s."
      echo "If it is an error please delete the files running_x_x.lock"
      echo "in $BaseProcessedDir."
      echo
      rm -f "$BaseProcessedDir/queue.txt"
      exit
    fi

    #------------------------------------------
    # Add to queue!
    #------------------------------------------
    if [ -d "$ScanRawDir" ]; then
      echo "#$CaseNumber# #$ScanNumber#" >> "$BaseProcessedDir/queue.txt"
    fi    
  done
  cd "$prevdir"
done

echo "DONE!"
echo
