#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " MOSE + MFM, high resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: MOSEMFM.sh [DWIid] [0:DWI/1:CUSP]"
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
checkIfVariablesAreSet "${DWIid}_RMASKED_NHDR,${DWIid}_RTENSOR_1T"

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
# 2T estimation
#-------------------------------------------------
showStepTitle "MOSE + 2T tensor estimation"
CACHE_DoStepOrNot "${DWIid}_MODULE_MOSEMFMHR" "1.1"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated tensors."
else
  t1T="${DWIid}_RTENSOR_1T"
  t1T=${!t1T}  

  crlDCIEstimate --log -i "$nhdr" -n 2 -t 1 --estimb0 1 --reg 1 -o "${OFOLDER}/${prefix}MOSE-MFM-2T.nrrd" --automose aicu -p "${NBTHREADS}"
  exitIfError "crlDCIEstimate"

  exportVariable "${DWIid}_MOSEMFM_T0" "${OFOLDER}/${prefix}MOSE-MFM-2T_t0.nrrd"
  exportVariable "${DWIid}_MOSEMFM_T1" "${OFOLDER}/${prefix}MOSE-MFM-2T_t1.nrrd"
  exportVariable "${DWIid}_MOSEMFM_F" "${OFOLDER}/${prefix}MOSE-MFM-2T_fractions.nrrd"


  CACHE_StepHasBeenDone "${DWIid}_MODULE_MOSEMFMHR" "$nhdr" "${OFOLDER}/${prefix}MOSE-MFM-2T_t0.nrrd,${OFOLDER}/${prefix}MOSE-MFM-2T_t1.nrrd,${OFOLDER}/${prefix}MOSE-MFM-2T_fractions.nrrd"
fi
echo ""
