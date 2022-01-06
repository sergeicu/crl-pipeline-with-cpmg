#!/bin/sh

echo "--------------------------------------"
echo " UpdateAllScripts"
echo " (c) Benoit Scherrer, 2009"
echo " benoit.scherrer@childrens.harvard.edu"
echo "--------------------------------------"
echo ""

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
cd "$BaseProcessedDir"
source "$BaseProcessedDir/DB.sh" || exit 1

prevdir=`pwd`

#------------------------------------------
# For all cases
#------------------------------------------
for (( c=1; c<=$CaseCount ; c++ ));
do
  CaseFolder=${Case[$c]};
  echo ""
  echo ""

  #------------------------------------------
  # Load the case study
  #------------------------------------------
  cd "$CaseFolder"
  source "`pwd`/CaseInfo.sh" || exit 1

  if [ -z "$ScanCount" ]; then
    echo "ERROR in `pwd`/CaseInfo.sh"
    exit 1
  fi

  #------------------------------------------
  # For all scans
  #------------------------------------------
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    ScanFolder=${Scan[$s]};
    cd "$ScanFolder"
    echo "Working on $ScanFolder"
    source "`pwd`/ScanInfo.sh" || exit 1

    sh "${SrcScriptDir}/CopyScripts.sh" "${ScanFolder}/scripts/"
  done

  cd "$prevdir"
done



