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
if [[ $? -ne 0 ]]; then
  exit
fi




prevdir=`pwd`

prevcase=""

nbCases=0
nbTotalScans=0

echo "CaseXXX    MRN     DOB   ScanXX         Name"

#------------------------------------------
# For all cases
#------------------------------------------
for (( c=1; c<=$CaseCount ; c++ ));
do
  CaseFolder=${Case[$c]};
  
  #------------------------------------------
  # Load the case study
  #------------------------------------------
  if [ ! -d "$CaseFolder" ]; then
    continue;
  fi

  cd "$CaseFolder"

  source "`pwd`/CaseInfo.sh" || exit 1

  nbCases=$(($nbCases+1))

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
    # Add to queue!
    #------------------------------------------
    if [ -d "$ScanRawDir" ]; then

      if [ -z "$PatientSex" ]; then
        PatientSex="?"
      fi

      if [ -z "$DOB" ]; then
        DOB="XXXXXXXX"
      fi

      if [ -z "$AcquisitionDate" ]; then
        AcquisitionDate="XXXXXXXX"
      fi

      if [ "$CaseName" == "$prevcase" ]; then
        CaseName="-------"
      else
        prevcase=$CaseName
      fi

      sname=`basename $ScanFolder`
      echo -e "$CaseName $MRN $PatientSex $DOB $sname $AcquisitionDate \t $PatientName " 

      nbTotalScans=$(($nbTotalScans+1))

      DOB=""
      AcquisitionDate=""
      PatientSex=""
      CaseName=""
      MRN=""
      PatientName=""
    fi    
  done
  cd "$prevdir"
done

echo
echo "Total number of cases: $nbCases"
echo "Total number of scans: $nbTotalScans"

echo


