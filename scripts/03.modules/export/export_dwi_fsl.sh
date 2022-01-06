#!/bin/sh

if [ $# -ne 2 ]; then
  echo "----------------------------------------------------------"
  echo " Export DWI data to the medinria file format"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: MOSEMFM.sh [DWIid] [0:DWI/1:CUSP]"
  echo
  exit 1
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
checkIfVariablesAreSet "${DWIid}_MASKED_NHDR,${DWIid}_DMASKED_NHDR,${DWIid}_DWI_ICC_MASK"





#=========================================================
# Convert the data to the MedINRIA format
#
# OUTPUT:
# - FSL_DATA
# - FSL_B0
# - FSL_VECTORS
# - FSL_BVALUES
# - FSL_MASK
#=========================================================
showStepTitle "Convert data for FSL"

OFOLDER="${folder}/modules/export/${DWIid}/fsl/dwi"
mkdir -p "$OFOLDER"

CACHE_DoStepOrNot "${DWIid}_EXPORT_FSL" 
if [  $? -eq 0 ]; then
  echo "- Use previously computed FSL data."
else
  nhdr="${DWIid}_MASKED_NHDR"
  nhdr=${!nhdr}

  echo "- Convert the RAW diffusion images to FSL file format."
  crlDWIConvertNHDRForFSL -i "$nhdr" --data "${OFOLDER}/data.nii.gz" --b0 "${OFOLDER}/nodif.nii.gz" --bvecs "${OFOLDER}/bvecs" --bvals "${OFOLDER}/bvals"
  exitIfError "crlDWIConvertNHDRForFSL"

  mask="${DWIid}_DWI_ICC_MASK"
  mask=${!mask}
  crlConvertBetweenFileFormats -in "$mask" -out "${OFOLDER}/nodif_brain.nii"

  exportVariable "${DWIid}_FSL_DATA" "${OFOLDER}/data.nii.gz"
  exportVariable "${DWIid}_FSL_B0" "${OFOLDER}/nodif.nii.gz"
  exportVariable "${DWIid}_FSL_VECTORS" "${OFOLDER}/bvecs"
  exportVariable "${DWIid}_FSL_BVALUES" "${OFOLDER}/bvals"
  exportVariable "${DWIid}_FSL_MASK" "${OFOLDER}/nodif_brain.nii"

  CACHE_StepHasBeenDone "${DWIid}_EXPORT_FSL" "$nhdr" "${OFOLDER}/data.nii.gz"
fi
echo ""


CACHE_DoStepOrNot "${DWIid}_EXPORT_DFSL" 
if [  $? -eq 0 ]; then
  echo "- Use previously computed denoised FSL data."
else
  OFOLDER="${folder}/modules/export/${DWIid}/fsl/dwi-denoised"
  mkdir -p "$OFOLDER"

  nhdr="${DWIid}_DMASKED_NHDR"
  nhdr=${!nhdr}

  echo "- Convert the RAW diffusion images to FSL file format."
  crlDWIConvertNHDRForFSL -i "$nhdr" --data "${OFOLDER}/data.nii.gz" --b0 "${OFOLDER}/nodif.nii.gz" --bvecs "${OFOLDER}/bvecs" --bvals "${OFOLDER}/bvals"
  exitIfError "crlDWIConvertNHDRForFSL"

  mask="${DWIid}_DWI_ICC_MASK"
  mask=${!mask}
  crlConvertBetweenFileFormats -in "$mask" -out "${OFOLDER}/nodif_brain.nii"

  setCachedValue "${DWIid}_FSL_DDATA" "${OFOLDER}/data.nii.gz"
  setCachedValue "${DWIid}_FSL_DB0" "${OFOLDER}/nodif.nii.gz"
  setCachedValue "${DWIid}_FSL_DVECTORS" "${OFOLDER}/bvecs"
  setCachedValue "${DWIid}_FSL_DBVALUES" "${OFOLDER}/bvals"
  setCachedValue "${DWIid}_FSL_DMASK" "${OFOLDER}/nodif_brain.nii"

  CACHE_StepHasBeenDone "${DWIid}_EXPORT_DFSL" "$nhdr" "${OFOLDER}/data.nii.gz"
fi
echo ""




