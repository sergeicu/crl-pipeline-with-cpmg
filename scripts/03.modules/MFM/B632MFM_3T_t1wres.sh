#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " B632 MOSE + MFM 3 Fibers, high resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2013"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: B632MFM_3T.sh [DWIid] [0:DWI/1:CUSP]"
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
# MFM Estimation
#-------------------------------------------------
showStepTitle "3Fibers MFM estimation"
CACHE_DoStepOrNot "${DWIid}_MODULE_B632MFM_3T" "1.4"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated MFM."
else
 
  crlDCIEstimate --log -i "$nhdr" --reg 1 -t 1 --estimb0 1 -n 3 -o "${OFOLDER}/${prefix}MFM_T1WRES_3T.nrrd" -p ${NBTHREADS} --automose aicu --mosemodels --mosedebugiters --verbosedOutput
  exitIfError "crlDCIEstimate"

  exportVariable "${DWIid}_B632MFM_3F_T0" "${OFOLDER}/${prefix}MFM_T1WRES_3T_t0.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_T1" "${OFOLDER}/${prefix}MFM_T1WRES_3T_t1.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_T2" "${OFOLDER}/${prefix}MFM_T1WRES_3T_t2.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_F"  "${OFOLDER}/${prefix}MFM_T1WRES_3T_fractions.nrrd"
  exportVariable "${DWIid}_B632MFM_3F_MOSEMAP"  "${OFOLDER}/${prefix}MFM_T1WRES_3T_mosemap.nrrd"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_B632MFM_3T" "$nhdr" "${OFOLDER}/${prefix}MFM_T1WRES_3T_t0.nrrd,${OFOLDER}/${prefix}MFM_T1WRES_3T_t1.nrrd,${OFOLDER}/${prefix}MFM_T1WRES_3T_t2.nrrd,${OFOLDER}/${prefix}MFM_T1WRES_3T_fractions.nrrd"
fi
echo ""
