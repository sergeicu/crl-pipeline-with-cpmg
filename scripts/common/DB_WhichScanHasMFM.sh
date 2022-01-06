#!/bin/sh

if [[ $# -eq 0 ]]; then
   echo "--------------------------------------"
   echo " DB_WhichScanHasNoDataForAnalysis"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Go through all scans and print the name"
   echo " of scans with MFM computed"
   echo ""
   echo "DB_WhichScanHasMFM.sh [mode] [outputfile] [[version_min]]"
   echo "   mode=0: mfm only [default]"
   echo "   mode=1: diamond only"
   echo "   mode=2: diamond or mfm"
   echo "--------------------------------------"
   echo ""
   exit
fi

ofile=`readlink -f "$2"`
if [[ ! -z "$ofile" ]] && [[ -f "$ofile" ]]; then
  rm -f "$ofile"
fi

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/DBUtils.txt || exit 1

ReadDBStudy

prevdir=`pwd`

nMFM=0
nDIAMOND=0
nMFMtoCompute=0
nDIAMONDtoCompute=0

if [[ $1 -eq 1 ]]; then
  diamond=1
  mfm=0
elif [[ $1 -eq 2 ]]; then
  diamond=1
  mfm=1
else
  diamond=0
  mfm=1
fi

versionrequired=$3

#------------------------------------------
# For all cases
#------------------------------------------
for (( c=1; c<=$CaseCount ; c++ ));
do
  CaseFolder=${Case[$c]};
  if [[ -z "$CaseFolder" ]]; then
    continue;
  fi

  #------------------------------------------
  # Load the case study
  #------------------------------------------
  if [ ! -d "$CaseFolder" ]; then
    echo "Error. Cannot find <$CaseFolder> declared in DB.sh"
    continue;
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

    if [[ ! -d "$ScanFolder" ]]; then
      continue
    fi

    cd "$ScanFolder"

    unset PipelineResultsFile

    source ./ScanInfo.sh || exit 1
   
    unset NB_MULTIB_DWI_FOLDERS
    unset dwiID
    unset dwifile
    unset dwifolder
 


    if [[ -f "$PipelineResultsFile" ]]; then
      source "$PipelineResultsFile" 
      source "$ScanProcessedDir/common-processed/00_Cache.txt"
      if [[ $? -eq 0 ]] && [[ ${NB_MULTIB_DWI_FOLDERS} -ge 1 ]] ; then
        for (( dwi=0; dwi<${NB_MULTIB_DWI_FOLDERS} ; dwi++ ))
        do
           dwifolder=${MULTIB_DWI_FOLDERS[$dwi]}
           dwiID=`basename $dwifolder`         

           if [[ $mfm -eq 1 ]]; then
             dwifile="${dwiID}_B632MFM_3F_T0"
             dwifile=${!dwifile}
             if [[ -f $dwifile ]]; then
               nMFM=$((nMFM+1))
               datemod=`stat -c %y "$dwifile" | cut -d ' ' -f1`

               version="${dwiID}_MODULE_MOSEMFM_3T_VERSION"; version=${!version}
               if [[ -z "$versionrequired" ]]; then
                 versionOK=1
               else
                 versionOK=`echo "${version}>=${versionrequired}" | bc`
               fi

               echo "MFM, $datemod, $version (ok=$versionOK), `dirname $dwifile`"

               if [[ ! -z $ofile ]] && [[ $versionOK -eq 1 ]]; then
                 echo `dirname $dwifile` >> $ofile
               fi
             else
               nMFMtoCompute=$((nMFMtoCompute+1))
             fi
           fi

           if [[ $diamond -eq 1 ]]; then
             dwifile="${dwiID}_B632DIAMOND_3F_T0"
             dwifile=${!dwifile}
             if [[ -f $dwifile ]]; then
               nDIAMOND=$((nDIAMOND+1))
               datemod=`stat -c %y "$dwifile" | cut -d ' ' -f1`

               version="${dwiID}_MODULE_B632DIAMOND_3T_VERSION"; version=${!version}
               if [[ -z "$versionrequired" ]]; then
                 versionOK=1
               else
                 versionOK=`echo "${version}>=${versionrequired}" | bc`
               fi
 
               echo "DIAMOND, $datemod, $version (ok=$versionOK), `dirname $dwifile`"

               if [[ ! -z $ofile ]] && [[ $versionOK -eq 1 ]]; then
                 echo `dirname $dwifile` >> $ofile
               fi
             else
               nDIAMONDtoCompute=$((nDIAMONDtoCompute+1))
             fi
           fi


           # Be sure to clear the variable
           read -r "${dwiID}_B632MFM_3F_T0" <<< "";
           read -r "${dwiID}_B632DIAMOND_3F_T0" <<< "";
          
       done
     fi
  fi

  done
  cd "$prevdir"
done

echo ""

if [[ ! -z $ofile ]]; then
  echo "Results written in $ofile"
fi

if [[ $mfm -eq 1 ]]; then
  echo "  $nMFM MFM computed"
  echo "  $nMFMtoCompute not ready yet (multi b-value dwi but no mfm)"
fi
if [[ $diamond -eq 1 ]]; then
  echo "  $nDIAMOND DIAMOND computed"
  echo "  $nDIAMONDtoCompute not ready yet (multi b-value dwi but no diamond)"
fi


echo ""

