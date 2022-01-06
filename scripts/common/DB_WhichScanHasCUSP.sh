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

nbCUSP_Nrrd=0
nbCUSP_ToSelect=0

nCUSP45=0
nCUSP65=0

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
  if [ ! -d "$CaseFolder" ]; then
    echo "Error. Cannot find <$CaseFolder>"
  fi

  cd "$CaseFolder"

  ScanCount=0		# In case CaseInfo.sh exists but is invalid

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

    #----------------------------------------
    # Look for a CUSP folder in RAW/nrrds folder
    #----------------------------------------
    cuspNrrd=`find "${ScanRawDir}/nrrds"/ -maxdepth 1 -type d -name '*cusp*' | wc -l`
    if [ $cuspNrrd -ne 0 ] && [ -d "${ScanRawDir}/Nrrds" ] ; then
      cuspNrrd=`find "${ScanRawDir}/Nrrds"/ -maxdepth 1 -type d -name '*cusp*' | wc -l`
    fi

    #----------------------------------------
    # Look for a CUSP folder in RAW/data_for_analysis
    #----------------------------------------
    cuspSelected=`find "${ScanRawDir}/data_for_analysis"/ -maxdepth 2 -type d -name '*cusp*' | wc -l`

    #----------------------------------------
    # If both in nrrds and data_for_analysis...
    #----------------------------------------
    if [ $cuspSelected -ne 0 ]; then
       f=`find "${ScanRawDir}/data_for_analysis"/ -maxdepth 2 -type d -name 'cusp*' | head -1`
       nfiles=`ls -l "$f" | wc -l`
       nfiles=$(($nfiles-1))

       echo "OK        - $f  ($nfiles)" 
       nbCUSP_Nrrd=$(($nbCUSP_Nrrd + 1))

       if [ $nfiles -lt 50 ]; then
         nCUSP45=$((${nCUSP45}+1))
       else
         nCUSP65=$((${nCUSP65}+1))
       fi

    fi

    #----------------------------------------
    # If only in nrrds... to be selected!
    #----------------------------------------
    if [ $cuspNrrd -ne 0 ] && [ $cuspSelected -eq 0 ]; then
       f=`find "${ScanRawDir}/nrrds"/ -maxdepth 1 -type d -name '*cusp*' | head -1`
       if [ -z "$f" ] && [ -d "${ScanRawDir}/Nrrds" ] ; then
         f=`find "${ScanRawDir}/Nrrds"/ -maxdepth 1 -type d -name '*cusp*' | head -1`
       fi
       echo "TO SELECT - $f" 
       let "nbCUSP_ToSelect = $nbCUSP_ToSelect + 1"
    fi

  done
  cd "$prevdir"
done


echo ""
echo "  $nbCUSP_Nrrd CUSP scans ready in data_for_analysis"
echo "  $nbCUSP_ToSelect CUSP scans to select from Nrrds -> data_for_analysis"
echo "  ${nCUSP45} CUSP45"
echo "  ${nCUSP65} CUSP65"

echo ""

