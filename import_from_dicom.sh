if [ $# -ne 1 ]; then
  echo "----------------------------------------------------------"
  echo "Import the images for that subject from a DICOM folder."
  echo "The script will create a 'nrrds' subfolder for this subject"
  echo "and convert the dicom files to nrrd files"
  echo 
  echo " (c) CRL, Benoit Scherrer, 2011"
  echo "     benoit.scherrer@childrens.harvard.edu"
  echo "----------------------------------------------------------"
  echo "SYNTAX: import_from_dicom.sh [dicom folder]"
  echo
  exit 1
fi


umask 002

dicom=`readlink -f "$1"`

mkdir -p nrrds | exit 1
cd nrrds
sh ../scripts/00.convert_dicom/ConvertFromDICOM.txt "$dicom" .
