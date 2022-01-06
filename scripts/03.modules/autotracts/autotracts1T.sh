function doInitializeAutotracts()
{
  local Rois=$1

  if [[ "$Rois" == "RALPH" ]]; then
    DB_ROI_LIST="CC CS CI OR TR SF"
  elif [[ "$Rois" == "WILL" ]]; then
    DB_ROI_LIST="R-Anterior-AF L-Anterior-AF R-Posterior-AF L-Posterior-AF R-Long-AF L-Long-AF L-UF R-UF"
  else
    echo "ERROR. Invalid ROI argument: $ROIS"
    return 1;
  fi
}

function doInitializeFascicleSelection()
{
  local Fascicle=$1

  if [[ ${Fascicle} == "CC" ]]; then 
    FASCICLE="CC"
    SEED_LABELS="1"
    SELECT_LABELS="1" 
    REJECT_LABELS="10"     
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1"\""" "\"""1"\""")
  elif [[ ${Fascicle} == "CS" ]]; then
    FASCICLE="CS"
    SEED_LABELS="1"
    SELECT_LABELS=$(echo "\"""1 2"\""")
    REJECT_LABELS="10"    
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1 2"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "CI" ]]; then
    FASCICLE="CI"
    SEED_LABELS="1"
    SELECT_LABELS="1" 
    REJECT_LABELS="10"    
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1"\""" "\"""1"\""")
  elif [[ ${Fascicle} == "OR" ]]; then
    FASCICLE="OR"
    SEED_LABELS="1"
    SELECT_LABELS=$(echo "\"""1 6"\""")
    REJECT_LABELS="10"
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1"\""" "\"""1"\""")
  elif [[ ${Fascicle} == "TR" ]]; then
    FASCICLE="TR"
    SEED_LABELS="1"
    SELECT_LABELS="1" 
    REJECT_LABELS="10" 
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1"\""" "\"""1"\""")
  elif [[ ${Fascicle} == "SF" ]]; then
    FASCICLE="SF"
    SEED_LABELS="1"
    SELECT_LABELS="1"
    REJECT_LABELS="10"
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1"\""" "\"""1"\""")
  elif [[ ${Fascicle} == "R-Anterior-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""1 2"\""")
   REJECT_LABELS="3"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""1 2"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "L-Anterior-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""4 5"\""")
   REJECT_LABELS="6"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""4 5"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "R-Posterior-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""2 3"\""")
   REJECT_LABELS="1"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""2 3"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "L-Posterior-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""5 6"\""")
   REJECT_LABELS="4"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""5 6"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "R-Long-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""1 2 3"\""")
   REJECT_LABELS="100000"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""1 2 3"\""" "\"""1 1 1"\""")
  elif [[ ${Fascicle} == "L-Long-AF" ]]; then
   FASCICLE="AFfromdensity"
   SEED_LABELS="1"
   SELECT_LABELS=$(echo "\"""4 5 6"\""")
   REJECT_LABELS="100000"
   TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
   RELABEL=$(echo "\"""4 5 6"\""" "\"""1 1 1"\""")
  elif [[ ${Fascicle} == "R-UF" ]]; then
    FASCICLE="UF"
    SEED_LABELS="1"
    SELECT_LABELS=$(echo "\"""4 2"\""")
    REJECT_LABELS="100000"
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""4 2"\""" "\"""1 1"\""")
  elif [[ ${Fascicle} == "L-UF" ]]; then
    FASCICLE="UF"
    SEED_LABELS="1"
    SELECT_LABELS=$(echo "\"""1 3"\""")
    REJECT_LABELS="100000"
    TRACTOGRAPHY_PARAM="-f 0.2 --famomentum 0.5 -a 35.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1 -p ${NBTHREADS}"
    RELABEL=$(echo "\"""1 3"\""" "\"""1 1"\""")
  fi
}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

#------------------------------------------
# Check some variables
#------------------------------------------
DWIid="$1"
ROIS="$3"
checkIfVariablesAreSet "${DWIid}_RTENSOR_1T"

echo ${ROIS}

tensors="${DWIid}_RTENSOR_1T"
tensors=${!tensors}

#--------------------------------------------------------------
# COMPUTE TRACTS
#--------------------------------------------------------------
OFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/${DWIid}_${ROIS}_1T"
ROIFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/projected-rois_${ROIS}"
mkdir -p "$OFOLDER"

let count=0;

doInitializeAutotracts "${ROIS}"

for roi in $DB_ROI_LIST;
do
  doInitializeFascicleSelection ${roi}

  roifile="$ROIFOLDER/${FASCICLE}-roi.nrrd"
  TENSOR_FILE="$tensors"
  
  #-------------------------------------#
  #---- Select streamlines from wbc ----#
  #-------------------------------------#
  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}"
  if [ $? -eq 0 ]; then
    echo "- Use previously tracts for roi ${roi}."
    echo
  else
    echo "- Generate tracts for roi ${roi}."

    cd "$OFOLDER"

    varname="${DWIid}_RTENSOR_1T"
    varname=${!varname}

    command=$(echo "crlRelabelImages ${roifile} ${roifile} ${RELABEL} ./${roi}-seed.nrrd \"""0"\"" ")
    eval "${command}"
    
    crlMFMTractGenerator \
    -i "${varname}" \
    -r ./${roi}-seed.nrrd \
    -l 1 \
    --select_roi "${roifile}" \
    --select_touch "${SELECT_LABELS}" \
    --select_donttouch "${REJECT_LABELS}" \
    ${TRACTOGRAPHY_PARAM} \
    -o "${OFOLDER}/${roi}-tracts.vtp64" 

    crlTensorToRGB \
    "${varname}" \
    ./rgb-${roi}-tensors.nrrd

    cd "$prevfolder"

    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}" "$roifile" "${OFOLDER}/${roi}-tracts.vtp64"
  fi

  #--------------------------#
  #--- Create RGB tracts ----#
  #--------------------------#
  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_RGBTRACTS"
  if [ $? -eq 0 ]; then
    echo "- Use previously generated RGB autotracts for roi ${roi}."
    echo
  else
    echo "- Generate RGB tracts for roi ${roi}."

    cd "$OFOLDER"

    echo "- Color ${roi}-tracts.vtp64"
    crlColorSurfaceModelWithRGBImage \
      "${OFOLDER}/${roi}-tracts.vtp64" \
      "$OFOLDER/rgb-${roi}-tensors.nrrd" \
      "${OFOLDER}/rgb-${roi}-tracts.vtp64"

    cd "$prevfolder"
    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_RGBTRACTS" "${OFOLDER}/${roi}-tracts.vtp64" "${OFOLDER}/rgb-${roi}-tracts.vtp64"
  fi

  #---------------------------------------------#
  #---- Create scalar density weighted maps ----#
  #---------------------------------------------#
  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_DWEIGHTSTATS" "1.01"
  if [  $? -eq 0 ]; then
    echo "- Use previously estimated density weighted scalar parameters."
    echo
  else
    cd "$OFOLDER"
    mkdir -p tmp
    cd tmp

    echo "- Tract density for ${roi}-tracts.vtp64"

    roifile="$ROIFOLDER/${FASCICLE}-roi.nrrd"
    thisout=${OFOLDER}/${prefix}${roi}-stats.txt
    crlTractDensity ${OFOLDER}/${roi}-tracts.vtp64 ${roifile} $OFOLDER/tmp/${roi}-density.nrrd $OFOLDER/tmp/${roi}-tracts-density.vtk
    (
    for stat in MD FA RD AD
    do
      echo -n "$stat " 1>&4 
      scalarmap=`dirname $tensors`/`basename $tensors .nrrd`_${stat}.nrrd
      crlDensityWeightedStats 1>&4 ${roi}-density.nrrd $scalarmap
    done
    ) 4>$thisout

    cd "$prevfolder"

    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_DWEIGHTSTATS" "${OFOLDER}/${roi}-tracts.vtp64,${roifile}" "${OFOLDER}/${prefix}${roi}-stats.txt"
  fi

done

