#!/bin/sh

#=================================================================
# ANATOMICAL ANALYSIS PIPELINE
# Benoit Scherrer, CRL, 2011
#-----------------------------------------------------------------
# 
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
source $ScriptDir/common/HtmlReportManager.txt || exit 1

exportVariable "PATIENT_NAME" "$PatientName"
exportVariable "PATIENT_MRN" "$MRN"
exportVariable "PATIENT_BIRTHDATE" "$DOB"
exportVariable "PATIENT_ACQDATE" "$AcquisitionDate"
exportVariable "PATIENT_SEX" "$PatientSex"
exportVariable "PATIENT_DICOMAGE" "$PatientDicomAge"
exportVariable "PATIENT_MONTH_AGE" "$PatientMonthAge"
exportVariable "PATIENT_YEAR_AGE" "$PatientYearAge"
exportVariable "ScannerManufacturer" "$ScannerManufacturer"
exportVariable "InstitutionName" "$InstitutionName"

echo
echo "================== PATIENT INFOS ====================="
echo "PATIENT NAME      : $PATIENT_NAME"
echo "PATIENT MRN       : $PATIENT_MRN"
echo "PATIENT AGE       : ${PATIENT_MONTH_AGE}M (${PATIENT_YEAR_AGE}Y)"
echo "PATIENT BIRTHDATE : $PATIENT_BIRTHDATE"
echo "PATIENT ACQDATE   : $PATIENT_ACQDATE"
echo "PATIENT SEX       : $PATIENT_SEX"
echo "PREFIX            : ${prefix}"
echo "======================================================"
echo

#------------------------------------------
# Init report
#------------------------------------------
if [[ $CREATE_REPORT -eq 1 ]]; then
  cp $ScriptDir/common/reportstyle.css $ReportDir

  ReportHtmlFile="${ReportDir}/index.html"

  echo "<html>" > ${ReportHtmlFile}
  echo "<head>" >> ${ReportHtmlFile}
  echo "  <link rel='stylesheet' type='text/css' href='reportstyle.css'>" >> ${ReportHtmlFile}
  echo '  <script language="javascript" type="text/javascript">function resizeIframe(obj) { obj.style.height = obj.contentWindow.document.body.scrollHeight + "px"; }</script>' >> ${ReportHtmlFile}
  echo "</head>" >> ${ReportHtmlFile}
  echo "<body>" >> $ReportHtmlFile
  echo "<div class='title'>CRL Analysis Pipeline</div>" >> $ReportHtmlFile

  echo "<br /><table width='60%'> 
<tr> <td>Name</td> <td>$PATIENT_NAME </td> </tr>
<tr> <td>MRN</td> <td>$PATIENT_MRN </td> </tr>
<tr> <td>Age</td> <td>${PATIENT_MONTH_AGE}M (${PATIENT_YEAR_AGE}Y) </td> </tr>
<tr> <td>Birthdate</td> <td>$PATIENT_BIRTHDATE </td> </tr>
<tr> <td>Acquisition date</td> <td>$PATIENT_ACQDATE </td> </tr>
<tr> <td>Sex</td> <td>$PATIENT_SEX </td> </tr>
<tr> <td>Pipeline prefix</td> <td>${prefix} </td> </tr>
</table>" >> $ReportHtmlFile

fi


dfa=`getDataForAnalysis`


#------------------------------------------
# HR RECON
#------------------------------------------
PREVIFS=$IFS
IFS=$'\n'
reconfolders=($(find "$dfa"/ -mindepth 1 -maxdepth 1 -type d -name \*hrrecon_\* ))
IFS=$PREVIFS

