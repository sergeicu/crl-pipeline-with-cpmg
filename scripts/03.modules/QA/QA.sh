#!/bin/sh


#------------------------------------------
# Load the cache manager, init the prefix, etc...
# After the file is sourced, we are in the folder 
# "$ScanProcessedDir/common-processed"
#------------------------------------------
source "./ScanInfo.sh" || exit 1
#source "`dirname $0`/../../../ScanInfo.sh" || source "./ScanInfo.sh" || exit 1
source $ScriptDir/common/PipelineUtils.txt || exit 1
source $ScriptDir/common/PipelineInit.txt || exit 1
source $ScriptDir/common/ReportManager.txt || exit 1

if [ ! -z "$SrcScriptDir" ]; then
  ApplyTransformScript="$SrcScriptDir/03.modules/QA/ref2subject.py"
else
  ApplyTransformScript="$ScriptDir/03.modules/QA/ref2subject.py"
fi


OFOLDER="${folder}/modules/QA"

mkdir -p "$OFOLDER/latex/imgs"
mkdir -p "$OFOLDER/tmp"

latexheader="$OFOLDER/latex/report.tex"
latexcontent="$OFOLDER/latex/report_content.tex"

rm -f $latexheader
rm -f $latexcontent


generateLatexHeader $latexheader "Quality Assessment\\\\ $CaseName - $ScanName ($PatientName)"

echo "\\input{$OFOLDER/latex/report_content.tex}" >> $latexheader

latexBeginCenter $latexcontent
latexBeginTabular $latexcontent "l l"

latexAddText $latexcontent "{\\bf  $CaseName - $ScanName } & \\\\ \hline"

if [ ! -z "$PatientName" ]; then

  latexAddText $latexcontent "DOB & $DOB\\\\"
  latexAddText $latexcontent "AcquisitionDate & $AcquisitionDate\\\\"
  latexAddText $latexcontent "PatientSex & $PatientSex\\\\"
  latexAddText $latexcontent "PatientDicomAge & $PatientDicomAge\\\\"
  latexAddText $latexcontent "PatientMonthAge & $PatientMonthAge\\\\"
  latexAddText $latexcontent "PatientYearAge & $PatientYearAge\\\\"
  latexAddText $latexcontent "ScannerManufacturer & $ScannerManufacturer\\\\"
  latexAddText $latexcontent "InstitutionName & $InstitutionName\\\\"

fi

latexEndTabular $latexcontent
latexEndCenter $latexcontent



function runMisterI()
{
    /opt/x86_64/pkgs/MisterI-alpha/MisterI $@ 
}



#-------------------------------------------------
# Compute registration from REF STANDARD to SUBJECT
#-------------------------------------------------
showStepTitle "Quality Assessment"
CACHE_DoStepOrNot "QA_ROOT" "1.05"
if [  $? -eq 0 ]; then
  echo "- Use previously computed QA."
else
  
  OFILE="$OFOLDER/tmp/ref2subject.nrrd"
  OTRSFR="$OFOLDER/tmp/ref2subject_1.tfm"
  OTRSFA="$OFOLDER/tmp/ref2subject_2.tfm"

  if [ ! -z "$SrcScriptDir" ]; then
    REF="$SrcScriptDir/03.modules/QA/t1w_ref.nrrd"
  else
    REF="$ScriptDir/03.modules/QA/t1w_ref.nrrd"
  fi

  crlRigidRegistration --metricName mi "${T1W_REF}" "$REF" "$OFILE" "$OTRSFR"
  exitIfError "Rigid registration"

  crlAffineRegistration "${T1W_REF}" "$REF" "$OFILE" "$OTRSFA" "$OTRSFR"
  exitIfError "Rigid registration"

  crlAnyTransformToAffineTransform "$OTRSFA" "$OFOLDER/tmp/ref2subject.affine.tfm"
  crlAnyTransformToAffineTransform "$OTRSFA" "$OFOLDER/tmp/ref2subject.affine.inv.tfm" 1


  CACHE_StepHasBeenDone "QA_ROOT" "$REF" "$OFILE"
fi
echo ""




#-------------------------------------------------
# QA for DW scans
#-------------------------------------------------
if [[ ! -z "$NB_DWI_FOLDERS" ]] && [[ $NB_DWI_FOLDERS -ge 1 ]]; then

  #-------------------------------------------------
  # For each DWI folder
  #-------------------------------------------------
  for i in `seq 0 $((NB_DWI_FOLDERS-1))`
  do
    dwifolder=${DWI_FOLDERS[$i]}
    if [ -z "$dwifolder" ]; then
      continue;
    fi

    dwiID=`basename "$dwifolder"`
    if [ -z "$dwiID" ]; then
      continue;
    fi

    baseimgfile="$OFOLDER/latex/imgs/${dwiID}"

    #--------------------------------------------
    # Snapshots of DTI 
    #--------------------------------------------
    showStepTitle "Snapshots - $dwiID Tensors"
    CACHE_DoStepOrNot "QA_$dwiID_DTI" "1.00"
    if [  $? -eq 0 ]; then
      echo "- Use previously computed QA."
    else


      #--------------------------------------------
      # Compose the transforms to get REF => DWI space
      #--------------------------------------------
      d2t="${dwiID}_DWI2T1W_TRSF"; d2t=${!d2t}
      REF2DWI="$OFOLDER/tmp/${dwiID}_ref2dwi.tfm"
      crlComposeAffineTransforms "$OFOLDER/tmp/ref2subject.affine.inv.tfm" "$d2t" "$REF2DWI"
      # we can use python ref2subject.py "$REF2DWI" 17.82,-46.45,19.36   to transform a point from REF space to DWI subject space

      corviewpos=`python "$ApplyTransformScript" "$REF2DWI" 1.55,-21.79,-19.20`
      axviewpos=`python "$ApplyTransformScript" "$REF2DWI" 2.74,-17.05,-22.0`
    
      dti="${dwiID}_TENSOR_1T"; dti=${!dti}
      echo "Open $dti"
      runMisterI --new "$dti" --singleviewlayout coronal --cursorpos "$corviewpos" --annotationvisible 0 --cursorvisible 0 --size 1024,768 --snapshot "${baseimgfile}_Tensor1T_cor.png" --exit 
      runMisterI --new "$dti" --singleviewlayout axial --cursorpos "$axviewpos" --annotationvisible 0 --cursorvisible 0 --size 1024,768 --snapshot "${baseimgfile}_Tensor1T_ax.png" --exit 
 
      CACHE_StepHasBeenDone "QA_$dwiID_DTI" "$dti" "${baseimgfile}_Tensor1T_cor.png,${baseimgfile}_Tensor1T_ax.png"
    fi

    latexBeginTwoColumnFigure $latexcontent
    latexInsertTwoColumnFigure $latexcontent "${baseimgfile}_Tensor1T_cor.png" "(a)" "width=3.5in" "${baseimgfile}_Tensor1T_ax.png" "(b)" "width=3.5in"
    latexEndTwoColumnFigure $latexcontent "DTI from ${dwiID}"

  done
fi


#------------------------------------------
# Now terminates latex generation
#------------------------------------------
generateLatexEnd $latexheader

#------------------------------------------
# Creates the final PDF
#------------------------------------------
echo "---------------------------------"
echo "Create PDF report" 
echo "---------------------------------"
prevdir=`pwd`
cd "$OFOLDER/latex"
pdflatex $latexheader
cp *.pdf ../

cd $prevdir

