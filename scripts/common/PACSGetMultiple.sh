echo "---------------------------------------------------------------"
echo "GetListFromPacs"
echo "Get a list of patients from the PACS"
echo "The input list file must contain one accession number per line."
echo "---------------------------------------------------------------"

if [ $# -ne 2 ]; then
  echo "SYNTAX: GetListFromPacs [LIST file] [Dest RAW]"
  echo
  exit 1
fi

list=$1
D=$2

umask 002

# $1 = file
# $2 = dicom tag
function getDicomTag()
{
  local VAL=`dcdump $1 2>&1 |  grep "$2" | cut -d'>' -f 3 | cut -d'<' -f 2`

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

scriptdir=`dirname $0`
scriptdir=`readlink -f ${scriptdir}`

#--------------------------------------------------
# Read each line of the file
#--------------------------------------------------
for line in $(cat $1)
#cat $list | while read line
do
  accnumber=$line

  echo "--------------------------------------"
  echo "Get $accnumber"
  echo "--------------------------------------"
  mkdir -p ${D}/$accnumber
 
  sh ${scriptdir}/PACSGet.sh $accnumber ${D}/$accnumber
  if [ $? -ne 0 ]; then
     echo "GetListFromPacs.sh : ERROR when calling GetFromPacs.sh"
     echo "Exit"
     echo
     exit 1
  fi


  echo "--------------------------------------"
  echo " Rename folder"
  echo "--------------------------------------"
  if [ `find "${D}/${accnumber}"/ -type f -name '*.dcm' | wc -l` -eq 0 ]; then
    echo "ERROR. Cannot find a dcm file in <${D}/${accnumber}>"
    exit 1
  fi

  dcm=`find "${D}/${accnumber}"/ -type f -name '*.dcm' | head -1`
  patientname=`getDicomTag $dcm 0x0010,0x0010`
  echo "- Rename ${D}/$accnumber -> ${D}/${patientname}_${accnumber}"
  mv ${D}/$accnumber "${D}/${patientname}_${accnumber}"

  echo
  echo


done


