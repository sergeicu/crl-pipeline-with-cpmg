#################################################
#---- REFERENCE POPULATION ALIGNMENT MODULE ----#
#################################################

function doInitializeRegistration()
{
  local Population=$1

  CRLThirdParty="/common/projects/xavier/Code/build"

  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then 
    #------------------------------------------#
    #---- Use CRL Block Matching Algorithm ----#
    #------------------------------------------#
    Registration="crlBlockMatchingRegistration"
    Resampler="crlBlockMatchingRegistration"

    #---- Define CRL Block Matching Parameters ----#
    CRLRigidParameters="-t similarity -s 3 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 5 --bh 3 --sb 3 --blv 3 --rs 2 --ssi cc -I linear"
    CRLAffineParameters="-t affine -s 3 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 10 --bh 3 --sb 3 --blv 2 --rs 2 --ssi cc -I linear"
    CRLDenseParameters="-t dense -s 4 -e 0 -k 0.8 -l 0.80 --sig 4.0 --mv 1.0 -n 10 --bh 4 --sb 3 --blv 3 --rs 2 --ssi cc -I linear"
    CRLResamplerParameters="-s 0 -e 0 -k 0.8 -l 0.8 --sig 4.0 --mv 0.0 -n 0 --bh 3 --sb 3 --blv 3 --rs 2 --ssi cc -N"
   
  elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
    #----------------------------#
    #---- Use ANTS Algorithm ----#
    #----------------------------#
    N4="${CRLThirdParty}/ANTs/bin/N4BiasFieldCorrection"
    Registration="${CRLThirdParty}/ANTs/bin/ANTS"
    Resampler="${CRLThirdParty}/ANTs/bin/WarpImageMultiTransform"

    #---- Define ANTS Parameters ----#
    if [[ ${Population} == "ICC" ]]; then
      ANTSParameters="-r Gauss[2,0] -t SyN[0.25] -i 100x100x0 --use-all-metrics-for-convergence 1 --continue-affine false"
    elif [[ ${Population} == "RefinedICC" ]]; then
      ANTSParameters="-r Gauss[0,2] -t SyN[0.5] -i 50x90x20 --use-all-metrics-for-convergence 1 --continue-affine false"
    fi
  fi
}

function doInitializePopulation()
{
  local Population=$1

  if [[ ${Population} == "ICC" ]]; then
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalpTemplate"
    T1WAVERAGETEMPLATE="t1w-Template.nii.gz"
    T2WAVERAGETEMPLATE="t2w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalp"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w"
    TEMPLATESLABELMASK="icc-mod tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"

  elif [[ ${Population} == "RefinedICC" ]]; then
    GetTemplateLibraryDir "R01Controls"			# Get dir in TemplateLibraryDir
    
    AVERAGETEMPLATES_FOLDER="${TemplateLibraryDir}/WithScalpTemplate"
    T1WAVERAGETEMPLATE="i-t1w-Template.nii.gz"
    T2WAVERAGETEMPLATE="i-t2w-Template.nii.gz"
    
    TEMPLATES_FOLDER="${TemplateLibraryDir}/Masked"
    TEMPLATESNUMBER=15
    TEMPLATESMODALITIES="t1w t2w flair"
    TEMPLATESLABELMASK="icc tissues"

    exportVariable "${Population}_TEMPLATE_NUMBER" "${TEMPLATESNUMBER}"
  fi
}

function doResampling()
{
  local input=${1}
  local output=${2}
  local reference=${3}
  local transform=${4}
  #local cachevar=${5}

  ${Resampler} 3 ${input} ${output} -R ${reference} ${transform} >> "${output}-log.txt" 2>&1
  exitIfError "${Resampler}-${output}"

  #CACHE_StepHasBeenDone "${cachevar}" "${T1W_REF},${T2W_REF}" "${output}"
}

