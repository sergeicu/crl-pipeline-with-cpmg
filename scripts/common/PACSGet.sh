echo "---------------------------------------------------------------"
echo "PACSGet.sh"
echo "Get a patient from the PACS. The MRI session to fetch is "
echo "described by its accession number."
echo "---------------------------------------------------------------"

if [ $# -ne 2 ]; then
  echo "SYNTAX: GetFromPacs [AccessNumber] [Dest RAW]"
  echo
  exit 1
fi

umask 002

#--------------------------------------
# Get the config file.
# Currently only used to define the variable:"
# TEMPORARYFOLDER
#--------------------------------------
sdir=`dirname $0`
sdir=`readlink -f ${sdir}`
echo "- Read configuration file <$sdir/PACS_script_config.txt>"
if [ -f "$sdir/PACS_script_config.txt" ]; then
  source "$sdir/PACS_script_config.txt" || exit 1
else
  echo "  NOT FOUND. USE DEFAULT SETTINGS."
fi

#--------------------------------------
# Default init for temporary folder
#--------------------------------------
if [ -z "$TEMPORARYFOLDER" ]; then
  TEMPORARYFOLDER="~/tmp/fromRadCrl"
fi

#--------------------------------------
# Show some infos and do checkings
#--------------------------------------
mkdir -p "$TEMPORARYFOLDER"
TEMPORARYFOLDER=`readlink -f "$TEMPORARYFOLDER"`
echo "- Temporary folder: <$TEMPORARYFOLDER>"

mkdir -p $2
odir=`readlink -f $2`
echo "- Output DICOM folder: <$odir>"

n=`find "$TEMPORARYFOLDER"/ -type f | wc -l`
if [ $n -ne 0 ] ; then
  echo "ERROR. Your tmp folder <$TEMPORARYFOLDER> is not empty"
  echo "GetFromPacs is probably already retrieving DICOM data"
  echo "and can only work one patient at a time."
  echo
  exit 1
fi

#----------------------------------------------
# Get the DICOM from the listener
#----------------------------------------------
echo "------------------------------------"
echo "Grab DICOMs"
echo "------------------------------------"

export PATH=/opt/x86_64/builds/dicomtools/dicom3tools_1.00.snapshot.20061010/bin/1.2.6.9.x8664/:$PATH

/usr/local/dcm4che-tools/bin/dcmqr -L RADCRL PACSDCM@134.174.12.21 -qAccessionNumber=$1 -cmove RADCRL
if [ $? -ne 0 ]; then
  echo "Error while running </usr/local/dcm4che-tools/bin/dcmqr> for PACS->RADCRL"
  echo
  exit 1
fi

/usr/local/dcm4che-tools/bin/dcmqr RADCRL@radcrl:11112 -qAccessionNumber=$1 -cmove LOCALRCV
if [ $? -ne 0 ]; then
  echo "Error while running </usr/local/dcm4che-tools/bin/dcmqr> for RADCRL->LOCAL"
  echo
  exit 1
fi

echo
echo

#----------------------------------------------
# Rename and move the DICOM folder/files
#----------------------------------------------
echo "------------------------------------"
echo "Rename DICOMs"
echo " $TEMPORARYFOLDER"
echo " -> $2" 
echo "------------------------------------"

nfiles=`find "$TEMPORARYFOLDER"/ -type f | wc -l`
j=1

for i in `find "$TEMPORARYFOLDER"/ -type f`; do
  # It is a lot quicker to do a single dcdump in a file
  # and then do the grep on the file
  dcdump "$i" 2>"$TEMPORARYFOLDER/dicomdump.txt"
#echo "file $i"
  SNAME=`cat "$TEMPORARYFOLDER/dicomdump.txt" |  grep 0x0008,0x103e | cut -d'>' -f 3 | cut -d'<' -f 2`
  if [ -z "$SNAME" ]; then
    SNAME="UNKNOWN"
  fi

#echo "-- $SNAME"
  SNAME=`echo $SNAME | sed s/\ /_/g`
  SNAME=`echo "${SNAME}" | sed "s/\ /_/g"`
  SNAME=`echo "${SNAME}" | sed "s/\^/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/+/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/-/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/(/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/)/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/=/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/&/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/*/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/%/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/\;/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/\:/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/\,/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/\//_/g"`

#echo "-2 $SNAME"

  SNAME=`echo "${SNAME}" | sed "s/__/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/__/_/g"`
  SNAME=`echo "${SNAME}" | sed "s/__/_/g"`

#echo "-3 $SNAME"

  SNAME=`echo "${SNAME}" | sed "s/_$//"`

#echo "-4 $SNAME"

  SNUMBER=`cat "$TEMPORARYFOLDER/dicomdump.txt" | grep 0x0020,0x0011 | cut -d'>' -f 3 | cut -d'<' -f 2`
  SNUMBER=`echo $SNUMBER | sed s/\ //g`

  if [ -z "$SNUMBER" ]; then
    SNUMBER=999
  fi

#echo "-5 $SNUMBER"

  AT=`cat "$TEMPORARYFOLDER/dicomdump.txt" | grep 0x0008,0x0018 | cut -d'>' -f 3 | cut -d'<' -f 2`
  AT=`echo $AT | sed s/\ //g`

  if [ -z "$AT" ]; then
    AT=`basename "$i"`
  fi

#echo "-6 $AT"

  rm -f "$TEMPORARYFOLDER/dicomdump.txt"

  if [ ! -d "${SNUMBER}_${SNAME}" ] ; then
    mkdir -p "$2/${SNUMBER}_${SNAME}"
  fi

  bn=`basename $i`
  echo "$j/$nfiles : $bn -> ${SNUMBER}_${SNAME}_${AT}.dcm"
  j=$(($j+1))

  mv $i "$2/${SNUMBER}_${SNAME}/${SNUMBER}_${SNAME}_${AT}.dcm"
  if [ $? -ne 0 ]; then
    echo "ERROR WHILE RENAMING THE FILE"
    echo "EXPORT infos in $2/debug.txt and quit"
    echo "Rename file <$i>" >> $2/debug.txt
    echo "  to <$2/${SNUMBER}_${SNAME}/${SNUMBER}_${SNAME}_${AT}.dcm>" >> $2/debug.txt
    echo
    exit 1
  fi

done
echo
echo


#----------------------------------------------
# Extract some infos from the DICOM
#----------------------------------------------

ofile=$2/dicom_infos.txt

echo "------------------------------------"
echo "Extract infos from DICOMs"
echo " in $ofile"
echo "------------------------------------"

# $1 = file
# $2 = dicom tag
function getDicomTag()
{
  VAL=`dcdump $1 2>&1 |  grep "$2" | cut -d'>' -f 3 | cut -d'<' -f 2`

  VAL=`echo "${VAL}" | sed "s/\ /_/g"`
  VAL=`echo "${VAL}" | sed "s/\^/_/g"`
  VAL=`echo "${VAL}" | sed "s/+/_/g"`
  VAL=`echo "${VAL}" | sed "s/-/_/g"`
  VAL=`echo "${VAL}" | sed "s/(/_/g"`
  VAL=`echo "${VAL}" | sed "s/)/_/g"`
  VAL=`echo "${VAL}" | sed "s/=/_/g"`
  VAL=`echo "${VAL}" | sed "s/&/_/g"`
  VAL=`echo "${VAL}" | sed "s/*/_/g"`
  VAL=`echo "${VAL}" | sed "s/%/_/g"`
  VAL=`echo "${VAL}" | sed "s/\;/_/g"`
  VAL=`echo "${VAL}" | sed "s/\:/_/g"`
  VAL=`echo "${VAL}" | sed "s/\,/_/g"`
  echo $VAL
}

dcm=`find "$2"/ -type f -name *.dcm | head -1`

mrn=`getDicomTag $dcm 0x0010,0x0020`
anum=`getDicomTag $dcm 0x0008,0x0050`
patientname=`getDicomTag $dcm 0x0010,0x0010`
patientsex=`getDicomTag $dcm 0x0010,0x0040`
patientbdate=`getDicomTag $dcm 0x0010,0x0030`
patientsdate=`getDicomTag $dcm 0x0008,0x0020`
patientage=`getDicomTag $dcm 0x0010,0x1010`
patientweight=`getDicomTag $dcm 0x0010,0x1030`

patientsex=`echo "${patientsex}" | sed "s/_//g"`


echo "MRN=\"$mrn\"" > $ofile
echo "ACCESSION_NUMBER=\"$anum\"" >> $ofile
echo "PATIENT_NAME=\"$patientname\"" >> $ofile
echo "PATIENT_SEX=\"$patientsex\"" >> $ofile
echo "PATIENT_BDAY=\"$patientbdate\"" >> $ofile
echo "PATIENT_SDAY=\"$patientsdate\"" >> $ofile
echo "PATIENT_AGE=\"$patientage\"" >> $ofile
echo "PATIENT_WEIGHT=\"$patientweight\"" >> $ofile

cat "$ofile"
echo
echo
