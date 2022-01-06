#!/bin/sh



if [ -z "$1" ]; then
   echo "-----------------------------------------------"
   echo " DB_FindMRN"
   echo " (c) Benoit Scherrer, 2012"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Go through all subjects and look for an MRN"
   echo "-----------------------------------------------"
   echo "SYNTAX: DB_FindMRN [MRN]"
   echo ""
   exit 1
fi

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ReadDBStudy "0"

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

  if [ -f "`pwd`/CaseInfo.sh" ]; then
    source "`pwd`/CaseInfo.sh" || exit 1

    if [ "$MRN" == "$1" ]; then
      echo "`pwd`/CaseInfo.sh"
      exit 0
    fi 
  fi


  cd "$prevdir"
done

exit 1