for d in ${reconfolders[*]}
do
  reconfolder=`basename $d`
  resolution=`echo "$reconfolder" | sed -e 's/^hrrecon_\([0-9\.]*\)_.*/\1/'`
  outputnrrd=`echo "$reconfolder" | sed -e 's/^hrrecon_[0-9\.]*_\(.*\)/\1/'`
  outputnrrd="$dfa/$outputnrrd"

  echo "HR RECON ($reconfolder)"

  #---------------------------------------------
  # Try to find an axial scan first
  #---------------------------------------------
  f=`find "$d"/ -mindepth 1 -maxdepth 1 -type f -iname \*ax\*.nrrd`

  #---------------------------------------------
  # If found, add it first and then add other files
  #---------------------------------------------
  deps=""
  inputFiles=""
  if [[ -f $f ]]; then
    inputFiles="-i $f"    
    deps="$f"
    IFS=$'\n' 
    reconfiles=($(find "$d"/ -mindepth 1 -maxdepth 1 -type f -not -iname \*ax\*.nrrd -name \*.nrrd))
    IFS=$PREVIFS
    for f in ${reconfiles[*]}
    do
      inputFiles="$inputFiles -i $f"
      deps="$deps,$f"
    done

  #---------------------------------------------
  # Else just add all files from directory
  #---------------------------------------------
  else
    IFS=$'\n' 
    reconfiles=($(find "$d"/ -mindepth 1 -maxdepth 1 -type f -name \*.nrrd ))
    IFS=$PREVIFS
    for f in ${reconfiles[*]}
    do
      inputFiles="$inputFiles -i $f"
      deps="$deps,$f"
    done
  fi
  
  #---------------------------------------------
  # NOW do the actual step
  #---------------------------------------------
  stepid="HRRECON_${reconfolder}"
  showStepTitle "HR Recon of $outputnrrd"
  CACHE_DoStepOrNot "$stepid"
  if [ $? -eq 0 ]; then
      echo "- Use previously recon image."
  else
     echo "RESOLUTION: $resolution"
     echo "OUTPUT    : $outputnrrd"
     echo "INPUTS:   : $inputFiles"
     echo
     echo "RUN RECON..."
     echo "crlDWIHighRes $inputFiles --iso ${resolution} -o ${outputnrrd} --interp sinc -p ${NBTHREADS}" > $d/recon.cmdline.txt
     crlDWIHighRes $inputFiles --iso ${resolution} -o ${outputnrrd} --interp sinc -p ${NBTHREADS}

     CACHE_StepHasBeenDone "$stepid" "$deps" "$outputnrrd"
  fi
  echo

done



#------------------------------------------
# Convert nii -> nrrd if necessary
# (using the cache manager)
#------------------------------------------
find "$dfa"/ -mindepth 1 -maxdepth 1 -type f -name \*.nii\* | sort -n | while read niiFile
do
    nrrdfile=`echo "$niiFile" | sed 's/.gz//g'`
    nrrdfile=`echo "$nrrdfile" | sed 's/.nii/.nrrd/g'`

    stepid=CONVERT_`basename "$niiFile"`
    showStepTitle "Convert $niiFile to nrrd"
    CACHE_DoStepOrNot "$stepid"
    if [ $? -eq 0 ]; then
      echo "- Use previously converted image."
    else
      crlConvertBetweenFileFormats -in "$niiFile" -out $nrrdfile
      CACHE_StepHasBeenDone "$stepid" "$niiFile" "$nrrdfile"
    fi
    echo

done


#------------------------------------------
# Get files in the data for analysis
#------------------------------------------
if [ -d "$dfa" ]; then
  t1w=`find -L "$dfa"/ -type f -name \*bestt1w.nrrd | head -1`
  t2w=`find -L "$dfa"/ -type f -name \*bestt2w.nrrd | head -1`
  flair=`find -L "$dfa"/ -type f -name \*FLAIR.nrrd  | head -1`
  cpmg=`find -L "$dfa"/ -type f -name \*CPMG.nrrd  | head -1` ## SV407 - added the following section (copy for flair)
  ct=`find -L "$dfa"/ -type f -name \*CT.nrrd | head -1`
fi
#sv407 if [ ! -z "$t1w" ] && [ ! -z "$t2w" ] ; then
if [ ! -z "$t1w" ] ; then
  echo "   FOUND T1W $t1w"
#  echo "   FOUND T2W $t2w"
else
  echo "-------------------------------------------------------"
  echo " ERROR. The files *bestt1w.nrrd and *bestt2w.nrrd were"
  echo " not found in the ./data_for_analysis folder"
  echo " CANNOT CONTINUE."
  echo "---------------------------------------------------"
  echo ""
  exit 1;
fi

