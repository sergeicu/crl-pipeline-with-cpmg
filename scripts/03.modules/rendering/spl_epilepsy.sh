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
checkIfVariablesAreSet "CT,CTtoT1_trsf,T1W_REF,ICC_MASK"

#------------------------------------------
# Prepare Output Folder
#------------------------------------------
showStepTitle "Grids & Strips electrodes segmentation and rendering"
OUTPUTFOLDER="${folder}/modules/rendering/spl_epilepsy"
mkdir -p "${OUTPUTFOLDER}"

#------------------------------------------
# Electrodes Segmentation from CT
#------------------------------------------
CACHE_DoStepOrNot "ELECTRODES_SEGMENTATION"
if [ $? -eq 0 ]; then
  echo "- Use previously computed step."
else
  mkdir -p "$OUTPUTFOLDER/tmp"
  prevdir=`pwd`
  cd "$OUTPUTFOLDER/tmp"

  ## Threshold the CT Th=3000
  crlBinaryThreshold ${CT} CT3000.nrrd 3000 100000000 1 0

  ## Apply "closing" "openign" "dilation" filter on the thresholded CT image 
  crlBinaryMorphology CT3000.nrrd closing 1 1 cCT3000.nrrd
  crlBinaryMorphology cCT3000.nrrd opening 1 1 ocCT3000.nrrd
  crlBinaryMorphology ocCT3000.nrrd dilation 1 1 docCT3000.nrrd

  ## Downsample the result, and make it of the same size as the MRI image
  crlResampler docCT3000.nrrd ${CTtoT1_trsf} ${T1W_REF} nearest rdocCT3000.nrrd

  ## Multiply by the mask
  crlImageAlgebra rdocCT3000.nrrd multiply $ICC_MASK mask_rdocCT3000.nrrd

  ## Connected components
  crlConnectedComponentFilter mask_rdocCT3000.nrrd ../${prefix}electrodes.nrrd 1

  crlCreateTriangleModel ../${prefix}electrodes.nrrd 0.5 ../${prefix}electrodes.vtk

  cd "$prevdir"

  CACHE_StepHasBeenDone "ELECTRODES_SEGMENTATION" "$CT,$CTtoT1_trsf,$T1W_REF,$ICC_MASK" "${OUTPUTFOLDER}/${prefix}electrodes.nrrd,${OUTPUTFOLDER}/${prefix}electrodes.vtk"
  echo

fi
echo ""



####################################################################
#####################################################################
# Take out HD grid
#crlRelabelImages cc_mask_rdocCT3000.nrrd rocCT3000.nrrd 1 1 hd-mask.nrrd 0
#crlRelabelImages hd-mask.nrrd rocCT3000.nrrd 0 0 hd-ele.nrrd
#crlRelabelImages hd-ele.nrrd rocCT3000.nrrd 0 0 hd-electrodes.nrrd 1
#crlCreateTriangleModel hd-ele.nrrd 0.5 hd-ele.vtk
#crlColorSurfaceModelWithSingleValue hd-ele.vtk hd-electrodes.vtk 1000.0 0.0 0.0

#crlRelabelImages cc_mask_rdocCT3000.nrrd rocCT3000.nrrd 4 4 dep-mask.nrrd 0
#crlRelabelImages dep-mask.nrrd rocCT3000.nrrd 0 0 dep-ele.nrrd
#crlRelabelImages dep-ele.nrrd rocCT3000.nrrd 0 0 dep-electrodes.nrrd 4
#crlCreateTriangleModel dep-ele.nrrd 0.5 dep-ele.vtk
#crlColorSurfaceModelWithSingleValue dep-ele.vtk dep-electrodes.vtk 0.0 1000.0 0.0


#crlColorSurfaceModelWithSingleValue inputModelFile outputModelFile R G B

#crlRelabelImages hd-electrodes.nrrd dep-electrodes.nrrd 1 1 hd-dep-electrodes.nrrd


#################################################################################
# apply "closing" filter on the original 
#crlBinaryMorphology CT3000.nrrd closing 1 1 cCT3000.nrrd
#crlBinaryMorphology cCT3000.nrrd opening 1 1 ocCT3000.nrrd
#crlBinaryMorphology ocCT3000.nrrd dilation 1 5 docCT3000.nrrd

# downsample to the MRI size
#crlResampler cCT3000.nrrd daffine.txt mri/c091_t1w_ref.nrrd nearest rocCT3000.nrrd
#crlResampler docCT3000.nrrd daffine.txt mri/c091_t1w_ref.nrrd nearest rdocCT3000.nrrd
#multiply by the mask
#crlImageAlgebra rocCT3000.nrrd multiply c091_ICC.nrrd mask_rocCT3000.nrrd
#crlImageAlgebra rdocCT3000.nrrd multiply c091_ICC.nrrd mask_rdocCT3000.nrrd

# connected components
#crlConnectedComponentFilter mask_rocCT3000.nrrd cc_mask_rocCT3000.nrrd 5
#crlConnectedComponentFilter mask_rdocCT3000.nrrd cc_mask_rdocCT3000.nrrd 1

#crlRelabelImages cc_mask_rocCT3000.nrrd Tumor-Segmentation/Tumor.nrrd 1 1 tumor-electrodes.nrrd
#crlColorSurfaceModelWithSingleValue inputModelFile outputModelFile R G B

# Take out HD grid
#crlCreateTriangleModel cc_mask_rocCT3000.nrrd 0.5 cc_mask_rocCT3000.vtk
#crlCreateTriangleModel hd-dep-electrodes.nrrd 0.5 hd-dep-electrodes.vtk
#crlColorSurfaceModel hd-dep-electrodes.vtk hd-dep-electrodes.nrrd color-hd-dep-electrodes.vtk
#clCreateTriangleModel dep-electrodes.nrrd 0.5 dep-electrodes.vtk
#crlCreateTriangleModel tumor-electrodes.nrrd 0.5 tumor-electrodes.vtk

## Making video
# ffmpeg -r 1 -i cortex%03d.png video.mp4









