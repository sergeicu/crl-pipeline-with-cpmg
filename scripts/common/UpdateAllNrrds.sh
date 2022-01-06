#!/bin/sh

if [ $# -lt 1 ]; then
   echo "--------------------------------------"
   echo " runScriptOnAllScans"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Run a script on all scans of all"
   echo " patients."
   echo "--------------------------------------"
   echo " runScriptOnAllScans [ScriptFile] [params...]"
   echo ""
   exit 1
fi

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
for (( c=16; c<=60 ; c++ ));
do
  CaseFolder=${Case[$c]};
  echo ""
  echo ""
  #echo $CaseFolder

  #------------------------------------------
  # Load the case study
  #------------------------------------------
  cd "$CaseFolder"
  source "`pwd`/CaseInfo.sh" || exit 1

  #------------------------------------------
  # For all scans
  #------------------------------------------
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    ScanFolder=${Scan[$s]};
    cd "$ScanFolder"
    echo "Working on $ScanFolder"
    source "`pwd`/ScanInfo.sh" || exit 1

    
   # rm -R ${ScanFolder}/nrrds
   # sh ./scripts/common/UpdateProcessedDir.sh ${CaseNumber} ${ScanNumber}
    cd nrrds
    sh ConvertFromDICOM.txt
    #sh $ScanFolder/$1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12} ${13} ${14} ${15} ${16}

    #rm "$1"
  done

  cd "$prevdir"
done