exportVariable "T1W" "$t1w"
exportVariable "T2W" "$t2w"
exportVariable "FLAIR" "$flair"
exportVariable "CPMG" "$cpmg" ## SV407 - added the following section (copy for flair)
exportVariable "CT" "$ct"

folder="$ScanProcessedDir/common-processed"

#=============================================================
# STEP1 - Resample the T1w and T2w to isotropic
#=============================================================
OUTPUTFOLDER="${folder}/anatomical/01-t1w-ref"
mkdir -p "$OUTPUTFOLDER"

showStepTitle "Compute reference T1-w"
CACHE_DoStepOrNot "T1_REF"
if [ $? -eq 0 ]; then
  echo "- Use previously computed T1w reference image."
else
  s=`crlImageInfo "$t1w" | grep Spacing`
  s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`

  sx=`echo "$s" | sed -e "s/\([0-9.]*\).*/\1/"`
  sy=`echo "$s" | sed -e "s/[0-9.]*, \([0-9.]*\).*/\1/"`
  sz=`echo "$s" | sed -e "s/[0-9].*, [0-9.]*, \([0-9.]*\).*/\1/"`
  echo "- Extracted Image Spacing: $sx, $sy, $sz"

  max=`getMaxFloat "$sx" "$sy"`
  max=`getMaxFloat "$max" "$sz"`

  min=`getMinFloat "$sx" "$sy"`
  min=`getMinFloat "$min" "$sz"`

  r=`echo "scale=2;$max/$min"|bc`
  echo "- Ratio MaxSpacing/MinSpacing = $r"

  if [ $(echo "$r > 1.5"|bc) -eq 1 ]; then 
    echo "- Convert to isotropic (MaxSpacing/MinSpacing>1.5)"
    crlResampleToIsotropic -x "$min" -y "$min" -z "$min" "$t1w" linear "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd" 
    exitIfError "crlResampleToIsotropic"
  
    crlOrientImage "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd" "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd" 
    exitIfError "crlOrientImage"
    exportVariable "T1W_REF_RESAMPLED_TO_ISO" "1"
  else
    echo "- Keep current resolution (MaxSpacing/MinSpacing<1.5)"
    echo "- Orient image in axial"
    crlOrientImage "$t1w" "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd" 
    exitIfError "crlOrientImage"
    exportVariable "T1W_REF_RESAMPLED_TO_ISO" "0"
  fi

  exportVariable "T1W_REF" "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd"

  s=`crlImageInfo "$OUTPUTFOLDER/${prefix}t1w_ref.nrrd" | grep Spacing`
  s=`echo "$s" | sed -e "s/Spacing: \[\(.*\)\]/\1/"`
  exportVariable "T1W_REF_SPACING" "$s"

  CACHE_StepHasBeenDone "T1_REF" "$t1w" "${T1W_REF}"
fi
echo ""


#=============================================================
# STEP2 - Co-registration of T2 to T1
#=============================================================
OUTPUTFOLDER="${folder}/anatomical/02-coregistration"
mkdir -p "$OUTPUTFOLDER"


#sv407 
if [ ! -z "$T2W" ] && [ -f "$T2W" ]; then
	showStepTitle "T2 -> T1 rigid registration"
	CACHE_DoStepOrNot "REG_T2_to_T1" 
	if [ $? -eq 0 ]; then
	  echo "- Use previously computed registration."
	else
	  OFILE="$OUTPUTFOLDER/${prefix}t2w_r.nrrd"
	  OTRSF="$OUTPUTFOLDER/${prefix}t2w_r.tfm"
	  echo "DOING THIS crlRigidRegistration --metricName mi $T1W_REF $T2W $OFILE $OTRSF"
	  crlRigidRegistration --metricName mi "$T1W_REF" "$T2W" "$OFILE" "$OTRSF"
	  exitIfError "Rigid registration"
	  
	  exportVariable "T2toT1_trsf" "$OTRSF"
	  exportVariable "T2W_REF" "$OFILE"

	  CACHE_StepHasBeenDone "REG_T2_to_T1" "$T1W_REF,$T2W" "$T2W_REF,$T2toT1_trsf"
	fi
	echo ""
fi
#=============================================================
# STEP2b - Co-registration of FLAIR to T1/T2
#=============================================================
if [ ! -z "$FLAIR" ] && [ -f "$FLAIR" ]; then
  showStepTitle "FLAIR -> T1/T2 rigid registration"
  CACHE_DoStepOrNot "REG_FLAIR_to_T1" 
  if [ $? -eq 0 ]; then
    echo "- Use previously computed registration."
  else
    OFILE="$OUTPUTFOLDER/${prefix}flair_r.nrrd"
    OTRSF="$OUTPUTFOLDER/${prefix}flair_r.tfm"
    crlRigidRegistration --metricName mi "$T1W_REF" "$FLAIR" "$OFILE" "$OTRSF"
    exitIfError "Rigid registration"
  
    exportVariable "FLAIRtoT1_trsf" "$OTRSF"
    exportVariable "FLAIR_REF" "$OFILE"

    CACHE_StepHasBeenDone "REG_FLAIR_to_T1" "$T1W_REF,$FLAIR" "$FLAIR_REF,$FLAIRtoT1_trsf"
  fi
  echo ""
fi

## SV407 - added the following section (copy for flair)
#=============================================================
# STEP2bb - Co-registration of CPMG to T1/T2
#=============================================================
if [ ! -z "$CPMG" ] && [ -f "$CPMG" ]; then
  showStepTitle "CPMG -> T1/T2 rigid registration"
  CACHE_DoStepOrNot "REG_CPMG_to_T1" 
  if [ $? -eq 0 ]; then
    echo "- Use previously computed registration."
  else
    OFILE="$OUTPUTFOLDER/${prefix}cpmg_r.nrrd"
    OTRSF="$OUTPUTFOLDER/${prefix}cpmg_r.tfm"
    crlRigidRegistration --metricName mi "$T1W_REF" "$CPMG" "$OFILE" "$OTRSF"
    exitIfError "Rigid registration"
  
    exportVariable "CPMGtoT1_trsf" "$OTRSF"
    exportVariable "CPMG_REF" "$OFILE"

    CACHE_StepHasBeenDone "REG_CPMG_to_T1" "$T1W_REF,$CPMG" "$CPMG_REF,$CPMGtoT1_trsf"
  fi
  echo ""
fi

#=============================================================
# STEP2c - Co-registration of CT to T1
#=============================================================
if [ ! -z "$CT" ] && [ -f "$CT" ]; then
  showStepTitle "CT -> T1 registration"
  CACHE_DoStepOrNot "REG_CT_to_T1"
  if [ $? -eq 0 ]; then
    echo "- Use previously computed step."
  else
    prevdir=`pwd`
    cd "$OUTPUTFOLDER"

    ## Subsample the CT image
    crlSubsampleImage3d ${CT} ${prefix}ct-subsampled.nrrd 2 2 2

    ## CT-MRI Registation
    crlRigidRegistration ${T1W_REF} ${prefix}ct-subsampled.nrrd ${prefix}ct_r.nrrd ${prefix}ct_r.tfm
    exitIfError "crlRigidRegistration"

    rm -f "${prefix}ct-subsampled.nrrd"

    exportVariable "CT_REF" "${OUTPUTFOLDER}/${prefix}ct_r.nrrd"
    exportVariable "CTtoT1_trsf" "${OUTPUTFOLDER}/${prefix}ct_r.tfm"

    cd "$prevdir"

    CACHE_StepHasBeenDone "REG_CT_to_T1" "$CT,$T1W_REF" "${OUTPUTFOLDER}/${prefix}ct_r.nrrd,${OUTPUTFOLDER}/${prefix}ct_r.tfm"
    echo
  fi
  echo ""
fi


#=============================================================
# STEP3 - ICC Extraction. Use old or new strategy
#=============================================================
OUTPUTFOLDER="${folder}/anatomical/03-ICC"
mkdir -p "$OUTPUTFOLDER"

#------------------------------------------------------------
# IF THE ICC STRATEGY HAS CHANGED, FORCE THE UPDATE OF THE STEP
#------------------------------------------------------------
#if [ ! -z "${NEW_ICC_DONE}" ] && [ "${NEW_ICC_DONE}" != "${NEW_ICC_EXTRACTION}" ]; then
#  ICC_SEG_DONE=0
#fi
#if [ ! -z "${SKIP_ICC_DONE}" ] && [ "${SKIP_ICC_DONE}" != "${SKIP_ICC_EXTRACTION}" ]; then
#  ICC_SEG_DONE=0
#fi

#------------------------------------------------------------
# Following: Only if single subject mode (ie BaseRawDir is empty)
#------------------------------------------------------------
if [[ -z "${BaseRawDir}" ]]; then
  CACHE_RedoStepIfValueChanged "ICC_SEG" "ICC_STRATEGY" "${ICC_STRATEGY}"
  CACHE_RedoStepIfValueChanged "ICC_SEG" "POPULATION_ALIGNMENT_STRATEGY" "${POPULATION_ALIGNMENT_STRATEGY}"
  CACHE_RedoStepIfValueChanged "ICC_SEG" "SKIP_ICC_EXTRACTION" "${SKIP_ICC_EXTRACTION}"
fi


showStepTitle "ICC segmentation"
CACHE_DoStepOrNot "ICC_SEG"
if [ $? -eq 0 ]; then
  echo "- Use previously computed ICC segmentation."

  if [[ ! -f "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" ]]; then
    cp "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd"

    exportVariable "BRAIN_MASK" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd"
  fi
else
  prevdir=`pwd`

  if [[ ${SKIP_ICC_EXTRACTION} -eq 1 ]]; then
    crlScalarImageAlgebra -i "$T1W_REF" -s "v1!=0?1:0" -o "$OUTPUTFOLDER/${prefix}ICC.nrrd"
    exitIfError "crlScalarImageAlgebra"
     
    if [[ ! -f "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" ]]; then
      cp "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd"

      exportVariable "BRAIN_MASK" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd"
    fi

    exportVariable "ICC_MASK" "$OUTPUTFOLDER/${prefix}ICC.nrrd"

  else
    #------------------------------------------#
    #---- CONSTRUCT THE VECTOR INPUT IMAGE ----#
    #------------------------------------------#
    mkdir -p "$OUTPUTFOLDER/tmp"
    #cd "$OUTPUTFOLDER/tmp"
    TMPVECFILE="$OUTPUTFOLDER/tmp/input.nrrd"

    if [[ -f "$FLAIR" ]] && [[ -f "$FLAIR_REF" ]] ; then
      crlConstructVectorImage "$T1W_REF" "$T2W_REF" "$FLAIR_REF" $TMPVECFILE
    else
      crlConstructVectorImage "$T1W_REF" "$T2W_REF" $TMPVECFILE
    fi
    exitIfError "crlConstructVectorImage"

    if [[ ${ICC_STRATEGY} -eq 1 ]]; then
      #echo "Intensity/Label Based ICC"
      #if [[ ${POPULATION_ALIGNMENT_STRATEGY} -eq 0 ]]; then
        #---- Sequential Population Alignment ----#
        #echo "- Intensity Based ICC - Sequential Population Alignment"
        #sh "$ScriptDir/01.anatomical/icc-segmentation_NEW.sh" "$TMPVECFILE" "$OUTPUTFOLDER/tmp"  "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" $NBTHREADS  
      #else
        #---- Composed Population Alignment ----#
        #echo "- Intensity Based ICC - Composed Population Alignment"
        #sh "$ScriptDir/01.anatomical/icc-segmentation_composed.sh" "$TMPVECFILE" "$OUTPUTFOLDER/tmp"  "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" $NBTHREADS
      #fi

      sh "$ScriptDir/01.anatomical/ICC-Segmentation_LabelBased.sh" "$TMPVECFILE" "$OUTPUTFOLDER/tmp" "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" "$OUTPUTFOLDER/${prefix}TissueSegmentation.nrrd" $NBTHREADS

    else
      echo "Label Fusion Based ICC"
      sh "$ScriptDir/01.anatomical/ICC-Segmentation_LabelBased.sh" "$TMPVECFILE" "$OUTPUTFOLDER/tmp" "$OUTPUTFOLDER/${prefix}ICC.nrrd" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd" "$OUTPUTFOLDER/${prefix}TissueSegmentation.nrrd" $NBTHREADS
    fi

    exitIfError "ICC Segmentation scripts"
  
    #if [ ! -z "$OUTPUTFOLDER" ]; then
    #  rm -Rf "$OUTPUTFOLDER/tmp"
    #fi

   cd "$prevdir"

    exportVariable "ICC_MASK" "$OUTPUTFOLDER/${prefix}ICC.nrrd"
    exportVariable "BRAIN_MASK" "$OUTPUTFOLDER/${prefix}BrainMask.nrrd"
    exportVariable "TISSUES_MASK" "$OUTPUTFOLDER/${prefix}TissueSegmentation.nrrd"
  fi

  exportVariable "NEW_ICC_DONE" "${NEW_ICC_EXTRACTION}"
  exportVariable "SKIP_ICC_DONE" "${SKIP_ICC_EXTRACTION}"


  CACHE_StepHasBeenDone "ICC_SEG" "$T1W_REF,$T2W" "$ICC_MASK"
fi
echo ""

exportVariable "TISSUES_MASK" "$OUTPUTFOLDER/${prefix}TissueSegmentation.nrrd"
#=============================================================
# STEP3b - ICC Mask > Triangle model
#=============================================================
#showStepTitle "Create ICC triangle model"
#CACHE_DoStepOrNot "ICC_TMODEL"
#if [ $? -eq 0 ]; then
#  echo "- Use previously computed triangle model."
#else
#  crlCreateTriangleModel "${ICC_MASK}" 0.5 "$OUTPUTFOLDER/${prefix}ICC_surface.vtk"
#  exitIfError "crlCreateTriangleModel"

#  exportVariable "ICC_TRIANGLE_MODEL" "$OUTPUTFOLDER/${prefix}ICC_surface.vtk"

#  CACHE_StepHasBeenDone "ICC_TMODEL" "${ICC_MASK}" "${ICC_TRIANGLE_MODEL}"
#fi
#echo ""



#=============================================================
# STEP3 - Mask anatomical data
#=============================================================
OUTPUTFOLDER="${folder}/anatomical/04-Masked"
mkdir -p "$OUTPUTFOLDER"

showStepTitle "Mask anatomical data"
CACHE_DoStepOrNot "MASK_ANAT_DATA"
if [ $? -eq 0 ]; then
  echo "- Use previously masked anatomical data."
else

  crlMaskImage "$T1W_REF" "$ICC_MASK" "$OUTPUTFOLDER/${prefix}t1w_ref_masked.nrrd"
  exitIfError "crlMaskImage"
  exportVariable "T1W_REF_MASKED" "$OUTPUTFOLDER/${prefix}t1w_ref_masked.nrrd"

  crlMaskImage "$T2W_REF" "$ICC_MASK" "$OUTPUTFOLDER/${prefix}t2w_ref_masked.nrrd"
  exitIfError "crlMaskImage"
  exportVariable "T2W_REF_MASKED" "$OUTPUTFOLDER/${prefix}t2w_ref_masked.nrrd"

  ofile="$OUTPUTFOLDER/${prefix}t1w_ref_masked.nrrd,$OUTPUTFOLDER/${prefix}t2w_ref_masked.nrrd"
  ifile="$T1W_REF,$T2W_REF,${ICC_MASK}" 

  if [ ! -z "$FLAIR_REF" ]; then
    crlMaskImage "$FLAIR_REF" "$ICC_MASK" "$OUTPUTFOLDER/${prefix}flair_ref_masked.nrrd"
    exitIfError "crlMaskImage"

    ifile="${ifile},$FLAIR_REF"
    ofile="${ofile},$OUTPUTFOLDER/${prefix}flair_ref_masked.nrrd"
    exportVariable "FLAIR_REF_MASKED" "$OUTPUTFOLDER/${prefix}flair_ref_masked.nrrd"

  fi

  if [ ! -z "$CT_REF" ]; then
    crlMaskImage "$CT_REF" "$ICC_MASK" "$OUTPUTFOLDER/${prefix}ct_ref_masked.nrrd"
    exitIfError "crlMaskImage"

    ifile="${ifile},$CT_REF"
    ofile="${ofile},$OUTPUTFOLDER/${prefix}ct_ref_masked.nrrd"
    exportVariable "CT_REF_MASKED" "$OUTPUTFOLDER/${prefix}ct_ref_masked.nrrd"
  fi

  CACHE_StepHasBeenDone "MASK_ANAT_DATA" "$ifile" "$ofile"
fi
echo ""

if [[ $CREATE_REPORT -eq 1 ]]; then
  AnatHtmlFile="${ReportDataDir}/AnatPipeline.html"

  showStepTitle "Report - Anatomical pipeline"
  CACHE_DoStepOrNot "REPORT_ANAT" 1.0088
  if [ $? -eq 0 ]; then
    echo "- Use previously generated report"
  else
    echo "" > ${AnatHtmlFile}

    #--------------------------------------------------------------------
    # Anatomic images all registered together
    #--------------------------------------------------------------------
    echo "<h3>Anatomic images</h3>" >> ${AnatHtmlFile}

    cmd="--new $T1W_REF --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/t1w.png --close $T2W_REF --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/t2w.png --close"
    if [ ! -z "$FLAIR_REF" ] && [ -f "$FLAIR_REF" ]; then
      cmd="$cmd --new $FLAIR_REF --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/flair.png --close"
    fi
    if [ ! -z "$CT_REF" ] && [ -f "$CT_REF" ]; then
      cmd="$cmd --new $CT_REF --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/ct.png --close"
    fi

    runMisterI $cmd --exit

    htmlInsertImageFloat "$AnatHtmlFile" "./imgs/t1w.png" "T1W_REF"
    htmlInsertImageFloat "$AnatHtmlFile" "./imgs/t2w.png" "T2W_REF (registered on T1w)"

    if [ ! -z "$FLAIR_REF" ] && [ -f "$FLAIR_REF" ]; then
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/flair.png" "FLAIR_REF (registered on T1w)"
    fi
    if [ ! -z "$CT_REF" ] && [ -f "$CT_REF" ]; then
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/ct.png" "CT_REF (registered on T1w)"
    fi

    htmlEndFloat $AnatHtmlFile

    #--------------------------------------------------------------------
    # ICC stuff
    #--------------------------------------------------------------------
    if [[ ${SKIP_ICC_EXTRACTION} -ne 1 ]]; then
      cmd="--new $ICC_MASK --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/icc.png --close $ICC_TRIANGLE_MODEL --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/iccmesh.png --close"

      cmd="$cmd $T1W_REF_MASKED --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/t1wmasked.png --close"
      cmd="$cmd $T2W_REF_MASKED --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/t2wmasked.png --close"
      if [ ! -z "$FLAIR_REF_MASKED" ] && [ -f "$FLAIR_REF_MASKED" ]; then
        cmd="$cmd $FLAIR_REF_MASKED --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/flairmasked.png --close"  
      fi
      if [ ! -z "$CT_REF_MASKED" ] && [ -f "$CT_REF_MASKED" ]; then
        cmd="$cmd $CT_REF_MASKED --annotationvisible 0 --cursorvisible 0 --size 600,600 --snapshot $ReportImgDir/ctmasked.png --close"  
      fi

      runMisterI $cmd --exit

      echo "<h3>ICC Step</h3>" >> ${AnatHtmlFile}
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/icc.png" "ICC mask"
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/iccmesh.png" "ICC mesh"
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/t1wmasked.png" "T1w masked"
      htmlInsertImageFloat "$AnatHtmlFile" "./imgs/t2wmasked.png" "T2w masked"
      if [ ! -z "$FLAIR_REF_MASKED" ] && [ -f "$FLAIR_REF_MASKED" ]; then
        htmlInsertImageFloat "$AnatHtmlFile" "./imgs/flairmasked.png" "FLAIR masked"
      fi
      if [ ! -z "$CT_REF_MASKED" ] && [ -f "$CT_REF_MASKED" ]; then
        htmlInsertImageFloat "$AnatHtmlFile" "./imgs/ctmasked.png" "CT masked"
      fi
      htmlEndFloat $AnatHtmlFile

    fi


    CACHE_StepHasBeenDone "REPORT_ANAT" "$T1W_REF,$T2W_REF,${ICC_MASK}" ""
  fi
  
  addHtmlToMainDocument ${AnatHtmlFile} $ReportHtmlFile

fi

exit 0

