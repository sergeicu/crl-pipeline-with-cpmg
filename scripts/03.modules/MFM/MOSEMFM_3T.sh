#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " MOSE + MFM 3 Fibers, high resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2012"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: MOSEMFM_3T.sh [DWIid] [0:DWI/1:CUSP]"
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

OFOLDER="${folder}/modules/MFM/${DWIid}"
mkdir -p "$OFOLDER"

#------------------------------------------------- 
# Check revision number
#------------------------------------------------- 
RevisionNumber=`crlDCIEstimate 2>&1 | grep REVISION | cut -f2 -d:`
if [[ $RevisionNumber -lt 8 ]]; then
  errorAndExit "Invalid revision number for crlDCIEstimate. Must be >=8"
fi

#-------------------------------------------------
# MFM Estimation
#-------------------------------------------------
showStepTitle "3Fibers Estimation"
CACHE_DoStepOrNot "${DWIid}_MODULE_MOSEMFM_3T" "1.2"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated MFM."
else
 
  crlDCIEstimate --log -i "$nhdr" --reg 1 -t 1 --estimb0 1 -n 3 -o "${OFOLDER}/${prefix}MOSEMFM_3T.nrrd" -p ${NBTHREADS} --automose aicu
  exitIfError "crlDCIEstimate"

  exportVariable "${DWIid}_MOSEMFM_3F_T0" "${OFOLDER}/${prefix}MOSEMFM_3T_t0.nrrd"
  exportVariable "${DWIid}_MOSEMFM_3F_T1" "${OFOLDER}/${prefix}MOSEMFM_3T_t1.nrrd"
  exportVariable "${DWIid}_MOSEMFM_3F_T2" "${OFOLDER}/${prefix}MOSEMFM_3T_t2.nrrd"
  exportVariable "${DWIid}_MOSEMFM_3F_F"  "${OFOLDER}/${prefix}MOSEMFM_3T_fractions.nrrd"
  exportVariable "${DWIid}_MOSEMFM_3F_REV"  "$RevisionNumber"



  CACHE_StepHasBeenDone "${DWIid}_MODULE_MOSEMFM_3T" "$nhdr" "${OFOLDER}/${prefix}MOSEMFM_3T_t0.nrrd,${OFOLDER}/${prefix}MOSEMFM_3T_t1.nrrd,${OFOLDER}/${prefix}MOSEMFM_3T_t2.nrrd,${OFOLDER}/${prefix}MOSEMFM_3T_fractions.nrrd"
fi
echo ""
