function doRoughICCSegmentation()
{
  local num=${1}
  local inputVectorImage=${2}
  local workingFolder=${3}
  local outputFolder=${4}
  local radius=${5}
  local cachevar=${6}
  local nthread=${7}
  local stabvar=0
  
  if [[ ${ICC_STRATEGY} -eq 1 ]]; then
    stabvar=0;
  else
    stabvar=1;
  fi

  crlExtractFromVectorImage ${workingFolder}/${inputVectorImage} ${workingFolder}/i-r${num}-t1w-ref.nrrd 0  
  crlExtractFromVectorImage ${workingFolder}/${inputVectorImage} ${workingFolder}/i-r${num}-t2w-ref.nrrd 1

  crlMultipleOtsuMaskMaker -o ${workingFolder}/r-c${num}-FullComputationMask.nrrd ${workingFolder}/i-r${num}-t2w-ref.nrrd 2 
  crlRelabelImages ${workingFolder}/r-c${num}-FullComputationMask.nrrd ${workingFolder}/r-c${num}-FullComputationMask.nrrd "0" "0" ${workingFolder}/r-c${num}-FullComputationMask.nrrd "1"
  crlBinaryMorphology ${workingFolder}/r-c${num}-FullComputationMask.nrrd closing 1 5 ${workingFolder}/r-c${num}-FullComputationMask.nrrd

  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "0" "1" ${workingFolder}/r-c${num}-background.nrrd "0" 
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "1" "1" ${workingFolder}/r-c${num}-GM.nrrd "0" 
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "4" "1" ${workingFolder}/r-c${num}-CSF.nrrd "0" 
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "2" "1" ${workingFolder}/r-c${num}-Ventricles.nrrd "0" 
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "3" "1" ${workingFolder}/r-c${num}-WM.nrrd "0" 
  crlConstructVectorImage ${workingFolder}/r-c${num}-background.nrrd ${workingFolder}/r-c${num}-GM.nrrd ${workingFolder}/r-c${num}-CSF.nrrd ${workingFolder}/r-c${num}-WM.nrrd ${workingFolder}/r-c${num}-Ventricles.nrrd ${workingFolder}/r-c${num}-icc-vectorimage.nrrd

  rm ${workingFolder}/r-c${num}-background.nrrd ${workingFolder}/r-c${num}-GM.nrrd ${workingFolder}/r-c${num}-CSF.nrrd ${workingFolder}/r-c${num}-WM.nrrd ${workingFolder}/r-c${num}-Ventricles.nrrd

  crlBinaryMorphology ${workingFolder}/r-c${num}-icc.nrrd dilate 1 15 ${workingFolder}/r-c${num}-ComputationMask.nrrd 
  crlImageAlgebra ${workingFolder}/r-c${num}-ComputationMask.nrrd multiply ${workingFolder}/r-c${num}-FullComputationMask.nrrd ${workingFolder}/r-c${num}-ComputationMask.nrrd
  rm ${workingFolder}/r-c${num}-FullComputationMask.nrrd

  crlConstructVectorImage ${workingFolder}/r-c${num}-t1w.nrrd ${workingFolder}/r-c${num}-t2w.nrrd ${workingFolder}/r-c${num}-feature-vectorimage.nrrd 

  crlSVGMM -p "${nthread}" -I 100 -t 1e-8 -r 12 -s 1 -c ${stabvar} -i ${workingFolder}/i-r${num}-t1w-ref.nrrd -i ${workingFolder}/i-r${num}-t2w-ref.nrrd -M ${workingFolder}/r-c${num}-ComputationMask.nrrd -o "${workingFolder}/r-c${num}-" -f ${workingFolder}/r-c${num}-feature-vectorimage.nrrd -l ${workingFolder}/r-c${num}-icc-vectorimage.nrrd 

  CACHE_StepHasBeenDone "${cachevar}" "${T1W_REF},${T2W_REF}" "${workingFolder}/r-c${num}-TissueProbability.nrrd"
}

