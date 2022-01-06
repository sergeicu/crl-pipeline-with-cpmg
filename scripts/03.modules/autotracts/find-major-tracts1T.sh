
#!/bin/bash
# -------------------------------------------------------------------------


  
# User define Function (UDF)
get_transforms(){
  fa_file="$1"
  TENSOR_FILE="$2"
  ref="$3"


# write the ITK wrapper file needed by itkSuperBaloo
echo "<TRSF>
TRSF_TYPE=MATRICE
MAT_TYPE=AFFI
INVERT=0
FILENAME=${ref}-to-target-affine.tfm
</TRSF>" > ./target-transforms/${ref}-to-target-affine_tr.tsl




# calculate rigid, affine, and nonrigid transforms

crlRigidRegistration \
   ./${fa_file} \
   /common/data/processed/automated-ROIs-for-tractography-project/studies/journal/case${ref}/dti/tracts/fa.nrrd  \
   ./target-transforms/${ref}-on-target-rigid.nrrd \
   ./target-transforms/${ref}-to-target-rigid.tfm 


crlAffineRegistration --metricName mi \
    ./${fa_file} \
    /common/data/processed/automated-ROIs-for-tractography-project/studies/journal/case${ref}/dti/tracts/fa.nrrd  \
    ./target-transforms/${ref}-on-target-affine.nrrd \
    ./target-transforms/${ref}-to-target-affine.tfm \
    ./target-transforms/${ref}-to-target-rigid.tfm


# NOTE: itkSuperBaloo needs to run inside the data directory 
cd target-transforms/

itkSuperBaloo \
    -r ${TENSOR_FILE} \
    -f /common/data/processed/automated-ROIs-for-tractography-project/studies/journal/case${ref}/dti/tracts/clean-masked-tensors.nrrd \
    -o ${ref}-to-target-nonrig \
    -t dense -s 3 -e 0 -k 0.8 --mvt 0.000001 -n 10 -A --bhx 3 --bhy 3 --bhz 3 --blvx 1 --blvy 1 --blvz 1 --ssi tscc -p 4 \
    -i ./${ref}-to-target-affine_tr.tsl

# get back out of the data directory 
cd ../



# save memory space?
rm ./target-transforms/${ref}-on-target-rigid.nrrd
rm ./target-transforms/${ref}-on-target-affine.nrrd

}
 




# User define Function (UDF)
project_roi(){
  roi="$1"
  ref="$2"
  fa_file="$3"



# NOTE: needs to run inside the data directory 
cd target-transforms/

# Resample the ROIs from the moving data set to match the target
itkApplyTrsfSerie \
    -i /common/data/processed/automated-ROIs-for-tractography-project/studies/journal/case${ref}/dti/tracts/${ref}-${roi}-roi.nrrd \
    -o ./${ref}-on-target-${roi}-roi.nrrd \
    -t ./${ref}-to-target-nonrig_tr.tsl  \
    -g ./fa-target.nrrd  \
    -p -1 
# get back out of the data directory 
cd ../



# save memory space?
#rm ./target-transforms/${ref}-to-target-nonrig_0.nrrd



}
 



# User define Function (UDF)
get_staple_roi(){
  roi="$1"
 
if [ -f "${roi}-roi.nrrd" ]; then
  echo "Using the previous STAPLE map consensus";
else

# apply STAPLE to all the reference rois
echo "Running STAPLE map consensus analysis on all ${roi} templates, please stand by...";
crlSTAPLE \
    -o ./target-transforms/${roi}-staple-weights.nrrd \
    ./target-transforms/007-on-target-${roi}-roi.nrrd \
    ./target-transforms/008-on-target-${roi}-roi.nrrd \
    ./target-transforms/009-on-target-${roi}-roi.nrrd \
    ./target-transforms/011-on-target-${roi}-roi.nrrd \
    ./target-transforms/014-on-target-${roi}-roi.nrrd \
    ./target-transforms/015-on-target-${roi}-roi.nrrd \
    ./target-transforms/020-on-target-${roi}-roi.nrrd \
    ./target-transforms/021-on-target-${roi}-roi.nrrd \
    ./target-transforms/023-on-target-${roi}-roi.nrrd \
    ./target-transforms/024-on-target-${roi}-roi.nrrd \
    ./target-transforms/025-on-target-${roi}-roi.nrrd \
    ./target-transforms/027-on-target-${roi}-roi.nrrd \
    ./target-transforms/029-on-target-${roi}-roi.nrrd \
    ./target-transforms/036-on-target-${roi}-roi.nrrd \
    ./target-transforms/039-on-target-${roi}-roi.nrrd > ./target-transforms/STAPLE_${roi}-output_log.txt


# write STAPLE roi from weights file
crlIndexOfMaxComponent \
    ./target-transforms/${roi}-staple-weights.nrrd \
    ./${roi}-roi.nrrd

fi

# save memory space?
rm target-transforms/STAPLE_${roi}-output_log.txt
rm target-transforms/${roi}-staple-weights.nrrd


}
 



