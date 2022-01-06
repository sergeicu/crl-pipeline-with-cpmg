#!/bin/sh

echo "--------------------------------------"
echo " CreateReportForAllSites "
echo " (c) Benoit Scherrer, 2013"
echo " benoit.scherrer@childrens.harvard.edu"
echo "--------------------------------------"

#------------------------------------------
# Load the study DB
#------------------------------------------
source `dirname $0`/../common/Settings.txt || exit 1
source `dirname $0`/../common/DBUtils.txt || exit 1
source `dirname $0`/../common/ReportManager.txt || exit 1

ReadDBStudy



#------------------------------------------
# Initialize the general latex report file
#------------------------------------------
reportdir="$BaseProcessedDir/report/tmp"
mkdir -p "$reportdir"
latexFile="$reportdir/ACRReport_AllSites.tex"
generateLatexHeader $latexFile "ACR Phantom Imaging"

#------------------------------------------
# Loop on all cases
#------------------------------------------
for (( s=1; s<=$CaseCount ; s++ ));
do  
    #------------------------------------------
    # Check if valid case
    #------------------------------------------
    CaseFolder=${Case[$s]};
    echo $CaseFolder
    if [ ! -f "$CaseFolder/CaseInfo.sh" ]; then
      echo "   SKIP"
      continue;
    fi
    source "$CaseFolder/CaseInfo.sh" || exit 1
    echo "   OK"

    #------------------------------------------
    # Update report for case
    #------------------------------------------
    sh $SrcScriptDir/04.acr/CreateReportForSite.sh $CaseNumber

    #------------------------------------------
    # Add reference to report
    #------------------------------------------
    echo "\\clearpage \section{${PatientName}}" >> $latexFile
    echo "\\input{$CaseProcessedDir/report/tmp/report_content.tex}" >> $latexFile
    cp "$CaseProcessedDir/report/tmp/\*.png" "$reportdir"/
done

#------------------------------------------
# Now terminates latex generation
#------------------------------------------
generateLatexEnd $latexFile

#------------------------------------------
# Creates the final PDF
#------------------------------------------
echo "---------------------------------"
echo "Create PDF report" 
echo "---------------------------------"
cd "$reportdir"
pdflatex $latexFile
cp $reportdir/*.pdf ../

cd "$prevdir"


#------------------------------------------
# Finished!
#------------------------------------------
echo "---------------------------------"
echo " !! DONE !!" 
echo "---------------------------------"

