#=================================================================
# AUTOMATED TRACTS PIPELINE
# pipeline scripts: Neil Weisenfeld, 2011
# methodology scripts: Ralph Suarez, 2011
#-----------------------------------------------------------------
# 
#=================================================================

DB_SUBJECTS_LIST="007 008 009 011 014 015 020 021 023 024 025 027 029 036 039"
DB_TEMPLATE_FOLDER="/common/data/processed/atlases/tracttemplates/structural"

DWIid="$1"
ROIS="$3"

if [ "$ROIS"=="RALPH" ]; then
  DB_ROI_FOLDER="/common/data/processed/atlases/tracttemplates/ralph_roi"
  DB_ROI_LIST="CC CS CI OR TR SF"
else
  echo "ERROR. Invalid ROI argument: $ROIS"
  return 1;
fi



# $1 : ${DWIid}

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
checkIfVariablesAreSet "${DWIid}_RTENSOR_1T"

tensors="${DWIid}_RTENSOR_1T"
tensors=${!tensors}

#--------------------------------------------------------------
# COMPUTE TRACTS
#--------------------------------------------------------------
OFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/${DWIid}_${ROIS}_1T"
ROIFOLDER="$ScanProcessedDir/common-processed/modules/autotracts/projected-rois_${ROIS}/"
mkdir -p "$OFOLDER"

let count=0;

for roi in $DB_ROI_LIST;
do
  roifile="$ROIFOLDER/${roi}-roi.nrrd"
  TENSOR_FILE="$tensors"

  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}"
  if [ $? -eq 0 ]; then
    echo "- Use previously tracts for roi ${roi}."
    echo
  else
    echo "- Generate tracts for roi ${roi}."

    cd "$OFOLDER"


    # make tracts from new rois file
    if [ "${roi}" == CS ]; then 
      echo "using CS bundle strategy for roi: ${roi}"; 
      echo "RUNNING crlTractGenerator";

      crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r $roifile \
    -l 1 -l 2 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

      crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    $roifile \
    -d "10" -t "1 2" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;




    elif [ "${roi}" == OR ]; then 
      echo "using OR bundle strategy for roi: ${roi}";
      echo "RUNNING crlTractGenerator";

     crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r $roifile \
    -l 1 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

     crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    $roifile \
    -d "10" -t "6" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;

    else 
      echo "using the default bundle strategy for roi: ${roi}";
      echo "RUNNING crlTractGenerator";

     crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r $roifile \
    -l 1 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

     crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    $roifile \
    -d "10" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;

    fi


    # get rid of unselected tract file
    rm ./${roi}-tracts-unsel.vtk    

    cd "$prevfolder"

    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}" "$roifile" "${OFOLDER}/${roi}-tracts.vtk"
  fi

done

#-------------------------------------------
# Create RGB image
#-------------------------------------------
showStepTitle "Compute RGB tensor image"
CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_RGB"
if [ $? -eq 0 ]; then
  echo "- Use previously generated RGB image."
  echo
else
  echo "- Generate RGB image."
  crlTensorToRGB "$tensors" "$OFOLDER/rgb-tensors.nrrd"
  CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_RGB" "$tensors" "$OFOLDER/rgb-tensors.nrrd"
fi

#-------------------------------------------
# Create RGB tracts for each ROI
#-------------------------------------------
showStepTitle "Colorize tracts"
for roi in $DB_ROI_LIST;
do
  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_RGBTRACTS"
  if [ $? -eq 0 ]; then
    echo "- Use previously generated RGB autotracts for roi ${roi}."
    echo
  else
    echo "- Generate RGB tracts for roi ${roi}."

    cd "$OFOLDER"

    echo "- Color ${roi}-tracts.vtk"
    crlColorSurfaceModelWithRGBImage "${OFOLDER}/${roi}-tracts.vtk" "$OFOLDER/rgb-tensors.nrrd" "${OFOLDER}/rgb-${roi}-tracts.vtk"

    cd "$prevfolder"
    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_RGBTRACTS" "${OFOLDER}/${roi}-tracts.vtk" "${OFOLDER}/rgb-${roi}-tracts.vtk"
  fi
done

#-------------------------------------------
# Create Scalar Density Weighted Maps
#-------------------------------------------
showStepTitle "Compute density weighted scalar paramaters"
for roi in $DB_ROI_LIST;
do
  CACHE_DoStepOrNot "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_DWEIGHTSTATS" "1.01"
  if [  $? -eq 0 ]; then
    echo "- Use previously estimated density weighted scalar parameters."
    echo
  else
    cd "$OFOLDER"
    mkdir -p tmp
    cd tmp


    echo "- Tract density for ${roi}-tracts.vtk"

    thisout=${OFOLDER}/${prefix}${roi}-stats.txt
    crlTractDensity ${OFOLDER}/${roi}-tracts.vtk ${OFOLDER}/../projected-rois_${ROIS}/${roi}-roi.nrrd $OFOLDER/tmp/${roi}-density.nrrd $OFOLDER/tmp/${roi}-tracts.vtk
    (
    for stat in MD FA RD AD
    do
      echo -n "$stat " 1>&4 
      scalarmap=`dirname $tensors`/`basename $tensors .nrrd`_${stat}.nrrd
      crlDensityWeightedStats 1>&4 ${roi}-density.nrrd $scalarmap
    done
    ) 4>$thisout

    cd "$prevfolder"

    CACHE_StepHasBeenDone "${DWIid}_AUTOTRACT_${ROIS}_1T_R${roi}_DWEIGHTSTATS" "${OFOLDER}/${roi}-tracts.vtk,${OFOLDER}/../projected-rois_${ROIS}/${roi}-roi.nrrd" "${OFOLDER}/${prefix}${roi}-stats.txt"
  fi
done

