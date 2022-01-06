#!/bin/sh

#=================================================================
# ANATOMICAL ANALYSIS PIPELINE
# Benoit Scherrer, CRL, 2011
#-----------------------------------------------------------------
# ref computed with: crlResampler2 -i refspace_src.nrrd --voxelsize 0.8,0.8,0.8 -o refspace.nrrd --interp linear -p 20
#=================================================================
umask 002

#------------------------------------------
# Load the scan informations
#------------------------------------------
source "`dirname $0`/../../ScanInfo.sh" || exit 1
prevdir=`pwd`

#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1

#------------------------------------------
# Get files in the data for analysis
#------------------------------------------
dfa=`getDataForAnalysis`

if [ -d "$dfa" ]; then
  acrt1w=`find -L "$dfa"/ -type f -name \*acrt1w.nrrd | head -1`
  acrt2w=`find -L "$dfa"/ -type f -name \*acrt2w.nrrd | head -1`
  sitet1w=`find -L "$dfa"/ -type f -name \*sitet1w.nrrd | head -1`
  sitet2w=`find -L "$dfa"/ -type f -name \*sitet2w.nrrd | head -1`
fi


folder="$ScanProcessedDir/common-processed"

function doIt()
{
  TYPE=$1
  T1W="$2"
  T2W="$3"
  prefix2="${prefix}${TYPE}"
  AtlasFolder="${SrcScriptDir}/04.acr"

  exportVariable "${TYPE}_T1W" "$t1w"
  exportVariable "${TYPE}_T2W" "$t2w"


  #=============================================================
  # STEP1 - Co-registration to reference
  #=============================================================
  OUTPUTFOLDER="${folder}/${TYPE}/01-commonspace"
  mkdir -p "$OUTPUTFOLDER"

  showStepTitle "Registration $TYPE to common space"
  CACHE_DoStepOrNot "${TYPE}_REGISTRATION" "1.04"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed registration."
  else
    echo "$T1W -> ${AtlasFolder}/refspace.nrrd"
    crlOrientImage "$T1W" $OUTPUTFOLDER/tmp.nrrd
    crlResampler2 --voxelsize 0.5,0.5,1 -i $OUTPUTFOLDER/tmp.nrrd -o $OUTPUTFOLDER/tmp.nrrd --interp nearest
    crlRigidRegistration "${AtlasFolder}/refspace.nrrd" "$OUTPUTFOLDER/tmp.nrrd" "${OUTPUTFOLDER}/${prefix2}_t1w_rlin.nrrd" "${OUTPUTFOLDER}/${prefix2}_t1w_r.tfm" --metricName mi
    crlResampler2 -i "$OUTPUTFOLDER/tmp.nrrd" -o "${OUTPUTFOLDER}/${prefix2}_t1w_r.nrrd" -g "${AtlasFolder}/refspace.nrrd" -t "${OUTPUTFOLDER}/${prefix2}_t1w_r.tfm" --interp nearest
    exitIfError "Rigid registration"
 
    echo "$T2W -> ${AtlasFolder}/refspace.nrrd"
    crlOrientImage "$T2W" $OUTPUTFOLDER/tmp.nrrd
    crlResampler2 --voxelsize 0.5,0.5,1 -i $OUTPUTFOLDER/tmp.nrrd -o $OUTPUTFOLDER/tmp.nrrd --interp nearest
    crlRigidRegistration "${AtlasFolder}/refspace.nrrd" "$OUTPUTFOLDER/tmp.nrrd" "${OUTPUTFOLDER}/${prefix2}_t2w_rlin.nrrd" "${OUTPUTFOLDER}/${prefix2}_t2w_r.tfm" --metricName mi
    crlResampler2 -i "$OUTPUTFOLDER/tmp.nrrd" -o "${OUTPUTFOLDER}/${prefix2}_t2w_r.nrrd" -g "${AtlasFolder}/refspace.nrrd" -t "${OUTPUTFOLDER}/${prefix2}_t2w_r.tfm" --interp nearest
    exitIfError "Rigid registration"
  
    rm -f $OUTPUTFOLDER/tmp.nrrd

    exportVariable "${TYPE}_T1Wref" "${OUTPUTFOLDER}/${prefix2}_t1w_r.nrrd"
    exportVariable "${TYPE}_T2Wref" "${OUTPUTFOLDER}/${prefix2}_t2w_r.nrrd"

    CACHE_StepHasBeenDone "${TYPE}_REGISTRATION" "$T1W,$T2W,${AtlasFolder}/refspace.nrrd" "${OUTPUTFOLDER}/${prefix2}_t1w_r.nrrd,${OUTPUTFOLDER}/${prefix2}_t1w_r.tfm,${OUTPUTFOLDER}/${prefix2}_t2w_r.nrrd,${OUTPUTFOLDER}/${prefix2}_t2w_r.tfm"
  fi
  echo ""
 
  OUTPUTFOLDER="${folder}/${TYPE}/02-roistats"
  mkdir -p "$OUTPUTFOLDER"

  showStepTitle "ROI analysis"
  
  CACHE_DoStepOrNot "${TYPE}_CNRROIANALYSIS" "1.06"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed registration."
  else
    function computeCnr()
    {
      local inImage=$1
      local outBaseStatFile=$2
      local str=`crlImageStatsLabelled -l "$AtlasFolder/rois.nrrd" -i "$inImage" | grep Mean`
      local meanBG=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean2=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean3=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean4=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean5=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean6=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`

      local str=`crlImageStatsLabelled -l "$AtlasFolder/rois.nrrd" -i "$inImage" | grep Variance`
      local varianceBG=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance2=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance3=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance4=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance5=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance6=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`

      echo "meanBG <$meanBG>" > $outBaseStatFile
      echo "varBG <$varianceBG>" >> $outBaseStatFile
      echo "meanLabel2 <$mean2>" >> $outBaseStatFile
      echo "varLabel2 <$variance2>" >> $outBaseStatFile
      echo "meanLabel3 <$mean3>" >> $outBaseStatFile
      echo "varLabel3 <$variance3>" >> $outBaseStatFile
      echo "meanLabel4 <$mean4>" >> $outBaseStatFile
      echo "varLabel4 <$variance4>" >> $outBaseStatFile
      echo "meanLabel5 <$mean5>" >> $outBaseStatFile
      echo "varLabel5 <$variance5>" >> $outBaseStatFile
      echo "meanLabel6 <$mean6>" >> $outBaseStatFile
      echo "varLabel6 <$variance6>" >> $outBaseStatFile

      #local cnr=`echo "scale=4;($mean3-$mean2)/$varianceBG"|bc`
     # local cnr=`echo "scale=4;a=$cnr;if(0>a)a*=-1;a"|bc`

     # local snr=`echo "scale=4;$variance3/$varianceBG"|bc`

     # echo "$cnr" > ${outBaseStatFile}_cnr.txt
     # echo "# ($mean3 - $mean2) / $varianceBG " >> ${outBaseStatFile}_cnr.txt

     # echo "$snr" > ${outBaseStatFile}_snr.txt
      #echo "# $variance3/$varianceBG" >> ${outBaseStatFile}_snr.txt
    }

    t1wref="${TYPE}_T1Wref"
    t1wref=${!t1wref}
    computeCnr $t1wref "${OUTPUTFOLDER}/${TYPE}_t1w_roistats.txt"

    t2wref="${TYPE}_T2Wref"
    t2wref=${!t2wref}
    computeCnr $t2wref "${OUTPUTFOLDER}/${TYPE}_t2w_roistats.txt"

    CACHE_StepHasBeenDone "${TYPE}_CNRROIANALYSIS" "$t1wref,$t2wref,$AtlasFolder/rois.nrrd" "${OUTPUTFOLDER}/${TYPE}_t2w_roistats.txt,${OUTPUTFOLDER}/${TYPE}_t1w_roistats.txt"
  fi
  echo ""
}



