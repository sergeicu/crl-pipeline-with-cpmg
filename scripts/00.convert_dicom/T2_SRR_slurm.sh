
#!/bin/bash
#Vinay Jayaram, 5/16/14
# Script that uses slurm functionality to set jobs instead of current approach
# usage: $0 <num cores>
#Confirm that slurm is installed
if ! hash sbatch 2>/dev/null; then
	echo "sbatch and SLURM not installed. Please run non-SLURM version from same directory"
	exit 1
fi
if [ $# -gt 1 ] ; then
    echo "Usage: $0 <cores>"
    exit 2
elif [ $# -eq 0 ]; then
    cores=3
else
    cores=$1
fi
if [ $cores -lt 1 ] || [ $cores -gt 5 ]; then
	echo "Inappropriate number of cores specified (choose 1-5)"
	exit 3
fi

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
#Currently no accounts implemented for slurm; this could change
head=$RANDOM
srun -J ${head}dbpml -c $cores --mem=20000 -N 1 -D `pwd`/dbpml $path/crlDBPMLReconImage -o hrT2womoco.nrrd -s 0.5 0.5 0.5 -m 1 -t $cores -i ${COR##*/}${AX##*/}${SAG##*/} >dbpml.log 2>&1 &
srun -J ${head}highres -c $cores --mem=20000 -N 1	-D `pwd`/highres $path/crlReconHighresT2 -o hrT2.nrrd -s 0.5 0.5 0.5 -m 2 -t $cores -i ${COR##*/}${AX##*/}${SAG##*/} >highres.log 2>&1 &
srun -d singleton -D `pwd` -J ${head}highres cp ./highres/hrT2.nrrd ./ &
srun -d singleton -D `pwd` -J ${head}dbpml cp ./dbpml/hrT2womoco.nrrd ./ &
