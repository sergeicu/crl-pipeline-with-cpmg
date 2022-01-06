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
checkIfVariablesAreSet "${DWIid}_MASKED_NHDR,${DWIid}_DMASKED_NHDR"


#=========================================================
# Convert the data to the MedINRIA format
#
# OUTPUT:
# - MEDINRIA_DTI
# - MEDINRIA_FODF
#=========================================================
showStepTitle "Convert data for MedINRIA"

OFOLDER="${folder}/modules/export/${DWIid}/medinria"
mkdir -p "$OFOLDER"

CACHE_DoStepOrNot "${DWIid}_EXPORT_MEDINRIA" 
if [  $? -eq 0 ]; then
  echo "- Use previously computed MedINRIA data."
else
  OFOLDER1="$DWIProcessedDir/06-export/medinria/dti"
  mkdir -p "$OFOLDER1"
  OFOLDER2="$DWIProcessedDir/06-export/medinria/dti-denoised"
  mkdir -p "$OFOLDER2"
  OFOLDER3="$DWIProcessedDir/06-export/medinria/odf"
  mkdir -p "$OFOLDER3"
  OFOLDER4="$DWIProcessedDir/06-export/medinria/odf-denoised"
  mkdir -p "$OFOLDER4"

  nhdr="${DWIid}_MASKED_NHDR"
  nhdr=${!nhdr}
  dnhdr="${DWIid}_DMASKED_NHDR"
  dnhdr=${!dnhdr}

  echo "- Create the MedINRIA RAW diffusion study file for DTI processing"
  crlDWIConvertNHDRForMedINRIA -i "$nhdr" -o "${OFOLDER1}/${prefix}diffusion-dti.dts" -t
  exitIfError "crlDWIConvertNHDRForMedINRIA"
  crlDWIConvertNHDRForMedINRIA -i "$dnhdr" -o "${OFOLDER2}/${prefix}ddiffusion-dti.dts" -t
  exitIfError "crlDWIConvertNHDRForMedINRIA"
 
  echo "- Create the MedINRIA RAW diffusion study file for ODF processing"
  crlDWIConvertNHDRForMedINRIA -i "$nhdr" -o "${OFOLDER3}/${prefix}diffusion-fodf.dts"
  exitIfError "crlDWIConvertNHDRForMedINRIA"
  crlDWIConvertNHDRForMedINRIA -i "$dnhdr" -o "${OFOLDER4}/${prefix}ddiffusion-fodf.dts"
  exitIfError "crlDWIConvertNHDRForMedINRIA"
 
  exportVariable "${DWIid}_MEDINRIA_DTI" "${OFOLDER1}/${prefix}diffusion-dti.dts"
  exportVariable "${DWIid}_MEDINRIA_FODF" "${OFOLDER3}/${prefix}diffusion-fodf.dts"
  exportVariable "${DWIid}_MEDINRIA_DDTI" "${OFOLDER2}/${prefix}ddiffusion-dti.dts"
  exportVariable "${DWIid}_MEDINRIA_DFODF" "${OFOLDER4}/${prefix}ddiffusion-fodf.dts"

  CACHE_StepHasBeenDone "${DWIid}_EXPORT_MEDINRIA" "$nhdr" "${OFOLDER1}/${prefix}diffusion-dti.dts,${OFOLDER3}/${prefix}diffusion-fodf.dts,${OFOLDER2}/${prefix}ddiffusion-dti.dts,${OFOLDER4}/${prefix}ddiffusion-fodf.dts"
fi
echo ""
