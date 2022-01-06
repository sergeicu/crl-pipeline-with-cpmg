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
  echo "- Not a multi b-value acquisition. Skip this module."
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

#------------------------------------------------- 
# Create output folder
#------------------------------------------------- 
OFOLDER="${folder}/modules/MFM/${DWIid}"
mkdir -p "$OFOLDER"

#-------------------------------------------------
# DIAMOND Estimation
#-------------------------------------------------
showStepTitle "DIAMOND estimation (up to 3 fascicles + iso)"
CACHE_DoStepOrNot "${DWIid}_MODULE_B632DIAMOND_3T" "2.03"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated DIAMOND."
else

  #/project/crlDCIEstimate_2016sep22 # galahad  percival  lancelot
 
  crlDCIEstimate --log -i "$nhdr" --reg 1.00 -t 1 --estimb0 1 -n 3 -o "${OFOLDER}/${prefix}B632DIAMOND_3T.nrrd" -p ${NBTHREADS} --automose aicu --fascicle diamondcyl --verbosedOutput
  exitIfError "crlDCIEstimate"
 
  exportVariable "${DWIid}_B632DIAMOND_3F_T0" "${OFOLDER}/${prefix}B632DIAMOND_3T_t0.nrrd"
  exportVariable "${DWIid}_B632DIAMOND_3F_T1" "${OFOLDER}/${prefix}B632DIAMOND_3T_t1.nrrd"
  exportVariable "${DWIid}_B632DIAMOND_3F_T2" "${OFOLDER}/${prefix}B632DIAMOND_3T_t2.nrrd"
  exportVariable "${DWIid}_B632DIAMOND_3F_F"  "${OFOLDER}/${prefix}B632DIAMOND_3T_fractions.nrrd"
  exportVariable "${DWIid}_B632DIAMOND_3F_MOSEMAP"  "${OFOLDER}/${prefix}B632DIAMOND_3T_mosemap.nrrd"
  exportVariable "${DWIid}_B632DIAMOND_3F_REV"  "$RevisionNumber"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_B632DIAMOND_3T" "$nhdr" "${OFOLDER}/${prefix}B632DIAMOND_3T_t0.nrrd,${OFOLDER}/${prefix}B632DIAMOND_3T_t1.nrrd,${OFOLDER}/${prefix}B632DIAMOND_3T_t2.nrrd,${OFOLDER}/${prefix}B632DIAMOND_3T_fractions.nrrd"
fi
echo ""