# User define Function (UDF)
get_tracts(){
  TENSOR_FILE="$1"
  roi="$2"


# make tracts from new rois file
if [ "${roi}" == CS ]; 
     then echo "using CS bundle strategy for roi: ${roi}"; 
echo "RUNNING crlTractGenerator";

crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r ./${roi}-roi.nrrd \
    -l 1 -l 2 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    ./${roi}-roi.nrrd \
    -d "10" -t "1 2" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;




else if [ "${roi}" == OR ]; 
     then echo "using OR bundle strategy for roi: ${roi}";
echo "RUNNING crlTractGenerator";

crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r ./${roi}-roi.nrrd \
    -l 1 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    ./${roi}-roi.nrrd \
    -d "10" -t "6" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;





else 
     echo "using the default bundle strategy for roi: ${roi}";
echo "RUNNING crlTractGenerator";

crlMFMTractGenerator     \
    -i ${TENSOR_FILE} \
    -r ./${roi}-roi.nrrd \
    -l 1 -f 0.2 --famomentum 0.5 -a 30.0 --anglemomentum 0.5 -d 0.5 -t 0.95 -s 6 -n 1     \
    -o ./${roi}-tracts-unsel.vtk;

crlTractSelector \
    ./${roi}-tracts-unsel.vtk \
    ./${roi}-roi.nrrd \
    -d "10" \
    ./${roi}-tracts.vtk

#echo "running: crlTractDensity"
#crlTractDensity \
#    ./${roi}-tracts.vtk \
#    ./${roi}-roi.nrrd  \
#    ./${roi}-roi-${n}-density.nrrd tracts2.vtk;





fi
fi

# get rid of unselected tract file
rm ./${roi}-tracts-unsel.vtk
}
 









### Main script starts here ###

DB_SUBJECTS_LIST="007 008 009 011 014 015 020 021 023 024 025 027 029 036 039"
ROI_LIST="CC CS CI OR TR SF"

fa_file="target-transforms/fa-target.nrrd"


# Check input file
echo
echo
echo "your tensor volume is: $1"
TENSOR_FILE="$1"
   if [ ! -f $TENSOR_FILE ]; then
  	echo "$TENSOR_FILE : does not exists"
  	exit 1
   elif [ ! -r $TENSOR_FILE ]; then
  	echo "$TENSOR_FILE: can not read"
  	exit 2
   fi


# Check to see if "target-transforms" directory already excists, if not make one
if [ ! -d target-transforms ]
then 
    mkdir target-transforms
    # also, make the fa_file volume from input tensor volume
    crlTensorScalarParameter -f $fa_file  $TENSOR_FILE
else
    echo "target-transforms directory was already made!"
fi






# the main loop starts here

for roi in $ROI_LIST;
do
  if [ ! -f "./${roi}-roi.nrrd" ]; then

    count=1;
    for ref in $DB_SUBJECTS_LIST;
    do


      echo "currently processing tract: $roi template $count" 

      if [ ! -f ./target-transforms/${ref}-to-target-nonrig_tr.tsl ]
      then
	# determine rigid, affine, and nonrigid transformations from tensor volumes
	get_transforms $fa_file $TENSOR_FILE $ref
	
	# project roi to patient anatomy
	project_roi $roi $ref $fa_file

      else
	# just project roi to patient anatomy
	project_roi $roi $ref $fa_file
	echo "GREAT! no transform calculations were needed for ${ref} to target"
      fi

      count=$(( $count + 1 ))

    done




    # do STAPLE to make ROI-roi-staple.nrrd in patient anatomy
    get_staple_roi $roi

  fi

  # make tracts
  get_tracts $TENSOR_FILE $roi

done


# save memory space?
#rm -r target-transforms



exit 0