function doPopulationAlignment_COMPOSED()
{
  local Population=$1
  local t1wTarget=$2
  local t2wTarget=$3

  #--------------------------------------------------------------------------------#
  #---- Target image to Average Population Atlas Rigid and Affine Registration ----#
  #--------------------------------------------------------------------------------#
  CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Rigid"
  if [ $? -eq 0 ]; then
    echo "- Use previously estimated rigid registration."
    echo
  else
    crlRigidRegistration ${AVERAGETEMPLATES_FOLDER}/${T1WAVERAGETEMPLATE} ${t1wTarget} ${OFOLDER}/TargetToTemplate-Rigid.nrrd ${OFOLDER}/TargetToTemplate-Rigid.txt --metricName mi
    exitIfError "crlRigidRegistration"

    CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Rigid" "${T1W_REF}" "${OFOLDER}/TargetToTemplate-Rigid.txt"
  fi

  CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Affine"
  if [ $? -eq 0 ]; then
    echo "- Use previously estimated affine registration."
    echo
  else
    crlAffineRegistration ${AVERAGETEMPLATES_FOLDER}/${T1WAVERAGETEMPLATE} ${t1wTarget} ${OFOLDER}/TargetToTemplate-Affine.nrrd ${OFOLDER}/TargetToTemplate-Affine.txt --metricName mi
    exitIfError "crlAffineRegistration"

    CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Affine" "${T1W_REF}" "${OFOLDER}/TargetToTemplate-Affine.txt"
  fi

  #-------------------------------------------------------------------------#
  #---- Target image to Average Population Atlas Non-Rigid Registration ----#
  #-------------------------------------------------------------------------#
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then
    #---- USE CRL BLOCK MATCHING ----#
    echo
    #---------------#
    #---- TO DO ----#
    #---------------#

  elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
    #---- USE ANTS ----#
    CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Warp"
    if [ $? -eq 0 ]; then
      echo "- Use previously estimated registration."
      echo
    else
      if [[ ${Population} == "ICC" ]]; then
        cp ${OFOLDER}/TargetToTemplate-Affine.txt ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz
      elif [[ ${Population} == "RefinedICC" ]]; then
        ${Registration} 3 -m CC[${AVERAGETEMPLATES_FOLDER}/${T1WAVERAGETEMPLATE},${t1wTarget},0.5,2] -m CC[${AVERAGETEMPLATES_FOLDER}/${T2WAVERAGETEMPLATE},${t2wTarget},0.5,2] -o ${OFOLDER}/TargetToTemplate -a TargetToTemplate-Affine.txt -x ${AVERAGETEMPLATES_FOLDER}/icc-Template.nii.gz ${ANTSParameters}

        exitIfError "${Registration}"

        mv ${OFOLDER}/TargetToTemplateInverseWarp.nii.gz ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz
        mv ${OFOLDER}/TargetToTemplateWarp.nii.gz ${OFOLDER}/TargetToTemplate-Warp.nii.gz
      fi

      CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-TargetToAverageTemplate-Warp" "${T1W_REF},${T2W_REF}" "${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz"
    fi
  fi

  #------------------------------------------------#
  #---- Resample template population to target ----#
  #------------------------------------------------#
  for i in `seq 0 ${TEMPLATESNUMBER}`; do
    num=$(printf %03d ${i})
    
    if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then
      #---- USE CRL BLOCK MATCHING ----#
      echo
      #---------------#
      #---- TO DO ----#
      #---------------#
    
    elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
      #---- USE ANTS ----#
     
      #---- Resample population template label masks ----#
      for j in ${TEMPLATESMODALITIES}; do   
        CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
          if [[ ${Population} == "ICC" ]]; then
            doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${t1wTarget}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt --use-NN"
            exitIfError "${Resampler}-c${num}-${j}"
          else
            doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${t1wTarget}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt --use-NN"
            exitIfError "${Resampler}-c${num}-${j}"
          fi

          CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi      
      done

      for j in ${TEMPLATESLABELMASK}; do   
        CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
          if [[ ${Population} == "ICC" ]]; then
            doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${t1wTarget}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt --use-NN"
            exitIfError "${Resampler}-c${num}-${j}"
          else
            doResampling "${TEMPLATES_FOLDER}/c${num}-${j}.nrrd" "${OFOLDER}/r-c${num}-${j}.nrrd" "${t1wTarget}" "-i ${OFOLDER}/TargetToTemplate-Affine.txt ${OFOLDER}/TargetToTemplate-InverseWarp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Warp.nii.gz ${AVERAGETEMPLATES_FOLDER}/c${num}-ToTemplate-Affine.txt --use-NN"
            exitIfError "${Resampler}-c${num}-${j}"
          fi

          CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi      
      done

    fi
  done
}

function doPopulationAlignment_DIRECT()
{
  local Population=$1
  local num=$2
  local t1wTarget=$3
  local t2wTarget=$4
  local nthreads=$5

  ###########################################
  #### BLOCK MATCHING BASED REGISTRATION ####
  ###########################################
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 0 ]]; then
    #----------------------------#
    #---- Rigid Registration ----#
    #----------------------------#
    CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid"
    if [ $? -eq 0 ]; then
      echo "- Use previously estimated rigid registration."
      echo
    else
      ${Registration} -f ${TEMPLATES_FOLDER}/c${num}-t1w.nrrd -r ${t1wTarget} -o ${OFOLDER}/c${num}-ToTarget-Rigid ${CRLRigidParameters} -p ${nthreads}
      mv ${OFOLDER}/c${num}-ToTarget-Rigid_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Rigid.tfm
      mv ${OFOLDER}/c${num}-ToTarget-Rigid_FinalS.nrrd ${OFOLDER}/c${num}-ToTarget-Rigid.nrrd
      exitIfError "crlRigidRegistration-c${num}-${j}"
 
      CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Rigid.tfm"
    fi
    
    #-----------------------------#
    #---- Affine Registration ----#
    #-----------------------------#
    CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine"
    if [ $? -eq 0 ]; then
      echo "- Use previously estimated rigid registration."
      echo
    else
      ${Registration} -i ${OFOLDER}/c${num}-ToTarget-Rigid.tfm -f ${TEMPLATES_FOLDER}/c${num}-t1w.nrrd -r ${t1wTarget} -o ${OFOLDER}/c${num}-ToTarget-Affine ${CRLAffineParameters} -p ${nthreads} 
      mv ${OFOLDER}/c${num}-ToTarget-Affine_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Affine.tfm
      mv ${OFOLDER}/c${num}-ToTarget-Affine_FinalS.nrrd ${OFOLDER}/c${num}-ToTarget-Affine.nrrd
      exitIfError "crlAffineRegistration-c${num}-${j}"
 
      CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Affine.tfm"
    fi
    
    #---------------------------------------------------#
    #---- CRL Block Matching Non-Rigid Registration ----#
    #---------------------------------------------------#
    CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp"
    if [ $? -eq 0 ]; then
      echo "- Use previously estimated registration."
      echo
    else
      if [[ ${Population} == "ICC" ]]; then
        cp ${OFOLDER}/c${num}-ToTarget-Affine.tfm ${OFOLDER}/c${num}-ToTarget-Warp.tfm
      else
        ${Registration} -i ${OFOLDER}/c${num}-ToTarget-Affine.tfm -f ${TEMPLATES_FOLDER}/c${num}-t2w.nrrd -r ${t2wTarget} -o ${OFOLDER}/c${num}-ToTarget-Warp ${CRLDenseParameters} -p ${nthreads}
        mv ${OFOLDER}/c${num}-ToTarget-Warp_FinalS.tfm ${OFOLDER}/c${num}-ToTarget-Warp.tfm
        exitIfError "${Registration}-c${num}-${j}"
      fi
      
      CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF},${T2W_REF}" "${OFOLDER}/c${num}-ToTarget-Warp.tfm"
    fi

    #----------------------------------------#
    #---- Resample Template Label Images ----#
    #----------------------------------------#
    for j in ${TEMPLATESMODALITIES}; do
      CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
      if [ $? -eq 0 ]; then
        echo "- Use previously resampled ${Population} template-${num}-${j}"
        echo
      else
        if [[ ${Population} == "ICC" ]]; then
          ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Affine.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${t1wTarget} -o ${OFOLDER}/r-c${num}-${j} -t affine ${CRLResamplerParameters}
          mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
          exitIfError "${Resampler}-c${num}-${j}"
        else
          ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Warp.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${t1wTarget} -o ${OFOLDER}/r-c${num}-${j} -t dense ${CRLResamplerParameters}
          mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
          exitIfError "${Resampler}-c${num}-${j}"
        fi

        CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
      fi 
    done

    for j in ${TEMPLATESLABELMASK}; do
      CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
      if [ $? -eq 0 ]; then
        echo "- Use previously resampled ${Population} template-${num}-${j}"
        echo
      else
        if [[ ${Population} == "ICC" ]]; then
          ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Affine.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${t1wTarget} -o ${OFOLDER}/r-c${num}-${j} -I NN -t affine ${CRLResamplerParameters}
          mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
          exitIfError "${Resampler}-c${num}-${j}"
        else
          ${Resampler} -i ${OFOLDER}/c${num}-ToTarget-Warp.tfm -f ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd -r ${t1wTarget} -o ${OFOLDER}/r-c${num}-${j} -I NN -t dense ${CRLResamplerParameters}
          mv ${OFOLDER}/r-c${num}-${j}_FinalS.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd
          exitIfError "${Resampler}-c${num}-${j}"
        fi

        CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
      fi 
    done

    #################################
    #### ANTS BASED REGISTRATION ####
    #################################
    elif [[ ${POPULATION_ALIGNMENT_ALGORITHM} -eq 1 ]]; then
      #----------------------------#
      #---- Rigid Registration ----#
      #----------------------------#
      CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid"
      if [ $? -eq 0 ]; then
        echo "- Use previously estimated rigid registration."
        echo
      else
        crlRigidRegistration ${t1wTarget} ${TEMPLATES_FOLDER}/c${num}-t1w.nrrd ${OFOLDER}/c${num}-ToTarget-Rigid.nrrd ${OFOLDER}/c${num}-ToTarget-Rigid.txt --metricName mi
        exitIfError "crlRigidRegistration"

        CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Rigid" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Rigid.txt"
      fi
      
      #-----------------------------#
      #---- Affine Registration ----#
      #-----------------------------#
      CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine"
      if [ $? -eq 0 ]; then
        echo "- Use previously estimated affine registration."
        echo
      else
        crlAffineRegistration ${t1wTarget} ${TEMPLATES_FOLDER}/c${num}-t1w.nrrd ${OFOLDER}/c${num}-ToTarget-Affine.nrrd ${OFOLDER}/c${num}-ToTarget-Affine.txt ${OFOLDER}/c${num}-ToTarget-Rigid.txt --metricName mi
        exitIfError "crlAffineRegistration"

        CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Affine" "${T1W_REF}" "${OFOLDER}/c${num}-ToTarget-Affine.txt"
      fi
 
      #-------------------------------------#
      #---- ANTs Non-Rigid Registration ----#
      #-------------------------------------#
      CACHE_DoStepOrNot "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp"
      if [ $? -eq 0 ]; then
        echo "- Use previously estimated registration."
        echo
      else
        if [[ ${Population} == "ICC" ]]; then
          cp ${OFOLDER}/c${num}-ToTarget-Affine.txt ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz
        elif [[ ${Population} == "RefinedICC" ]]; then
          ${Registration} 3 -m CC[${t1wTarget},${TEMPLATES_FOLDER}/c${num}-t1w.nrrd,0.5,2] -m CC[${t2wTarget},${TEMPLATES_FOLDER}/c${num}-t2w.nrrd,0.5,2] -o ${OFOLDER}/c${num}-ToTarget -a ${OFOLDER}/c${num}-ToTarget-Affine.txt ${ANTSParameters}
          exitIfError "${Registration}"

          mv ${OFOLDER}/c${num}-ToTargetWarp.nii.gz ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz
          mv ${OFOLDER}/c${num}-ToTargetInverseWarp.nii.gz ${OFOLDER}/c${num}-ToTarget-InverseWarp.nii.gz
        fi

        CACHE_StepHasBeenDone "${Population}-${RegistrationTitle}-Template${num}-To-Target-Warp" "${T1W_REF},${T2W_REF}" "${OFOLDER}/c${num}-ToTarget-Warp.nii.gz"
      fi

      #----------------------------------------#
      #---- Resample Template Label Images ----#
      #----------------------------------------#
      for j in ${TEMPLATESMODALITIES}; do
        CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
         if [[ ${Population} == "ICC" ]]; then
            ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${t1wTarget} ${OFOLDER}/c${num}-ToTarget-Affine.txt
            exitIfError "${Resampler}-c${num}-${j}"
          else
            ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${t1wTarget} ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz ${OFOLDER}/c${num}-ToTarget-Affine.txt
            exitIfError "${Resampler}-c${num}-${j}"
          fi
         
          CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi 
      done 

      for j in ${TEMPLATESLABELMASK}; do
        CACHE_DoStepOrNot "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}"
        if [ $? -eq 0 ]; then
          echo "- Use previously resampled ${Population} template-${num}-${j}"
          echo
        else
          if [[ ${Population} == "ICC" ]]; then
            ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${t1wTarget} ${OFOLDER}/c${num}-ToTarget-Affine.txt --use-NN
            exitIfError "${Resampler}-c${num}-${j}"
          else
            ${Resampler} 3 ${TEMPLATES_FOLDER}/c${num}-${j}.nrrd ${OFOLDER}/r-c${num}-${j}.nrrd -R ${t1wTarget} ${OFOLDER}/c${num}-ToTarget-Warp.nii.gz ${OFOLDER}/c${num}-ToTarget-Affine.txt --use-NN
            exitIfError "${Resampler}-c${num}-${j}"
          fi

          CACHE_StepHasBeenDone "${Population}-${StrategyTitle}-${RegistrationTitle}-Template-${num}-${j}" "${T1W_REF},${T2W_REF}" "${OFOLDER}/r-c${num}-${j}.nrrd"
        fi 
      done      

    fi
}