function doRefinedICCSegmentation()
{
  local num=${1}
  local inputVectorImage=${2}
  local workingFolder=${3}
  local outputFolder=${4}
  local radius=${5}
  local cachevar=${6}
  local nthread=${7}

  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "0" "1" ${workingFolder}/r-c${num}-background.nrrd "0"
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "1" "1" ${workingFolder}/r-c${num}-GM.nrrd "0"
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "4" "1" ${workingFolder}/r-c${num}-CSF.nrrd "0"
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "2" "1" ${workingFolder}/r-c${num}-Ventricles.nrrd "0"
  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "3" "1" ${workingFolder}/r-c${num}-WM.nrrd "0"
  crlConstructVectorImage ${workingFolder}/r-c${num}-background.nrrd ${workingFolder}/r-c${num}-GM.nrrd ${workingFolder}/r-c${num}-CSF.nrrd ${workingFolder}/r-c${num}-WM.nrrd ${workingFolder}/r-c${num}-Ventricles.nrrd ${workingFolder}/r-c${num}-tissues-vectorimage.nrrd

  rm ${workingFolder}/r-c${num}-background.nrrd ${workingFolder}/r-c${num}-GM.nrrd ${workingFolder}/r-c${num}-CSF.nrrd ${workingFolder}/r-c${num}-WM.nrrd ${workingFolder}/r-c${num}-Ventricles.nrrd

  crlRelabelImages ${workingFolder}/r-c${num}-tissues.nrrd ${workingFolder}/r-c${num}-tissues.nrrd "0" "0" ${workingFolder}/r-c${num}-ComputationMask.nrrd "1"
  crlBinaryMorphology ${workingFolder}/r-c${num}-ComputationMask.nrrd dilate 1 5 ${workingFolder}/r-c${num}-ComputationMask.nrrd
  
  crlConstructVectorImage ${workingFolder}/r-c${num}-t1w.nrrd ${workingFolder}/r-c${num}-t2w.nrrd ${workingFolder}/r-c${num}-feature-vectorimage.nrrd
  crlSVGMM -p "${nthread}" -I 100 -t 1e-8 -r 12 -s 1 -i ${T1W_REF} -i ${T2W_REF} -M ${workingFolder}/r-c${num}-ComputationMask.nrrd -o "${workingFolder}/r-c${num}-" -f ${workingFolder}/r-c${num}-feature-vectorimage.nrrd -l ${workingFolder}/r-c${num}-tissues-vectorimage.nrrd

  CACHE_StepHasBeenDone "${cachevar}" "${T1W_REF},${T2W_REF}" "${workingFolder}/r-c${num}-TissueProbability.nrrd"
}

#!/bin/sh

umask 002
#----------------------------------------------------------
# First get scriptdir to source Settings.txt
#----------------------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

refImage=${1}
tmpDir=${2}
outImg=${3} 
brainMaskImg=${4}
tissueImg=${5}
threadNo=${6}
crlExtractFromVectorImage $refImage ${tmpDir}/t1w.nrrd 0

RegistrationTitle=""
if [[ ${POPULATION_ALIGNMENT_ALGORITHM} == 0 ]]; then
  RegistrationTitle="crlRegistration"
else
  RegistrationTitle="ANTS"
fi

StrategyTitle=""
if [[ ${POPULATION_ALIGNMENT_STRATEGY} == 1 ]]; then
  StrategyTitle="Composed"
else
  StrategyTitle="Direct"
fi

Population=""
RefinedPopulation=""
if [[ ${ICC_BABY} == 1 ]]; then
  Population="BabyICC"
  RefinedPopulation="RefinedBabyICC"
else
  Population="ICC"
  RefinedPopulation="RefinedICC"
fi

tensors="${DWIid}_RTENSOR_1T"
tensors=${!tensors}