function doIt2()
{
  TYPE=$1
  MODALITY="$2"
  IMG="$3"
  
  prefix2="${prefix}${TYPE}"
  AtlasFolder="${SrcScriptDir}/04.acr"

  exportVariable "${TYPE}_${MODALITY}" "$IMG"

  #=============================================================
  # STEP1 - Co-registration to reference
  #=============================================================
  OUTPUTFOLDER="${folder}/${TYPE}/01-commonspace"
  mkdir -p "$OUTPUTFOLDER"

  showStepTitle "Registration $TYPE ${MODALITY} to common space"
  CACHE_DoStepOrNot "${TYPE}_${MODALITY}_REGISTRATION" "1.04"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed registration."
  else
    echo "$IMG -> ${AtlasFolder}/refspace.nrrd"
    crlOrientImage "$IMG" $OUTPUTFOLDER/tmp.nrrd
    crlResampler2 --voxelsize 0.5,0.5,1 -i $OUTPUTFOLDER/tmp.nrrd -o $OUTPUTFOLDER/tmp.nrrd --interp nearest
    crlRigidRegistration "${AtlasFolder}/refspace.nrrd" "$OUTPUTFOLDER/tmp.nrrd" "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_rlin.nrrd" "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.tfm" --metricName mi
    crlResampler2 -i "$OUTPUTFOLDER/tmp.nrrd" -o "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.nrrd" -g "${AtlasFolder}/refspace.nrrd" -t "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.tfm" --interp nearest
    exitIfError "Rigid registration"
 
  
  
    rm -f $OUTPUTFOLDER/tmp.nrrd

    exportVariable "${TYPE}_${MODALITY}ref" "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.nrrd"

    CACHE_StepHasBeenDone "${TYPE}_${MODALITY}_REGISTRATION" "$IMG,${AtlasFolder}/refspace.nrrd" "${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.nrrd,${OUTPUTFOLDER}/${prefix2}_${MODALITY}_r.tfm"
  fi
  echo ""
 
  OUTPUTFOLDER="${folder}/${TYPE}/02-roistats"
  mkdir -p "$OUTPUTFOLDER"

  showStepTitle "ROI $TYPE ${MODALITY} analysis"
  
  CACHE_DoStepOrNot "${TYPE}_${MODALITY}_CNRROIANALYSIS" "1.08"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed stats."
  else
    function computeCnr()
    {
      local inImage=$1
      local outBaseStatFile=$2

      # Check if we have the right version of crlImageStatsLabelled
      crlImageStatsLabelled -l "$AtlasFolder/rois.nrrd" -i "$inImage" 
      exitIfError "crlImageStatsLabelled"

      local str=`crlImageStatsLabelled -l "$AtlasFolder/rois.nrrd" -i "$inImage" | grep Mean`
      echo "Mean: $str"
      local meanBG=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean2=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean3=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean4=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean5=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local mean6=`echo "$str" | sed -e 's/.*Mean, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`

      local str=`crlImageStatsLabelled -l "$AtlasFolder/rois.nrrd" -i "$inImage" | grep Variance`
      exitIfError "crlImageStatsLabelled"
      echo "Variance: $str"
      local varianceBG=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance2=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance3=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance4=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance5=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`
      local variance6=`echo "$str" | sed -e 's/.*Variance, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, [0-9.]*, \([0-9.]*\).*/\1/'`

      echo "meanBG <$meanBG>" > $outBaseStatFile
      echo "varBG <$varianceBG>" >> $outBaseStatFile
      echo "meanLabel2 <$mean2>" >> $outBaseStatFile
      echo "varLabel2 <$variance2>" >> $outBaseStatFile
      echo "meanLabel3 <$mean3>" >> $outBaseStatFile
      echo "varLabel3 <$variance3>" >> $outBaseStatFile
      echo "meanLabel4 <$mean4>" >> $outBaseStatFile
      echo "varLabel4 <$variance4>" >> $outBaseStatFile
      echo "meanLabel5 <$mean5>" >> $outBaseStatFile
      echo "varLabel5 <$variance5>" >> $outBaseStatFile
      echo "meanLabel6 <$mean6>" >> $outBaseStatFile
      echo "varLabel6 <$variance6>" >> $outBaseStatFile

      #local cnr=`echo "scale=4;($mean3-$mean2)/$varianceBG"|bc`
     # local cnr=`echo "scale=4;a=$cnr;if(0>a)a*=-1;a"|bc`

     # local snr=`echo "scale=4;$variance3/$varianceBG"|bc`

     # echo "$cnr" > ${outBaseStatFile}_cnr.txt
     # echo "# ($mean3 - $mean2) / $varianceBG " >> ${outBaseStatFile}_cnr.txt

     # echo "$snr" > ${outBaseStatFile}_snr.txt
      #echo "# $variance3/$varianceBG" >> ${outBaseStatFile}_snr.txt
    }

    imgref="${TYPE}_${MODALITY}ref"
    imgref=${!imgref}


    echo "Compute statistics..."
    echo "Registred image is $imgref"
    computeCnr $imgref "${OUTPUTFOLDER}/${TYPE}_${MODALITY}_roistats.txt"

    CACHE_StepHasBeenDone "${TYPE}_${MODALITY}_CNRROIANALYSIS" "$imgref,$AtlasFolder/rois.nrrd" "${OUTPUTFOLDER}/${TYPE}_${MODALITY}_roistats.txt"
  fi
  echo ""
}


if [ ! -z "$acrt1w" ]; then
  doIt2 "ACR" "T1W" "$acrt1w"
fi
if [ ! -z "$acrt2w" ]; then
  doIt2 "ACR" "T2W" "$acrt2w"
fi


if [ ! -z "$sitet1w" ]; then
  doIt2 "SITE" "T1W" "$sitet1w"
fi
if [ ! -z "$sitet2w" ]; then
  doIt2 "SITE" "T2W" "$sitet2w"
fi

echo ""


