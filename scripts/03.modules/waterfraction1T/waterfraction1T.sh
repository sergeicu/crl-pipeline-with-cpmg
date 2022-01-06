#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " 1T + WaterFraction, high resolution module"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: waterfraction1T.sh [DWIid] [0:DWI/1:CUSP]"
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

OFOLDER="${folder}/modules/WaterFraction1T/${DWIid}"
mkdir -p "$OFOLDER"

#-------------------------------------------------
# Water fraction and coefficient estimation
#-------------------------------------------------
showStepTitle "1T+WaterFraction estimation"
CACHE_DoStepOrNot "${DWIid}_MODULE_WFRACTION1T" "1.11"
if [  $? -eq 0 ]; then
  echo "- Use previously estimated tensors."
else
  t1T="${DWIid}_RTENSOR_1T"
  t1T=${!t1T}  

  crlDCIEstimate --log -i "$nhdr" --reg 1 -t 1 --fascicle tensor --waterfraction 1 --estimb0 1 -n 1 -o "${OFOLDER}/${prefix}WaterFraction1T.nrrd" -p ${NBTHREADS}
  exitIfError "crlDCIEstimate"

  exportVariable "${DWIid}_WF1T_T" "${OFOLDER}/${prefix}WaterFraction1T_t0.nrrd"
  exportVariable "${DWIid}_WF1T_F" "${OFOLDER}/${prefix}WaterFraction1T_fractions.nrrd"
  exportVariable "${DWIid}_WF1T_C" "${OFOLDER}/${prefix}WaterFraction1T_twater.nrrd"

  CACHE_StepHasBeenDone "${DWIid}_MODULE_WFRACTION1T" "$nhdr" "${OFOLDER}/${prefix}WaterFraction1T_t0.nrrd,${OFOLDER}/${prefix}WaterFraction1T_fractions.nrrd"
fi
echo ""