#---------------------------------#
#---- Generate Rough ICC Mask ----#
#---------------------------------#
s=`crlImageInfo "${T1W_REF}" | grep Spacing`
s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`

sx=`echo "$s" | sed -e "s/\([0-9.]*\).*/\1/"`
sy=`echo "$s" | sed -e "s/[0-9.]*, \([0-9.]*\).*/\1/"`
sz=`echo "$s" | sed -e "s/[0-9].*, [0-9.]*, \([0-9.]*\).*/\1/"`

min=`getMinFloat "$sx" "$sy"`
min=`getMinFloat "$min" "$sz"`
min=$(echo "$min * 2" | bc)

crlResampleToIsotropic "${T1W_REF}" linear "${tmpDir}/s-t1w.nrrd" -x $min -y $min -z $min
#crlResampleToIsotropic "${T2W_REF}" linear "${tmpDir}/s-t2w.nrrd" -x $min -y $min -z $min
crlRigidRegistration "${tmpDir}/s-t1w.nrrd" "${T2W_REF}" "${tmpDir}/s-t2w.nrrd" "${tmpDir}/s-t2w.txt"

sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentScalar.sh "${Population}" "${tmpDir}/s-t1w.nrrd" "t1w"

source "`dirname $0`/../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

CACHE_DoStepOrNot "ROUGH_ICC_ESTIMATION"
if [ $? -eq 0 ]; then
  echo "- Use previously estimated rough icc mask"
  echo
else
  if [[ -f ${tmpDir}/RoughICCReferencePopulation.txt ]]; then
    rm ${tmpDir}/RoughICCReferencePopulation.txt
  fi
  
  PopulationFolder="${Population}_ALIGNED_REFERENCE_FOLDER"
  PopulationFolder=${!PopulationFolder}
  crlConstructVectorImage "${tmpDir}/s-t1w.nrrd" "${tmpDir}/s-t2w.nrrd" "${PopulationFolder}/in-Target-VectorImage.nrrd"

  npr=0
  tcount=1
  TemplateNumber="${Population}_TEMPLATE_NUMBER"
  TemplateNumber=${!TemplateNumber}
  total=$(( ${TemplateNumber}+1 ))
  
  while( [ ${tcount} -lt ${total} ] ); do
    while ( [ ${npr} -lt ${NBTHREADS} ] ); do
      if [ ${tcount} -lt ${total} ]; then
        num=$(printf %03d ${tcount})
        echo ${PopulationFolder}/r-c${num}-TissueProbability.nrrd >> ${tmpDir}/RoughICCReferencePopulation.txt

        CACHE_DoStepOrNot "Template-${num}-Rough-ICC"
        if [ $? -eq 0 ]; then
          echo "- Use previously estimated rough ICC for template ${num}"
          echo
        else
          nt=`echo "scale=10; n=(${threadNo}/${ICC_TEMPLATE_NUMBER}+0.5); scale=0; n/1 " | bc`		# Number of threads... depends on number of templates
          if [[ $nt -eq 0 ]]; then
             nt=1
          fi
          echo "Generating rough icc segmentation for template-${num} ($nt threads)..."
        
          doRoughICCSegmentation "${num}" "in-Target-VectorImage.nrrd" "${PopulationFolder}" "${tmpDir}" "5" "Template-${num}-Rough-ICC" "${nt}" > "${tmpDir}/r${num}-RoughICC-segmentation.txt" &
          exitIfError "${num}-RoughICCSegmentation"
        fi
        
        npr=$[ ${npr} + 1 ]
        tcount=$[ ${tcount} + 1 ]
      else
        npr=${NBTHREADS}
      fi
    done

    wait
    npr=0
  done

  crlVectorProbabilisticSTAPLE -p ${threadNo} -P ${tmpDir}/RoughICCReferencePopulation.txt -O ${tmpDir}/Rough-ICC.nrrd -o ${tmpDir}/Rough-ICC-Weights.nrrd
  exitIfError "crlVectorProbabilisticSTAPLE"   

  crlRigidRegistration ${T1W_REF} ${tmpDir}/s-t1w.nrrd ${tmpDir}/rs-t1w.nrrd ${tmpDir}/rs-t1w.txt
  
  crlCreateNullImageFromImage "${tmpDir}/s-t1w.nrrd" "${tmpDir}/Rough-ICC.nrrd"
  for i in 1 2 3 4; do
    crlExtractFromVectorImage "${tmpDir}/Rough-ICC-Weights.nrrd" "${tmpDir}/tissue${i}.nrrd" ${i}
    crlImageAlgebra "${tmpDir}/Rough-ICC.nrrd" add "${tmpDir}/tissue${i}.nrrd" "${tmpDir}/Rough-ICC.nrrd"
  done
  
  crlResampler "${tmpDir}/Rough-ICC.nrrd" "${tmpDir}/rs-t1w.txt" ${T1W_REF} linear "${tmpDir}/Rough-ICC.nrrd"
  crlBinaryThreshold "${tmpDir}/Rough-ICC.nrrd" "${tmpDir}/Rough-ICC.nrrd" 1e-1 100 1 0
  crlRelabelImages "${tmpDir}/Rough-ICC.nrrd" "${tmpDir}/Rough-ICC.nrrd" "0" "1" "${tmpDir}/Rough-ICC.nrrd" "0"
  
  crlExtractFromVectorImage "${tmpDir}/Rough-ICC-Weights.nrrd" "${tmpDir}/Background.nrrd" 0
  crlResampler "${tmpDir}/Background.nrrd" "${tmpDir}/rs-t1w.txt" ${T1W_REF} linear "${tmpDir}/Background.nrrd"
  crlBinaryThreshold "${tmpDir}/Background.nrrd" "${tmpDir}/Background.nrrd" 1e-1 1 1 0
  
  crlImageAlgebra "${tmpDir}/Rough-ICC.nrrd" add "${tmpDir}/Background.nrrd" "${tmpDir}/Background.nrrd"
  crlRelabelImages "${tmpDir}/Background.nrrd" "${tmpDir}/Background.nrrd" "0" "0" "${tmpDir}/Background.nrrd" "1"
  crlBinaryMorphology "${tmpDir}/Background.nrrd" closing 1 2 "${tmpDir}/Background.nrrd"
  crlRelabelImages "${tmpDir}/Background.nrrd" "${tmpDir}/Background.nrrd" "0" "1" "${tmpDir}/Rough-ICC.nrrd" "0"
  crlBinaryMorphology "${tmpDir}/Rough-ICC.nrrd" dilate 1 2 "${tmpDir}/Rough-ICC.nrrd"

  crlImageAlgebra ${T1W_REF} multiply ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/rough-t1w.nrrd
  crlImageAlgebra ${T2W_REF} multiply ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/rough-t2w.nrrd

  exportVariable "BRAIN_MASK" "${tmpDir}/Rough-ICC.nrrd"
  exportVariable "ICC_MASK" "${tmpDir}/Rough-ICC.nrrd"

  CACHE_StepHasBeenDone "ROUGH_ICC_ESTIMATION" "${T1W_REF},${T2W_REF}" "${tmpDir}/Rough-ICC.nrrd"
fi

#-----------------------------------#
#---- Generate Refined ICC Mask ----#
#-----------------------------------#

#---- First refine intersubject alignment ----#
sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentScalar.sh "${RefinedPopulation}" "${T1W_REF}" "t1w"

source "`dirname $0`/../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

CACHE_DoStepOrNot "REFINED_ICC_ESTIMATION"
if [ $? -eq 0 ]; then
  echo "- Use previously estimated refined ICC for template ${num}"
  echo
else
  if [[ -f ${tmpDir}/RefinedICCReferencePopulation.txt ]]; then
    rm ${tmpDir}/RefinedICCReferencePopulation.txt
    rm ${tmpDir}/RefinedICCReferencePopulationStructural.txt
  fi
 
  RefinedPopulationFolder="${RefinedPopulation}_ALIGNED_REFERENCE_FOLDER"
  RefinedPopulationFolder=${!RefinedPopulationFolder}
  crlConstructVectorImage ${T1W_REF} ${T2W_REF} ${RefinedPopulationFolder}/in-Target-VectorImage.nrrd

  npr=0
  tcount=1
  RefinedTemplateNumber="${RefinedPopulation}_TEMPLATE_NUMBER"
  RefinedTemplateNumber=${!RefinedTemplateNumber}
  total=$(( ${RefinedTemplateNumber}+1 ))
  while( [ ${tcount} -lt ${total} ] ); do
    while ( [ ${npr} -lt ${NBTHREADS} ] ); do
      if [ ${tcount} -lt ${total} ]; then
        num=$(printf %03d ${tcount})
        echo ${RefinedPopulationFolder}/r-c${num}-TissueProbability.nrrd >> ${tmpDir}/RefinedICCReferencePopulation.txt

        CACHE_DoStepOrNot "Template-${num}-Refined-ICC"
        if [ $? -eq 0 ]; then
          echo "- Use previously estimated refined ICC for template ${num}"
          echo
        else
          nt=`echo "scale=10; n=(${threadNo}/${ICC_TEMPLATE_NUMBER}+0.5); scale=0; n/1 " | bc`		# Number of threads... depends on number of templates
          if [[ $nt -eq 0 ]]; then
             nt=1
          fi

          echo "Generating refined icc segmentation for template-${num} ($nt threads)..."
        
          doRefinedICCSegmentation "${num}" "in-Target-VectorImage.nrrd" "${RefinedPopulationFolder}" "${tmpDir}" "5" "Template-${num}-Refined-ICC" "${nt}" > "${tmpDir}/r${num}-RefinedICC-segmentation.txt" &
          exitIfError "${num}-RefinedICCSegmentation"
        fi
        
        npr=$[ ${npr} + 1 ]
        tcount=$[ ${tcount} + 1 ]
      else
        npr=${NBTHREADS}
      fi
    done

    wait
    npr=0
  done

  CACHE_DoStepOrNot "TISSUE_SEGMENTATION"
  if [ $? -eq 0 ]; then
    echo "- Use previously estimated tissue segmentation"
    echo
  else
    crlVectorProbabilisticSTAPLE -p ${threadNo} -P ${tmpDir}/RefinedICCReferencePopulation.txt -O ${tmpDir}/TissueSegmentation.nrrd -o ${tmpDir}/TissueSegmentation-Weights.nrrd
    exitIfError "crlVectorProbabilisticSTAPLE"

    CACHE_StepHasBeenDone "TISSUE_SEGMENTATION" "${T1W_REF}" "${tmpDir}/TissueSegmentation.nrrd"
  fi

  crlRelabelImages "${tmpDir}/TissueSegmentation.nrrd" "${tmpDir}/TissueSegmentation.nrrd" "0 1 " "0 0" "${tmpDir}/Refined-ICC.nrrd" "1" 
  crlBinaryMorphology "${tmpDir}/Refined-ICC.nrrd" opening 1 2 "${tmpDir}/o-Refined-ICC.nrrd"
  crlConnectedComponentFilter "${tmpDir}/o-Refined-ICC.nrrd" "${tmpDir}/co-Refined-ICC.nrrd" 10000
  crlRelabelImages "${tmpDir}/co-Refined-ICC.nrrd" "${tmpDir}/co-Refined-ICC.nrrd" "1" "1" "${tmpDir}/co-Refined-ICC.nrrd" "0"
  crlBinaryMorphology "${tmpDir}/co-Refined-ICC.nrrd" closing 1 10 "${tmpDir}/co-Refined-ICC.nrrd"
  crlImageAlgebra "${tmpDir}/co-Refined-ICC.nrrd" multiply "${tmpDir}/Refined-ICC.nrrd" "${tmpDir}/Refined-ICC.nrrd"
  rm "${tmpDir}/co-Refined-ICC.nrrd" "${tmpDir}/o-Refined-ICC.nrrd"

  CACHE_StepHasBeenDone "REFINED_ICC_ESTIMATION" "${T1W_REF},${T2W_REF}" "${tmpDir}/Refined-ICC.nrrd"
fi

rm -rf ${PopulationFolder}
rm -rf ${RefinedPopulationFolder}

cp ${tmpDir}/Refined-ICC.nrrd ${outImg}
cp ${tmpDir}/Refined-ICC.nrrd ${brainMaskImg}
cp ${tmpDir}/TissueSegmentation.nrrd ${tissueImg}

exit 0

