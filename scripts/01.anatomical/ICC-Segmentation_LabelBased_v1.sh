function doSpectralSpatialSegmentation()
{
  local num=${1}
  local inputVectorImage=${2}
  local workingFolder=${3}
  local outputFolder=${4}
  local radius=${5}
  local cachevar=${6}

  crlRelabelImages ${workingFolder}/r-c${num}-icc.nrrd ${workingFolder}/r-c${num}-icc.nrrd "0" "1" ${workingFolder}/r-c${num}-background.nrrd "0" >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlConstructVectorImage ${workingFolder}/r-c${num}-background.nrrd ${workingFolder}/r-c${num}-icc.nrrd ${workingFolder}/r-c${num}-icc-vectorimage.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlAtlasSample3 ${workingFolder}/r-c${num}-icc-vectorimage.nrrd ${radius} ${workingFolder}/r-c${num}-icc-mapfile.map 5000 "0 1" ${workingFolder}/in-t1w-Target.nrrd ${workingFolder}/in-t2w-Target.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlOrderKVoronoiDiagram ${workingFolder}/r-c${num}-icc-mapfile.map auto auto auto 31 ${workingFolder}/r-c${num}-icc-table.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlTableLookup ${workingFolder}/r-c${num}-icc-table.nrrd ${workingFolder}/${inputVectorImage} ${workingFolder}/r-c${num}-icc-weights.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlSpectralSpatialSegmentation ${workingFolder}/r-c${num}-icc-mapfile.map ${workingFolder}/r-c${num}-icc-weights.nrrd ${workingFolder}/r-c${num}-almost-icc.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlBinaryMorphology ${workingFolder}/r-c${num}-almost-icc.nrrd opening 1 4 ${workingFolder}/r-c${num}-final-icc.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlConnectedComponentFilter ${workingFolder}/r-c${num}-final-icc.nrrd ${workingFolder}/r-c${num}-final-icc.nrrd 10000 >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlRelabelImages ${workingFolder}/r-c${num}-final-icc.nrrd ${workingFolder}/r-c${num}-final-icc.nrrd "1" "1" ${workingFolder}/r-c${num}-final-icc.nrrd "0" >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlBinaryMorphology ${workingFolder}/r-c${num}-final-icc.nrrd closing 1 4 ${workingFolder}/r-c${num}-final-icc.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1
  crlBinaryMorphology ${workingFolder}/r-c${num}-final-icc.nrrd dilate 1 1 ${workingFolder}/r-c${num}-final-icc.nrrd >> ${workingFolder}/r-c${num}-final-icc-log.txt 2>&1

  CACHE_StepHasBeenDone "${cachevar}" "${T1W_REF},${T2W_REF}" "${workingFolder}/r-c${num}-final-icc.nrrd"
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

#---------------------------------#
#---- Generate Rough ICC Mask ----#
#---------------------------------#
sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentICC.sh "ICC" "${T1W_REF}" "${T2W_REF}"

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
  
  crlConstructVectorImage ${ICC_ALIGNED_REFERENCE_FOLDER}/in-t1w-Target.nrrd ${ICC_ALIGNED_REFERENCE_FOLDER}/in-t2w-Target.nrrd ${ICC_ALIGNED_REFERENCE_FOLDER}/in-Target-VectorImage.nrrd

  npr=0
  tcount=0
  total=$(( ${ICC_TEMPLATE_NUMBER}+1 ))
  while( [ ${tcount} -lt ${total} ] ); do
    while ( [ ${npr} -lt ${NBTHREADS} ] ); do
      if [ ${tcount} -lt ${total} ]; then
        num=$(printf %03d ${tcount})
        echo ${ICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-final-icc.nrrd >> ${tmpDir}/RoughICCReferencePopulation.txt
        
        CACHE_DoStepOrNot "Template-${num}-Rough-ICC"
        if [ $? -eq 0 ]; then
          echo "- Use previously estimated rough ICC for template ${num}"
          echo
        else
          echo "Generating rough icc segmentation for template-${num}..."
          doSpectralSpatialSegmentation "${num}" "in-Target-VectorImage.nrrd" "${ICC_ALIGNED_REFERENCE_FOLDER}" "${tmpDir}" "5" "Template-${num}-Rough-ICC" &
          exitIfError "${num}-SpectralSpatialSegmentation"
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

  crlLocalLOPSTAPLE -p ${threadNo} -x 3 -y 3 -z 3 -O ${tmpDir}/Rough-ICC.nrrd -o ${tmpDir}/Rough-ICC-Weights.nrrd -l ${tmpDir}/RoughICCReferencePopulation.txt
  exitIfError "crlLocalLOPSTAPLE"

  crlConnectedComponentFilter ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/Rough-ICC.nrrd 10000
  crlRelabelImages ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/Rough-ICC.nrrd "1" "1" ${tmpDir}/Rough-ICC.nrrd "0"

  crlImageAlgebra ${ICC_ALIGNED_REFERENCE_FOLDER}/in-t1w-Target.nrrd multiply ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/rough-t1w.nrrd
  crlImageAlgebra ${ICC_ALIGNED_REFERENCE_FOLDER}/in-t2w-Target.nrrd multiply ${tmpDir}/Rough-ICC.nrrd ${tmpDir}/rough-t2w.nrrd

  CACHE_StepHasBeenDone "ROUGH_ICC_ESTIMATION" "${T1W_REF},${T2W_REF}" "${tmpDir}/Rough-ICC.nrrd"
fi

#-----------------------------------#
#---- Generate Refined ICC Mask ----#
#-----------------------------------#

#---- First refine intersubject alignment ----#
crlRigidRegistration ${tmpDir}/rough-t1w.nrrd ${tmpDir}/rough-t2w.nrrd ${tmpDir}/r-rough-t2w.nrrd ${tmpDir}/r-rough-t2w.txt --metricName mi
crlAffineRegistration ${tmpDir}/rough-t1w.nrrd ${tmpDir}/rough-t2w.nrrd ${tmpDir}/ar-rough-t2w.nrrd ${tmpDir}/ar-rough-t2w.txt ${tmpDir}/r-rough-t2w.txt --metricName mi

sh ${ScriptDir}/03.modules/PopulationAlignment/PopulationAlignmentICC.sh "RefinedICC" "${tmpDir}/rough-t1w.nrrd" "${tmpDir}/ar-rough-t2w.nrrd"

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
  
  crlConstructVectorImage ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/in-t1w-Target.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/in-t2w-Target.nrrd ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/in-Target-VectorImage.nrrd

  npr=0
  tcount=0
  total=$(( ${RefinedICC_TEMPLATE_NUMBER}+1 ))
  while( [ ${tcount} -lt ${total} ] ); do
    while ( [ ${npr} -lt ${NBTHREADS} ] ); do
      if [ ${tcount} -lt ${total} ]; then
        num=$(printf %03d ${tcount})
        echo ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-tissues.nrrd >> ${tmpDir}/RefinedICCReferencePopulation.txt
        echo ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/r-c${num}-t1w.nrrd >> ${tmpDir}/RefinedICCReferencePopulationStructural.txt
        
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
    crlProbabilisticGMMSTAPLE -p ${NBTHREADS} -x 16 -y 16 -z 16 -X 4 -Y 4 -Z 4 -T ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/in-t1w-Target.nrrd -S ${tmpDir}/RefinedICCReferencePopulation.txt -I ${tmpDir}/RefinedICCReferencePopulationStructural.txt -t 4 -O ${tmpDir}/TissueSegmentation.nrrd   
    exitIfError "crlProbabilisticGMMSTAPLE"

    CACHE_StepHasBeenDone "TISSUE_SEGMENTATION" "${T1W_REF}" "${tmpDir}/TissueSegmentation.nrrd"
  fi

  #---- Estimate BrainMask from Tissue Segmentation ----#
  crlRelabelImages ${tmpDir}/TissueSegmentation.nrrd ${tmpDir}/TissueSegmentation.nrrd "1 2 3" "1 1 1" ${tmpDir}/tmp-BrainMask.nrrd "0"
  crlBinaryMorphology ${tmpDir}/tmp-BrainMask.nrrd opening 1 2 ${tmpDir}/o-tmp-BrainMask.nrrd
  crlConnectedComponentFilter ${tmpDir}/o-tmp-BrainMask.nrrd ${tmpDir}/co-tmp-BrainMask.nrrd 100000
  crlBinaryMorphology ${tmpDir}/co-tmp-BrainMask.nrrd closing 1 4 ${tmpDir}/BrainMask.nrrd
  

  #---- Estimate ICC from Tissue Segmentation ----#
  crlRelabelImages ${tmpDir}/TissueSegmentation.nrrd ${tmpDir}/TissueSegmentation.nrrd "0" "0" ${tmpDir}/tmp-icc.nrrd "1"
  crlBinaryMorphology ${tmpDir}/tmp-icc.nrrd dilate 1 1 ${tmpDir}/d-tmp-icc.nrrd
  crlBinaryMorphology ${tmpDir}/tmp-icc.nrrd erode 1 1 ${tmpDir}/e-tmp-icc.nrrd
  crlImageAlgebra ${tmpDir}/d-tmp-icc.nrrd subtract ${tmpDir}/e-tmp-icc.nrrd ${tmpDir}/inspection-boundary.nrrd

  crlRelabelImages ${tmpDir}/TissueSegmentation.nrrd ${tmpDir}/TissueSegmentation.nrrd "4" "1" ${tmpDir}/extra-csf.nrrd "0"
  crlImageAlgebra ${tmpDir}/inspection-boundary.nrrd multiply ${tmpDir}/extra-csf.nrrd ${tmpDir}/csf-ToInspect.nrrd
  crlDetectVectorOutlier -p ${NBTHREADS} -x 2 -y 2 -z 2 -o ${tmpDir}/tmp-csf-zscore.nrrd -T ${RefinedICC_ALIGNED_REFERENCE_FOLDER}/in-Target-VectorImage.nrrd -L ${tmpDir}/extra-csf.nrrd -m ${tmpDir}/csf-ToInspect.nrrd
  crlBinaryThreshold ${tmpDir}/tmp-csf-zscore.nrrd ${tmpDir}/def-csf.nrrd 0 0.2 1 0
  crlBinaryMorphology ${tmpDir}/def-csf.nrrd opening 1 1 ${tmpDir}/o-def-csf.nrrd
  crlConnectedComponentFilter ${tmpDir}/o-def-csf.nrrd ${tmpDir}/Refined-ICC.nrrd 10000
  crlImageAlgebra ${tmpDir}/Refined-ICC.nrrd multiply ${tmpDir}/tmp-icc.nrrd ${tmpDir}/Refined-ICC.nrrd
  crlConnectedComponentFilter ${tmpDir}/Refined-ICC.nrrd ${tmpDir}/Refined-ICC.nrrd 10000
  crlRelabelImages ${tmpDir}/Refined-ICC.nrrd ${tmpDir}/Refined-ICC.nrrd "1" "1" ${tmpDir}/Refined-ICC.nrrd "0"

  #rm -rf "${RefinedICC_ALIGNED_REFERENCE_FOLDER}" 
  #rm -rf "${ICC_ALIGNED_REFERENCE_FOLDER}"

  CACHE_StepHasBeenDone "REFINED_ICC_ESTIMATION" "${T1W_REF},${T2W_REF}" "${tmpDir}/Refined-ICC.nrrd"
fi

cp ${tmpDir}/Refined-ICC.nrrd ${outImg}
cp ${tmpDir}/Refined-ICC.nrrd ${brainMaskImg}
cp ${tmpDir}/TissueSegmentation.nrrd ${tissueImg}

exit 0