function doPopulationAlignment_SCALAR()
{
  #--------------------------------#
  #---- Check for Dependencies ----#
  #--------------------------------#
  local Population=$1
  local t1wTarget=$2
  local t2wTarget=$3
  
  local RegistrationTitle=""
  if [[ ${POPULATION_ALIGNMENT_ALGORITHM} == 0 ]]; then
    RegistrationTitle="crlRegistration"
  else
    RegistrationTitle="ANTS"
  fi

  local StrategyTitle=""
  if [[ ${POPULATION_ALIGNMENT_STRATEGY} == 1 ]]; then
    StrategyTitle="Composed"
  else
    StrategyTitle="Direct"
  fi
  
  showStepTitle "${Population} Reference - ${StrategyTitle} Registration - ${RegistrationTitle} Algorithm"

  OFOLDER="${folder}/modules/ReferencePopulationAlignment/${Population}"
  mkdir -p "${OFOLDER}"

  prevdir=`pwd`
  cd ${OFOLDER}

  #---- Initialize Registration Algorithm Variables ----#
  doInitializeRegistration ${Population}

  #---- Initialize Reference Population Variables ----#
  doInitializePopulation "${Population}"

  #---- Correct Intensity Inhomogeneity of Target Images ----#
  #if [ -x ${CRLThirdParty}/ANTs/bin/N4BiasFieldCorrection ]; then
  #  ${CRLThirdParty}/ANTs/bin/N4BiasFieldCorrection -i ${t1wTarget} -o "${OFOLDER}/in-t1w-Target.nrrd"
  #  ${CRLThirdParty}/ANTs/bin/N4BiasFieldCorrection -i ${t2wTarget} -o "${OFOLDER}/in-t2w-Target.nrrd"
  #else
  #  cp ${t1wTarget} "${OFOLDER}/in-t1w-Target.nrrd"
  #  cp ${t2wTarget} "${OFOLDER}/in-t2w-Target.nrrd"
  #fi
  
  if [ -x crlN4BiasFieldCorrection ]; then
    crlN4BiasFieldCorrection ${t1wTarget} ${OFOLDER}/in-t1w-Target.nrrd
    crlN4BiasFieldCorrection ${t2wTarget} ${OFOLDER}/in-t2w-Target.nrrd
  else
    cp ${t1wTarget} "${OFOLDER}/in-t1w-Target.nrrd"
    cp ${t2wTarget} "${OFOLDER}/in-t2w-Target.nrrd"
  fi

  #---- Compute Reference Population Alignment ----#
  if [[ ${POPULATION_ALIGNMENT_STRATEGY} == 1 ]]; then
    doPopulationAlignment_COMPOSED "${Population}" "${OFOLDER}/in-t1w-Target.nrrd" "${OFOLDER}/in-t2w-Target.nrrd"
  else
    nThreadPerTemplate=`echo "scale=10; n=(${NBTHREADS}/${TEMPLATESNUMBER}+0.5); scale=0; n/1 " | bc`		# Number of threads... depends on number of templates
    if [[ $nThreadPerTemplate -eq 0 ]]; then
      nThreadPerTemplate=1
    fi
    echo "Alignment of ${TEMPLATESNUMBER} templates with ${NBTHREADS} threads -> Uses ${nThreadPerTemplate} threads per template"

    #---- We are going to run multiple registrations in parallel ----#
    export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${nThreadPerTemplate}

    npr=0
    tcount=0
    total=$(( ${TEMPLATESNUMBER}+1 ))
    while( [ ${tcount} -lt ${total} ] ); do
      while ( [ ${npr} -lt ${NBTHREADS} ] ); do
        if [ ${tcount} -lt ${total} ]; then
          num=$(printf %03d ${tcount})        
          echo "Estimating alignment of Reference${num}..."
          doPopulationAlignment_DIRECT "${Population}" "${num}" "${OFOLDER}/in-t1w-Target.nrrd" "${OFOLDER}/in-t2w-Target.nrrd" > "${OFOLDER}/${Population}-Reference${num}-AlignmentLog.txt" ${nThreadPerTemplate} &          
        
          npr=$[ ${npr} + 1 ]
          tcount=$[ ${tcount} + 1 ]
        else
          npr=${NBTHREADS}
        fi
      done

      wait
      npr=0
    done
  fi 

  export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=${NBTHREADS}

  exportVariable "${Population}_ALIGNED_REFERENCE_FOLDER" "${OFOLDER}"

  cd "$prevdir"

}

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "`dirname $0`/../../../ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

doPopulationAlignment_SCALAR "$1" "$2" "$3"

