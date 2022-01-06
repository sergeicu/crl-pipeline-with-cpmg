#!/bin/sh
#-------------------------------------------
# Check the number of parameters
#-------------------------------------------
if [ $# -lt 1 ]; then
   echo "--------------------------------------"
   echo " CreateReportForSite "
   echo " (c) Benoit Scherrer, 2013"
   echo " benoit.scherrer@childrens.harvard.edu"
   echo ""
   echo " Create the report for a site"
   echo "--------------------------------------"
   echo " CreateReportForSite <CaseNumber>"
   echo ""
   exit 1
fi

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/../common/Settings.txt || exit 1
source `dirname $0`/../common/DBUtils.txt || exit 1
source `dirname $0`/../common/ReportManager.txt || exit 1

ReadDBStudy

prevdir=`pwd`

#------------------------------------------
# Get the case folders (CaseRawDir and CaseProcessedDir)
#------------------------------------------
CaseNumber=$1
getCase $CaseNumber
if [ $? -ne 0 ]; then
  exit 1
fi

#------------------------------------------
# Load the case study
#------------------------------------------
cd "$CaseProcessedDir"
if [ ! -f "`pwd`/CaseInfo.sh" ]; then
  echo "Error. Cannot find `pwd`/CaseInfo.sh. Cannot continue."
  exit 1;
fi

source "`pwd`/CaseInfo.sh" || exit 1


#------------------------------------------
# Initialize
#------------------------------------------
reportdir="$CaseProcessedDir/report/tmp"
mkdir -p "$reportdir"

#------------------------------------------
# Initialize Latex report file
#------------------------------------------
latexFile="$reportdir/ACRReport_${PatientName}.tex"

generateLatexHeader $latexFile "ACR Phantom Imaging\\\\ ${PatientName}\\\\ \\small Assessment using the ACR T1w scan \\normalsize"


function runMisterI()
{
  /opt/x86_64/pkgs/MisterI-alpha/MisterI --hidden $@ 
  sleep 1

  # Wait for MisterI to terminate
  
  local p=`echo "$@" | sed 's/,/\ /g'`
  local tmp=`ps -AF | grep "bin/misteri-core --hidden $1 $2 $3" | grep -v grep`
  #echo "-----${tmp}-"
  while [[ ! -z "$tmp" ]];
  do
    sleep 1 
    tmp=`ps -AF | grep "bin/misteri-core --hidden $1 $2 $3" | grep -v grep`
    #echo "-----${tmp}-"
  done
 
}

#------------------------------------------
# CNR Analysis
#------------------------------------------
function plotCNR()
{
  TYPE="$1"
  modality="$2"

  echo "---------------------------------"
  echo " CNR PLOT FOR $TYPE, $modality" 
  echo "---------------------------------"

  ofilebase=$reportdir/${TYPE}seq_${modality}_data
  echo "- Preparing plots ..."
  rm -f ${ofilebase}_cnr2.txt
  rm -f ${ofilebase}_snr.txt
  rm -f ${ofilebase}_BKG.txt
  rm -f ${ofilebase}_SIGNAL.txt
  tickstr=""
  tickstr2=""

  local lastTimePoint=0
  local firstTimePoint=-1
  local minSignal=1000000
  local maxSignal=0
  local minBkgSignal=1000000
  local maxBkgSignal=0
    
  for (( s=1; s<=$ScanCount ; s++ ));
  do  
    PipelineResultsFile=""
    ScanFolder=${Scan[$s]};
    cd "$ScanFolder"
    echo "Scan $ScanFolder"
    if [ ! -f "$ScanFolder/ScanInfo.sh" ]; then
      echo "   SKIP"
      continue;
    fi
    source "$ScanFolder/ScanInfo.sh" || exit 1

    if [ ! -f "$PipelineResultsFile" ]; then
      echo "   SKIP"
      continue;
    fi
    source $PipelineResultsFile
    echo " - OK. Data imported"

    statdir="$ScanProcessedDir/common-processed/${TYPE}/02-roistats/"
    statfile="$statdir/${TYPE}_${modality}_roistats.txt"

    echo " - Read statistics ${statfile}"


    if [[ -d $statdir ]] && [[ -f "$statfile" ]] ; then
      meanBG=`more "$statfile" | grep "meanBG" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      varBG=`more "$statfile" | grep "varBG" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      mean2=`more "$statfile" | grep "meanLabel2" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      var2=`more "$statfile" | grep "varLabel2" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      mean3=`more "$statfile" | grep "meanLabel3" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      var3=`more "$statfile" | grep "varLabel3" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      mean4=`more "$statfile" | grep "meanLabel4" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      var4=`more "$statfile" | grep "varLabel4" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      meanSIGNAL=`more "$statfile" | grep "meanLabel5" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      varSIGNAL=`more "$statfile" | grep "varLabel5" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      mean6=`more "$statfile" | grep "meanLabel6" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      var6=`more "$statfile" | grep "varLabel6" |  cut -d'>' -f 1 | cut -d'<' -f 2`
 
      sigmaBG=`echo "scale=4;sqrt($varBG)"|bc`
      sigmaSIGNAL=`echo "scale=4;sqrt($varSIGNAL)"|bc`
      

      local v=$(printf "%.0f" $(echo "scale=2;$meanBG+2*$sigmaBG"|bc))
      if [[ $v -ge $maxBkgSignal ]]; then
        maxBkgSignal=$v
      fi
      v=$(printf "%.0f" $(echo "scale=2;$meanBG-2*$sigmaBG"|bc))
      if [[ $v -le $minBkgSignal ]]; then
        minBkgSignal=$v
      fi

      v=$(printf "%.0f" $(echo "scale=2;$meanSIGNAL+2*$sigmaSIGNAL"|bc))
      if [[ $v -ge $maxSignal ]]; then
        maxSignal=$v
      fi
      v=$(printf "%.0f" $(echo "scale=2;$meanSIGNAL-2*$sigmaSIGNAL"|bc))
      if [[ $v -le $minSignal ]]; then
        minSignal=$v
      fi


      if [ ! -z "$meanBG" ]; then

        local cnr2=`echo "scale=4;($meanSIGNAL-$meanBG)/$sigmaBG"|bc`
        cnr2=`echo "scale=4;a=$cnr2;if(0>a)a*=-1;a"|bc`

        local snr=`echo "scale=4;$meanSIGNAL/$sigmaBG"|bc`
        snr=`echo "scale=4;20*l($snr)/l(10)"|bc -l`
        nrrdfile=`basename $ScanFolder`
        echo "$nrrdfile bg: $meanBG, $varBG   L2: $mean2,$var2   L3: $mean3,$var3   L5: $meanSIGNAL,$varSIGNAL"
        echo " ==>  SNR=$snr   CNR(L2)=$cnr2  CNR(L3)=$cnr3  CNR(L6)=$cnr6" 
        echo "$s $cnr2" >> ${ofilebase}_cnr2.txt
        echo "$s $snr" >> ${ofilebase}_snr.txt

        echo "$s $meanBG $sigmaBG" >> ${ofilebase}_BKG.txt
        echo "$s $meanSIGNAL $sigmaSIGNAL" >> ${ofilebase}_SIGNAL.txt

        if [ ! -z "$tickstr" ]; then
          tickstr="$tickstr,"
          tickstr2="${tickstr2},"
        fi
        tickstr="$tickstr'${ScanNumber}'"
        tickstr2="${tickstr2}${s}"

        if [[ $firstTimePoint -eq -1 ]]; then
          firstTimePoint=$s
        fi
        if [[ $s -gt $lastTimePoint ]]; then
          lastTimePoint=$s
        fi
     fi
    fi
    echo
  done


  echo "- Create graphs"
  plotTmpFile="$reportdir/tmp.py"


  plotBeginPyPlot $plotTmpFile
  plotAddPyErrorBarPlot $plotTmpFile ${ofilebase}_BKG.txt 
  plotYLabel $plotTmpFile "Intensity"

  local x1=`echo "scale=4;$firstTimePoint-0.5"|bc`
  local x2=`echo "scale=4;$lastTimePoint+0.5"|bc`
  plotSetXAxesLimits $plotTmpFile $x1 $x2
  plotSetYAxesLimits $plotTmpFile $minBkgSignal $maxBkgSignal
  echo "plt.xticks(($tickstr2), ($tickstr), rotation=20)" >> $plotTmpFile
  plotSavePyPlot $plotTmpFile $reportdir/${TYPE}seq_${modality}_BKG.png

  plotBeginPyPlot $plotTmpFile
  plotAddPyErrorBarPlot $plotTmpFile ${ofilebase}_SIGNAL.txt 
  plotYLabel $plotTmpFile "Intensity"
  plotSetYAxesLimits $plotTmpFile $minSignal $maxSignal
  plotSetXAxesLimits $plotTmpFile $x1 $x2
  echo "plt.xticks(($tickstr2), ($tickstr), rotation=20)" >> $plotTmpFile
  plotSavePyPlot $plotTmpFile $reportdir/${TYPE}seq_${modality}_SIGNAL.png
  

  plotBeginPyPlot $plotTmpFile
  plotAddPyPlot $plotTmpFile ${ofilebase}_cnr2.txt 'ro--' 'Label 2'
  #plotAddLegend $plotTmpFile "bbox_to_anchor=(0,1.02,1,0.1), loc=3, ncol=3, mode=\"expand\""
  plotSetYAxesLimits $plotTmpFile 0 1000
  plotSetXAxesLimits $plotTmpFile $x1 $x2
  plotYLabel $plotTmpFile "CNR"
  echo "plt.xticks(($tickstr2), ($tickstr), rotation=20)" >> $plotTmpFile
  plotSavePyPlot $plotTmpFile $reportdir/${TYPE}seq_${modality}_cnr.png
  

  
  plotBeginPyPlot $plotTmpFile
  plotAddPyPlot $plotTmpFile ${ofilebase}_snr.txt 'ro--' ''
  plotSetYAxesLimits $plotTmpFile 30 70
  plotSetXAxesLimits $plotTmpFile $x1 $x2
  plotYLabel $plotTmpFile "SNR (dB)"
  #plotXLabel $plotTmpFile "Time point"
  echo "plt.xticks(($tickstr2), ($tickstr), rotation=20)" >> $plotTmpFile
  plotSavePyPlot $plotTmpFile $reportdir/${TYPE}seq_${modality}_snr.png
  
 
  #python ${SrcScriptDir}/04.acr/showPlot.py $reportdir/${TYPE}seq_${modality}_cnr.png ${ofilebase}_cnr2.txt ${ofilebase}_cnr3.txt ${ofilebase}_cnr6.txt
  #python ${SrcScriptDir}/04.acr/showPlot.py $reportdir/${TYPE}seq_${modality}_snr.png ${ofilebase}_snr.txt
  echo ""



}

plotCNR "ACR" "T1W"
#plotCNR "ACR" "T2W"

#plotCNR "SITE" "T1W"
#plotCNR "SITE" "T2W"

latexcontent="$reportdir/report_content.tex"
rm -f $latexcontent

#------------------------------------------
# Add sigma-related plots
#------------------------------------------
latexBeginTwoColumnFigure $latexcontent
latexInsertTwoColumnFigure $latexcontent "$reportdir/ACRseq_T1W_BKG.png" "(a)" "height=1.8in" "$reportdir/ACRseq_T1W_SIGNAL.png" "(b)" "height=1.8in"
latexEndTwoColumnFigure $latexcontent "(a) Mean and standard deviation of the noise. (b) Mean and standard deviation of the signal."


#------------------------------------------
# Add CNR-related stuff to latex report
#------------------------------------------
latexBeginTwoColumnFigure $latexcontent
latexInsertTwoColumnFigure $latexcontent "$reportdir/ACRseq_T1W_snr.png" "(b)" "height=1.8in" "$SrcScriptDir/04.acr/snaphot_acr_snr.png" "(a)" "height=1.8in"
latexEndTwoColumnFigure $latexcontent "(a) Signal-to-noise ratio (SNR) at each time point. The SNR is defined by: \$ 20 \\log_{10} \\frac{ \\mathrm{\\mu_\\mathrm{signal(green)}} }{\\sigma_\\mathrm{noise(blue)}} \$. (b) ROIs used to compute the SNR."



latexBeginTwoColumnFigure $latexcontent
latexInsertTwoColumnFigure $latexcontent "$reportdir/ACRseq_T1W_cnr.png" "(b)" "height=1.8in" "$SrcScriptDir/04.acr/snaphot_acr_cnr.png" "(a)" "height=1.8in"
latexEndTwoColumnFigure $latexcontent "(a) Contrast-to-noise ratio (CNR) with background at each time point. The CNR is defined by: \$ \\frac{| \\mu_\\mathrm{signal1(green)} - \\mu_\\mathrm{signal2(blue)} |}{\\sigma_\\mathrm{noise(blue)}} \$. (b) ROIs used to compute the CNR."

#------------------------------------------
# Insert all snapshots
#------------------------------------------
echo "---------------------------------"
echo " CREATE SNAPSHOTS" 
echo "---------------------------------"



snapshotStr=""
nsnapshot=0
nbonline=0
subcaption=""
TYPE="ACR"
modality="T1W"
for (( s=1; s<=$ScanCount ; s++ ));
do  
  #---------------------------------------------
  # Get the pipeline result variables
  #---------------------------------------------
  PipelineResultsFile=""
  ScanFolder=${Scan[$s]};
  if [ ! -f "$ScanFolder/ScanInfo.sh" ]; then
    continue;
  fi
  source "$ScanFolder/ScanInfo.sh" || exit 1

  if [ ! -f "$PipelineResultsFile" ]; then
    continue;
  fi
  source $PipelineResultsFile

  #---------------------------------------------
  # Get the window/level from the roistats file
  #---------------------------------------------
  statfile="$ScanProcessedDir/common-processed/${TYPE}/02-roistats/${TYPE}_${modality}_roistats.txt"

  if [[ -f "$statfile" ]] ; then
      mean=`more "$statfile" | grep "meanLabel5" |  cut -d'>' -f 1 | cut -d'<' -f 2`
      window=`echo "scale=4;3*$mean"|bc`
      level=`echo "scale=4;0.6*$mean"|bc`
  fi

  #---------------------------------------------
  # Create screenshot with MisterI
  #---------------------------------------------
  opng=$reportdir/${CaseNumber}_${TYPE}seq_${modality}_${ScanNumber}.png
  echo "${ACR_T1Wref} => $opng"
  runMisterI ${ACR_T1Wref} --singleviewlayout axial --cursorpos -37,11,-34 --annotationvisible 0 --cursorvisible 0 --windowlevel $window,$level --snapshotW $opng 640 --exit
  
  #---------------------------------------------
  # Initialize latex figure if needed
  #---------------------------------------------
  if [[ $nsnapshot -eq 0 ]]; then
    echo "\begin{figure}[!ht]" >> $latexcontent
    echo "\center" >> $latexcontent
    echo "\begin{tabular}{cccc}" >> $latexcontent  
  fi

  #---------------------------------------------
  # Include next graphic (creates both the
  # \includegraphics command and build the fig caption)
  #---------------------------------------------
  str=""
  if [[ $nbonline -ne 0 ]]; then
     str="&"
     subcaption="$subcaption &"
  fi
  str="$str \\includegraphics[height=1.5in]{${opng}}"
  w2=`printf "%.0f" "$window"`
  l2=`printf "%.0f" "$level"`
  subcaption="$subcaption $ScanNumber (w=$w2, l=$l2)"

  #---------------------------------------------
  # Increment counters
  #---------------------------------------------
  nsnapshot=$(($nsnapshot+1))
  nbonline=$(($nbonline+1))

  #---------------------------------------------
  # Allow a max of 4 images per line
  #---------------------------------------------
  if [[ $nbonline -eq 4 ]]; then
    str="$str \\\\ $subcaption \\\\"
    nbonline=0
    subcaption=""
  fi

  echo "$str" >> $latexcontent

  #---------------------------------------------
  # Allow a max of 6x4 images per figure
  #---------------------------------------------
  if [[ $nsnapshot -eq 24 ]]; then
    echo "\end{tabular}" >> $latexcontent
    echo "\caption{A same slice of the ACR phantom accross each time point. Window/Level values (w/l values) are adjusted for each image according to the signal value, so that changes in contrast can be visualized.}" >> $latexcontent
    echo "\end{figure}" >> $latexcontent

    nsnapshot=0 # Will create a new figure at the next iteration
    nbonline=0
  fi

done

if [[ $nbonline -ne 0 ]]; then
  echo "\\\\ $subcaption" >> $latexcontent
fi

if [[ $nsnapshot -ne 0 ]]; then
  echo "\end{tabular}" >> $latexcontent
  echo "\caption{A same slice of the ACR phantom accross each time point. Window/Level values (w/l values) are adjusted for each image according to the signal value, so that changes in contrast can be visualized.}" >> $latexcontent
  echo "\end{figure}" >> $latexcontent
fi

#------------------------------------------
# Finished the latex generation, and create pdf
#------------------------------------------
cd "$reportdir"

echo "\\input{$latexcontent}" >> $latexFile

generateLatexEnd $latexFile

echo "---------------------------------"
echo "Create PDF report" 
echo "---------------------------------"
echo "pdflatex $latexFile"
pdflatex $latexFile

basepdf=`echo "$latexFile" | sed 's/\.tex//'`

d=`date +"%Y-%m"`

cp ${basepdf}.pdf "../ACRReport_${PatientName}_${d}.pdf"
cp ${basepdf}.pdf "../ACRReport_${PatientName}.pdf"

echo
pwd
echo " FILE ../ACRReport_${PatientName}_${d}.pdf"
echo

cd "$prevdir"


#------------------------------------------
# Finished!
#------------------------------------------
echo "---------------------------------"
echo " !! DONE !!" 
echo " $latexFile "

echo "---------------------------------"

