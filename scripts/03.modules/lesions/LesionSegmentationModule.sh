#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

#------------------------------#
#---- Check some variables ----#
#------------------------------#
checkIfVariablesAreSet "T1W_REF,T2W_REF,ICC_MASK"

showStepTitle "Lesion Segmentation"

OFOLDER="${folder}/modules/LesionSegmentation"
mkdir -p "$OFOLDER/tmpDir"

if [[ "$1" == "MS" ]]; then
  echo "Lesion Type is set to MS"
  LESIONTYPE="0"
  THRESHOLD="0.3"
  BRAINPARENCHYMA="1 3"
  CSF="2 4"
elif [[ "$1" == "TSC" ]]; then
  echo "Lesion Type is set to TSC"
  LESIONTYPE="1"
  THRESHOLD="0.3"
  BRAINPARENCHYMA="1 3"
  CSF="2 4"
fi

CACHE_DoStepOrNot "LESION_SEGMENTATION"
if [ $? -eq 0 ]; then
  echo "- Use previously computed Lesion Segmentation."
else
  #------------------------------------------------------#
  #---- Align Reference Population to Target Subject ----#
  #------------------------------------------------------#
  if [[ -f ${FLAIR_REF_MASKED} ]] ; then
    sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentScalar.sh "RefinedICC" "${FLAIR_REF}" "flair"
  else
    sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentScalar.sh "RefinedICC" "${T1W_REF}" "t1w"
  fi
  
  #----------------------------------------------#
  #---- Prepare Aligned Reference Population ----#
  #----------------------------------------------#
  source $ScriptDir/common/PipelineUtils.txt || exit 1
  source $ScriptDir/common/PipelineInit.txt || exit 1

  rm ${OFOLDER}/*.txt
  for i in `seq 1 ${RefinedICC_TEMPLATE_NUMBER}`; do
    num=$( printf %03d ${i})

    #---- Flair sequence is available? ----#
    if [[ -f ${FLAIR_REF_MASKED} ]] ; then
      crlConstructVectorImage ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t1w.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t2w.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-flair.nrrd ${OFOLDER}/tmpDir/r-c${num}-vectorimage.nrrd
      #cp ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd
      crlModifyIntensityAndSegmentationUsingNonDiffeomorphicMatching -p ${NBTHREADS} -X 2 -Y 2 -Z 2 -m "${ICC_MASK}" -x 2 -y 2 -z 2 -o ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-flair.nrrd -O ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd -T "${FLAIR_REF_MASKED}" -A ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-flair.nrrd -L "${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd"
    else
      crlConstructVectorImage ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t1w.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t2w.nrrd ${OFOLDER}/tmpDir/r-c${num}-vectorimage.nrrd
      crlModifyIntensityAndSegmentationUsingNonDiffeomorphicMatching -p ${NBTHREADS} -X 2 -Y 2 -Z 2 -m "${ICC_MASK}" -x 2 -y 2 -z 2 -o ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-t1w.nrrd -O ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd -T "${T1W_REF_MASKED}" -A ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t1w.nrrd -L "${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd"
      #cp ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd
    fi    

    crlRelabelImages ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd "1 7 9 10 11 12 13 14" "1 1 1 1 1 1 1 1" ${OFOLDER}/tmpDir/r-c${num}-gm.nrrd "0"
    crlRelabelImages ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-multilabel.nrrd "2" "1" ${OFOLDER}/tmpDir/r-c${num}-ventricles.nrrd "0"
    crlRelabelImages ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd "3 5 6 8" "1 1 1 1" ${OFOLDER}/tmpDir/r-c${num}-wm.nrrd "0"
    crlRelabelImages ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/wr-c${num}-multilabel.nrrd "4" "1" ${OFOLDER}/tmpDir/r-c${num}-csf.nrrd "0"
    
    crlConstructVectorImage ${OFOLDER}/tmpDir/r-c${num}-gm.nrrd ${OFOLDER}/tmpDir/r-c${num}-ventricles.nrrd ${OFOLDER}/tmpDir/r-c${num}-wm.nrrd ${OFOLDER}/tmpDir/r-c${num}-csf.nrrd ${OFOLDER}/tmpDir/r-c${num}-tissues.nrrd
 
    rm ${OFOLDER}/tmpDir/r-c${num}-gm.nrrd ${OFOLDER}/tmpDir/r-c${num}-ventricles.nrrd ${OFOLDER}/tmpDir/r-c${num}-wm.nrrd ${OFOLDER}/tmpDir/r-c${num}-csf.nrrd 

    echo ${OFOLDER}/tmpDir/r-c${num}-vectorimage.nrrd >> ${OFOLDER}/ReferencePopulation.txt
    echo ${OFOLDER}/tmpDir/r-c${num}-tissues.nrrd >> ${OFOLDER}/ReferencePopulationLabels.txt
  done

  if [[ -f ${FLAIR_REF_MASKED} ]] ; then
    crlMOPS -p ${NBTHREADS} -t 1e-6 -I 100 -r 12 -s 1 -R 2 -S 1 -o "${OFOLDER}/${prefix}" -M "${ICC_MASK}" -i "${T1W_REF_MASKED}" -i "${T2W_REF_MASKED}" -i "${FLAIR_REF_MASKED}" -L "${OFOLDER}/ReferencePopulationLabels.txt" -P "${OFOLDER}/ReferencePopulation.txt" -l ${THRESHOLD} -c "${CSF}" -b "${BRAINPARENCHYMA}"
  else
    crlMOPS -p ${NBTHREADS} -t 1e-6 -I 100 -r 12 -s 1 -R 2 -S 1 -o "${OFOLDER}/${prefix}" -M "${ICC_MASK}" -i "${T1W_REF_MASKED}" -i "${T2W_REF_MASKED}" -L "${OFOLDER}/ReferencePopulationLabels.txt" -P "${OFOLDER}/ReferencePopulation.txt" -l ${THRESHOLD} -c "${CSF}" -b "${BRAINPARENCHYMA}"
  fi
  

  crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "5" "1" "${OFOLDER}/${prefix}LesionSegmentation.nrrd" "0"
  crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "0 1 2 3 4" "1 1 1 1 1" "${OFOLDER}/${prefix}NotLesions.nrrd" "0"
  crlBinaryMorphology "${OFOLDER}/${prefix}NotLesions.nrrd" closing 1 1 "${OFOLDER}/c-${prefix}NotLesions.nrrd"
  crlRelabelImages "${OFOLDER}/c-${prefix}NotLesions.nrrd" "${OFOLDER}/c-${prefix}NotLesions.nrrd" "1" "0" "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" "1"
  crlImageAlgebra "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" multiply "${OFOLDER}/${prefix}LesionSegmentation.nrrd" "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd"
  crlBinaryMorphology "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" dilate 1 4 "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd"
  crlImageAlgebra "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" multiply "${OFOLDER}/${prefix}LesionSegmentation.nrrd" "${OFOLDER}/${prefix}LesionSegmentation.nrrd"
  rm "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" "${OFOLDER}/${prefix}NotLesions.nrrd"
  rm -r ${RefinedICC_ALIGNED_REFERENCE_FOLDER}

  exportVariable "LESION_SEGMENTATION_IMG" "${OFOLDER}/${prefix}LesionSegmentation.nrrd"
  
  CACHE_StepHasBeenDone "LESION_SEGMENTATION" "${T1W_REF},${ICC_MASK}" "${OFOLDER}/${prefix}LesionSegmentation.nrrd"
fi

crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "1 2 3 5" "0 0 0 0" "${OFOLDER}/tmpDir/${prefix}BrainMask.nrrd" "1"
crlConnectedComponentFilter "${OFOLDER}/tmpDir/${prefix}BrainMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}BrainMask.nrrd" 10
crlImageAlgebra "${OFOLDER}/tmpDir/c-${prefix}BrainMask.nrrd" multiply "${T1W_REF_MASKED}" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd"
crlMultipleOtsuMaskMaker -o "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" 2
crlRelabelImages "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "1" "1" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "0"
crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "0" "1" "${OFOLDER}/tmpDir/${prefix}BackgroundMask.nrrd" "0"
crlImageAlgebra "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" add "${OFOLDER}/tmpDir/${prefix}BackgroundMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd"
crlConnectedComponentFilter "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" 10
crlRelabelImages "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "0 1" "0 0" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "1"
crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "0 1 2 3 4" "1 1 1 1 1" "${OFOLDER}/${prefix}NotLesions.nrrd" "0"
crlImageAlgebra "${OFOLDER}/${prefix}NotLesions.nrrd" subtract "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/${prefix}NotLesions.nrrd"
crlRelabelImages "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "${OFOLDER}/${prefix}TissueSegmentation.nrrd" "5" "1" "${OFOLDER}/tmpDir/${prefix}OriginalLesionMask.nrrd" "0"
crlImageAlgebra "${OFOLDER}/tmpDir/${prefix}OriginalLesionMask.nrrd" add "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd"

crlBinaryMorphology "${OFOLDER}/${prefix}NotLesions.nrrd" closing 1 1 "${OFOLDER}/c-${prefix}NotLesions.nrrd"
crlRelabelImages "${OFOLDER}/c-${prefix}NotLesions.nrrd" "${OFOLDER}/c-${prefix}NotLesions.nrrd" "1" "0" "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" "1"
crlImageAlgebra "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" multiply "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd"
crlBinaryMorphology "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" dilate 1 4 "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd"
crlBinaryMorphology "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" closing 1 1 "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd"
crlImageAlgebra "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" multiply "${OFOLDER}/tmpDir/c-${prefix}LesionMask.nrrd" "${OFOLDER}/${prefix}LesionSegmentation.nrrd"

rm "${OFOLDER}/c-${prefix}NotLesions-Mask.nrrd" "${OFOLDER}/${prefix}NotLesions.nrrd" "${OFOLDER}/c-${prefix}NotLesions.nrrd"
#rm -r "${RefinedICC_ALIGNED_REFERENCE_FOLDER}"

#--------------------------------------#
#---- GENERATE LESION COUNT REPORT ----#
#--------------------------------------#


#---- Check if NMM Parcellation had been computed ----#
#------------ If not run NMM Parcellation ------------#
#CACHE_DoStepOrNot "NMM_BRAIN_PARCELLATION"
#if [ $? -eq 0 ]; then
#  echo "- Use previously computed NMM parcellation."
#else
#  sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentScalar.sh "NMM" "${T1W_REF}" "t1w"
#  sh ${ScriptDir}/03.modules/parcellation/BrainParcellation.sh "NMM"
#fi


#source $ScriptDir/common/PipelineUtils.txt || exit 1
#source $ScriptDir/common/PipelineInit.txt || exit 1

#showStepTitle "Lesion Report Generation"

#checkIfVariablesAreSet "LESION_SEGMENTATION_IMG"

#CACHE_DoStepOrNot "LESION_REPORT"
#if [ $? -eq 0 ]; then
#  echo "- Use previously computed Lesion Report"
#else
  #---- Then create lesion count report ----#
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "54 58" "1 1" ${OFOLDER}/tmpDir/${prefix}L-Frontal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "27 59" "1 1" ${OFOLDER}/tmpDir/${prefix}R-Frontal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "62 56" "1 1" ${OFOLDER}/tmpDir/${prefix}L-Parietal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "63 29" "1 1" ${OFOLDER}/tmpDir/${prefix}R-Parietal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "60 55" "1 1" ${OFOLDER}/tmpDir/${prefix}L-Occipital-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "61 28" "1 1" ${OFOLDER}/tmpDir/${prefix}R-Occipital-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "57 64" "1 1" ${OFOLDER}/tmpDir/${prefix}L-Temporal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "65 30" "1 1" ${OFOLDER}/tmpDir/${prefix}R-Temporal-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "43" "1" ${OFOLDER}/tmpDir/${prefix}L-Insula-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "19" "1" ${OFOLDER}/tmpDir/${prefix}R-Insula-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "38 37" "1 1" ${OFOLDER}/tmpDir/${prefix}L-Cerebellum-Lobe.nrrd "0"
#  crlRelabelImages ${PARCELLATION_NMM} ${PARCELLATION_NMM} "14 13" "1 1" ${OFOLDER}/tmpDir/${prefix}R-Cerebellum-Lobe.nrrd "0"

#  rm ${OFOLDER}/*.csv

#  crlCreateNullImageFromImage ${T1W_REF} ${OFOLDER}/LesionSegmentationPerLobe.nrrd

  #---- Calculate Voxel Volume ----#
#  s=`crlImageInfo "${T1W_REF}" | grep Spacing`
#  s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`
#  sx=`echo "$s" | sed -e "s/\([0-9.]*\).*/\1/"`
#  sy=`echo "$s" | sed -e "s/[0-9.]*, \([0-9.]*\).*/\1/"`
#  sz=`echo "$s" | sed -e "s/[0-9].*, [0-9.]*, \([0-9.]*\).*/\1/"`
#  VoxelVolume=`echo "${sx}*${sy}*${sz}"|bc`

