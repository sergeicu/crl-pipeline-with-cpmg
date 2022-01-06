#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " B632 MOSE + DIAMOND 3 Fibers, high resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2013"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: B632DIAMOND_3T.sh [DWIid] [0:DWI/1:CUSP]"
  echo
  exit 1
fi

if [ $2 -ne 1 ]; then
  echo "- Not a CUSP acquisition. Skip this module."
  exit 0
fi


#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

DWIid="$1"

#------------------------------------------
# Check some variables
#------------------------------------------
checkIfVariablesAreSet "${DWIid}_RMASKED_NHDR"

#-------------------------------------------------
# Get the High Resolution NHDR (resampled)
#------------------------------------------------- 
nhdr="${DWIid}_RMASKED_NHDR"
nhdr=${!nhdr}
if [ -z "$nhdr" ] || [ ! -f "$nhdr" ]; then
  echo "FATAL ERROR. Invalid file <$nhdr.>"
  exit 1
fi

#------------------------------------------------- 
# Check revision number
#------------------------------------------------- 
RevisionNumber=`crlDCIEstimate 2>&1 | grep REVISION | cut -f2 -d:`
if [[ $RevisionNumber -lt 8 ]]; then
  errorAndExit "Invalid revision number for crlDCIEstimate. Must be >=8"
fi

OFOLDER="${folder}/modules/MFM/${DWIid}"
mkdir -p "$OFOLDER"


#-------------------------------------------------
# DIAMOND Estimation
#-------------------------------------------------
showStepTitle "DIAMOND estimation (1 fascicle + iso)"
CACHE_DoStepOrNot "${DWIid}_MODULE_DIAMOND_1T" "2.03"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated DIAMOND."
else

  
  crlDCIEstimate --log -i "$nhdr" --reg 1.00 -t 1 --automose aicu --fascicle diamond --waterfraction 1 --estimb0 1 -n 1 -o "${OFOLDER}/${prefix}DIAMOND_1T.nrrd" -p ${NBTHREADS}  --verbosedOutput
  exitIfError "crlDCIEstimate"
  
  exportVariable "${DWIid}_DIAMOND_1F_T0" "${OFOLDER}/${prefix}DIAMOND_1T_t0.nrrd"
  exportVariable "${DWIid}_DIAMOND_1F_F"  "${OFOLDER}/${prefix}DIAMOND_1T_fractions.nrrd"
  exportVariable "${DWIid}_DIAMOND_1F_MOSEMAP"  "${OFOLDER}/${prefix}DIAMOND_1T_mosemap.nrrd"
  exportVariable "${DWIid}_DIAMOND_1F_REV"  "$RevisionNumber"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_DIAMOND_1T" "$nhdr" "${OFOLDER}/${prefix}DIAMOND_1T_t0.nrrd,${OFOLDER}/${prefix}DIAMOND_1T_fractions.nrrd"
fi
echo ""
