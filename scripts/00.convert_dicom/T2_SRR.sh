#!/bin/bash
#if you exit the script, kill the jobs:
trap 'echo killed; kill $(jobs -p)' TERM

#script expects to be run in the scan directory, post sh import_from_dicom.sh
path=/opt/x86_64/builds/crkit/external
if [ ! -d superresolution ]; then mkdir superresolution; fi
if [ ! -d nrrds ]; then
	echo "no directory nrrds. Please convert dicoms before running, or create nrrds folder and add the nrrd files"
	exit 4
fi
cd nrrds
FSE=''
FLAIR=''
COR=''
AX=''
SAG=''
#check if the folder is already populated
if [ $(echo ../superresolution/fse/*.nrrd | wc -w) -lt 2 ] && [ $(echo ../superresolution/flair/*.nrrd | wc -w) -lt 2 ]; then
	echo "copying T2 scans to new directory..."
	[ ! -d ../superresolution/fse ] && mkdir ../superresolution/fse
	[ ! -d ../superresolution/flair ] && mkdir ../superresolution/flair 	 
    for dir in $(ls -l | awk '/^d/ {print $9}'); do
		cd ./$dir
		file=*
		#hacker way, or stupid?
		if [[ `echo $file | grep -i T2 | wc -w` > 0 ]]; then
			if [[ `echo $file | grep -i FSE | wc -w` > 0 ]]; then
				FSE="$FSE $file"
				cp $file ../../superresolution/fse
			elif [[ `echo $file | grep -i FLAIR | wc -w` > 0 ]]; then
				FLAIR="$FLAIR $file"
				cp $file ../../superresolution/flair
			else
				cp $file ../../superresolution/flair
				cp $file ../../superresolution/fse
			fi
		fi
		cd ..
	done
fi
echo "T2 scans copied"
cd ../superresolution
echo "using T2-weighted images:"
DIR='fse'
if [ `echo ./fse/* | wc -w` -lt 2 ] && [ `echo ./flair/* | wc -w` -lt 2 ]; then
	echo "not enough T2 FSE or FLAIR weighted images present"
    exit 0
else
	#prefer to use FSE but if not enough then FLAIR
	for f in ./fse/*.nrrd; do
		COR="$COR $(echo $f | grep -i COR)"
		AX="$AX $(echo $f | grep -i AX)"	
		SAG="$SAG $(echo $f | grep -i SAG)"
	done
	if [[ -z `echo ${COR}${AX}` || -z `echo ${AX}${SAG}` || -z `echo ${COR}${SAG}` ]]; then
		echo "Only one orientation of FSE T2 image; using FLAIR"
		COR=''
		AX=''
		SAG=''
		for f in ./flair/*.nrrd; do
			COR="$COR $(echo $f | grep -i COR)"
			AX="$AX $(echo $f | grep -i AX)"	
			SAG="$SAG $(echo $f | grep -i SAG)"
		done
        if [[ -z `echo ${COR}${AX}` || -z `echo ${AX}${SAG}` || -z `echo ${COR}${SAG}` ]]; then
            echo "Only one FLAIR was found; not enough to reconstruct, exiting"
            echo "Cor: $COR"
            echo "Ax: $AX"
            echo "Sag: $SAG"
            exit 4
        else
            DIR='flair'
        fi

	fi
	echo "Cor: $COR"
	echo "Ax: $AX"
	echo "Sag: $SAG"
fi 

#Now add scripts to slurm
[ ! -d ./dbpml  ] && mkdir ./dbpml
[ ! -d ./highres ] && mkdir ./highres
cp ./${DIR}/*.nrrd ./dbpml
cp ./${DIR}/*.nrrd ./highres
freespace=`top -b -n 1 | awk 'NR==4{print $6}'`
echo "Checking memory usage...$freespace available"
input="${COR} ${AX} ${SAG}"
[ ! -d ./dbpml  ] && mkdir ./dbpml
[ ! -d ./highres ] && mkdir ./highres
cp $input ./dbpml
cp $input ./highres
if [[  ${freespace%k} -ge `echo '40*1000000' | bc -l` && `jobs | wc -l` -le 2 ]]; then
	if [ ! -f ./running_dbpml ]; then
        #maybe a better way...
		echo running dpbml parallel
		(echo 'test' >running_dbpml; cd ./dbpml; $path/crlDBPMLReconImage -o hrT2womoco.nrrd -s 0.5 0.5 0.5 -m 1 -t 2 -i ${input} >dpbml.log 2>&1; cd ..; cp dbpml/hrT2womoco.nrrd ../../data_for_analysis/; rm running_dbpml) &
	else
		echo "dbpml lock in place"
	fi
	if [ ! -f ./running_highres ]; then
		echo running highres parallel
		(echo 'test' >running_highres; cd ./highres; $path/crlReconHighresT2 -o hrT2.nrrd -s 0.5 0.5 0.5 -m 2 -t 2 -i ${input} >highres.log ; cd ..; cp highres/hrT2.nrrd ../../data_for_analysis; rm running_highres)&
	else
		echo "highres lock in place"
	fi			
elif [[ ${freespace%k} -ge `echo '20*1000000' | bc -l` && `jobs | wc -l` -le 2 ]]; then
	if [ ! -f ./running_dbpml ]; then
		cd ./dbpml
        echo "test" >../running_dbpml
		echo running dbpml
		$path/crlDBPMLReconImage -o hrT2womoco.nrrd -s 0.5 0.5 0.5 -m 1 -t 2 -i ${input} >dpbml.log 2>&1
        cd ..
  		rm running_dbpml
	else
		echo "dbpml lock in place"
	fi
	if [ ! -f ./running_highres ]; then
		cd ./highres
		echo "test" >../running_highres
		echo running parallel
		$path/crlReconHighresT2 -o hrT2.nrrd -s 0.5 0.5 0.5 -m 2 -t 2 -i ${input} >highres.log 2>&1
		cd ..
		rm running_highres
	else
		echo "highres lock in place"
	fi
else 
	echo "choose another server; this one's full."
	exit 0
fi
