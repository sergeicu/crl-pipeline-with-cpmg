#!/bin/sh

opt=$1

if [[ -z "$opt" ]]; then
   echo "----------------------------------------------------------------"
   echo " DB_RepairAllCases"
   echo " (c) Benoit Scherrer, 2009"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Update all cases. Can be used to repair the DB.sh file"
   echo "----------------------------------------------------------------"
   echo " `basename $0` <--update|--noupdate>"
   echo "   --update :   updates the content of each case/scan "
   echo "                (scripts & CaseInfo.sh & ScanInfo.sh)"
   echo "   --noupdate : do not update each scan but just regenerates DB.sh"
   echo "                (much faster)"
   echo ""
   exit

fi


#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/Settings.txt || exit 1
source `dirname $0`/bashMutex.sh || exit 1

#------------------------------------------
# Check that BaseProcessedDir was set
#------------------------------------------
if [ -z "$BaseProcessedDir" ]; then
  echo "FATAL ERROR: BaseProcessedDir is not set."
  exit 1;   
fi 

#------------------------------------------
# Take the mutex
#------------------------------------------
dbfile="$BaseProcessedDir/DB.sh"
lockdbfile="$BaseProcessedDir/DB.lock"
mutexLockFile "$lockdbfile"
if [[ $? -ne 0 ]]; then
  exit 1
fi

#------------------------------------------
# Create/Update the DB file
#------------------------------------------
echo "#!/bin/sh" > $dbfile
echo "#-------------------------------------------" >> $dbfile
echo "# CRL ANALYSIS PIPELINE " >> $dbfile
echo "# Database Cases Description" >> $dbfile
echo "# Can be imported in a script pipeline." >> $dbfile
echo "# Benoit Scherrer, 2013" >> $dbfile
echo "#-------------------------------------------" >> $dbfile

ValidCaseCount=0

#------------------------------------------
# Search for subfolders of $BaseRawDir/
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'

CaseFolders=($(find $BaseRawDir/ -mindepth 1 -maxdepth 1 -type d -name "${CASEID}*" | sort -n ))
CaseCount=${#CaseFolders[@]}


if [ $CaseCount -eq 0 ]; then
  echo "Error. No case folder respecting the filter '${CASEID}*' in  <${BaseRawDir}>"
else
  #------------------------------------------------
  # NOW for all folder convert to DICOM
  #------------------------------------------------
  for (( i=0; i<${CaseCount} ; i++ ));
  do
    #------------------------------------------------
    # Get and simplify the directory name
    #------------------------------------------------
    caseD="${CaseFolders[$i]}" 
    caseD=`readlink -f "$caseD"`

    #------------------------------------------------
    # Extract case number
    #------------------------------------------------
    CaseName=`basename ${caseD}`
    CaseNumber="$CaseName"
    if [[ ! -z "${CASEID}" ]]; then
      CaseNumber=`echo "$CaseName" | sed "s/^${CASEID}//g"`
    fi

    echo "Found $CaseNumber ($caseD)"

    #------------------------------------------------
    # Look for patient name
    #------------------------------------------------
    NbPatientNameFolder=($(find $caseD/ -mindepth 1 -maxdepth 1 -type d -name "*" | wc -l ))
    if [[ ${NbPatientNameFolder} -ne 1 ]]; then
      echo "Error. Found ${NbPatientNameFolder} subfolders in <$caseD.>"
      echo "There should be a single folder indicating the patient name."
      echo "IGNORE $caseD"
    else
      PatientFolder=($(find $caseD/ -mindepth 1 -maxdepth 1 -type d -name "*" | head -1 ))
      PatientName=`basename "$PatientFolder"`

      #------------------------------------------------
      # If no error, look for scan name
      #------------------------------------------------
      ScanFolders=($(find $PatientFolder/ -mindepth 1 -maxdepth 1 -type d -name "${SCANID}*" | sort -n ))
      ScanCount=${#ScanFolders[@]}
      if [ $CaseCount -eq 0 ]; then
        echo "Error. No scan folder respecting the filter '${SCANID}*' in  <${PatientFolder}>"
      else
        for (( j=0; j<${ScanCount} ; j++ ));
        do
          scanD="${ScanFolders[$j]}" 
          scanD=`readlink -f "$scanD"`
          
          #------------------------------------------------
          # Extract scan number
          #------------------------------------------------
          ScanNumber=`basename ${scanD}`

          # Remove stuff after "_" in scan names such as scan01_20151021 . stay compatible even if no "_"
          tst2="s/${SCANID}\([0-9]*\).*/\1/"
          ScanNumber=`echo "$ScanNumber" | sed -e "$tst2"`

          if [[ ! -z "${SCANID}" ]]; then
            ScanNumber=`echo "$ScanNumber" | sed "s/^${SCANID}//g"`
          fi
          echo "      $CaseNumber-$ScanNumber ($scanD)"

          if [[ "$opt" != "--noupdate" ]]; then
            sh "$SrcScriptDir/common/DB_UpdateCaseScan.sh" "${CaseNumber}" "${ScanNumber}"
          fi

          echo
        done


        ValidCaseCount=$(( $ValidCaseCount + 1 ))
        str=`printf "Case[%d]=\"%s\"" $ValidCaseCount $BaseProcessedDir/$CaseName/$PatientName `
        echo $str >> $dbfile


      fi
    fi


    echo
  done
fi

echo "CaseCount=$CaseCount" >> $dbfile
IFS=$PREVIFS


mutexUnlockFile "$lockdbfile"


