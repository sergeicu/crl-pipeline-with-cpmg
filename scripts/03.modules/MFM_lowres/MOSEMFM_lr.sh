#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " MOSE + MFM, low resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: MOSEMFM_lr.sh [DWIid] [0:DWI/1:CUSP]"
  echo
  exit 1
fi

if [ $2 -ne 1 ]; then
  echo "- Not a CUSP acquisition. Skip."
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
checkIfVariablesAreSet "${DWIid}_MASKED_NHDR,${DWIid}_TENSOR_1T"

#-------------------------------------------------
# Get the Low Resolution NHDR (not resampled)
#------------------------------------------------- 
nhdr="${DWIid}_MASKED_NHDR"
nhdr=${!nhdr}
if [ -z "$nhdr" ] || [ ! -f "$nhdr" ]; then
  echo "FATAL ERROR. Invalid file <$nhdr.>"
  exit 1
fi

OFOLDER="${folder}/modules/MFM_lowres/${DWIid}"
mkdir -p "$OFOLDER"

#-------------------------------------------------
# 2T estimation
#-------------------------------------------------
showStepTitle "MOSE + 2T tensor estimation (LR)"
CACHE_DoStepOrNot "${DWIid}_MODULE_MOSEMFMLR" "1.1"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated tensors."
else
  t1T="${DWIid}_TENSOR_1T"
  t1T=${!t1T}  

  crlMFMEstimate --log -i "$nhdr" -t 1 --estimb0 -n 2 --waterfraction --maxpasses 10 --reg 1 -o "${OFOLDER}/${prefix}MOSE-MFM-2T.nrrd" --cylinders  --automose b632 --mosethreshold 5 --moseiter 20 -p "${NBTHREADS}"
  exitIfError "crlMFMEstimate"

  exportVariable "${DWIid}_LRMOSEMFM_T0" "${OFOLDER}/${prefix}MOSE-MFM-2T_t0.nrrd"
  exportVariable "${DWIid}_LRMOSEMFM_T1" "${OFOLDER}/${prefix}MOSE-MFM-2T_t1.nrrd"
  exportVariable "${DWIid}_LRMOSEMFM_F" "${OFOLDER}/${prefix}MOSE-MFM-2T_fractions.nrrd"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_MOSEMFMLR" "$nhdr" "${OFOLDER}/${prefix}MOSE-MFM-2T_t0.nrrd,${OFOLDER}/${prefix}MOSE-MFM-2T_t1.nrrd,${OFOLDER}/${prefix}MOSE-MFM-2T_fractions.nrrd"
fi
echo ""