#  counter=1
#  for i in L R; do
#    for j in Frontal Parietal Occipital Temporal Insula Cerebellum; do
#      LesionCount=0
#      LesionVoxels=0
#      LesionVolume=0

#      crlImageAlgebra ${OFOLDER}/${prefix}LesionSegmentation.nrrd multiply ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe.nrrd ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd
#      crlConnectedComponentFilter ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions-cc.nrrd 20
#      LesionCount=$(crlImageStats ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions-cc.nrrd | grep -o -P "Maximum [0-9]{1,100}" | grep -o -P "[0-9]{1,100}")

#      crlRelabelImages ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd "0" "0" ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd "${counter}"
#      LesionVoxels=$(crlImageStatsLabelled -i ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd -l ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd --minlabel ${counter} --maxlabel ${counter} | grep -o -P "Count, [0-9]{1,100}" | grep -o -P "[0-9]{1,100}")
#      LesionVolume=`echo "${VoxelVolume}*${LesionVoxels}"|bc` 

#      crlImageAlgebra ${OFOLDER}/LesionSegmentationPerLobe.nrrd add ${OFOLDER}/tmpDir/${prefix}${i}-${j}-Lobe-Lesions.nrrd ${OFOLDER}/LesionSegmentationPerLobe.nrrd

#      echo "${i},${j},${LesionCount},${LesionVolume}" >> ${OFOLDER}/${prefix}LesionReport.csv

#      counter=$((${counter}+1))
#    done
#  done

#  exportVariable "LESION_REPORT_CSV" "${OFOLDER}/${prefix}LesionReport.csv"

#  if [ ! -z "$OFOLDER" ]; then
#      rm -Rf "$OFOLDER/tmpDir"
#      rm -Rf ${RefinedICC_ALIGNED_REFERENCE_FOLDER}
#  fi

#  CACHE_StepHasBeenDone "LESION_REPORT" "${T1W_REF}" "${OFOLDER}/${prefix}LesionReport.csv"

#fi
































































