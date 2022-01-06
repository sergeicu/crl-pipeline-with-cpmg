# to prepare CPMG file for CRL pipeline we need to extract nth echo. We found that ~10th echo (90ms) is a good approximation to T2W image contrast (for rigid alignment)
mkdir cpmg 
f=<path_to_cpmg_nifti_image>
cp $f cpmg && cd cpmg
fslsplit $f ${f/.nii.gz/} -t 
cp ${f/.nii.gz/}0010.nii.gz gt_bestCPMG.nii.gz
crlConvertBetweenFileFormats gt_bestCPMG.nii.gz gt_bestCPMG.nrrd
cp gt_bestCPMG.nrrd ../data_for_analysis/


