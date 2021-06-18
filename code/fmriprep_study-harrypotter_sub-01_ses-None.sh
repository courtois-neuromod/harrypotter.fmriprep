#!/bin/bash
#SBATCH --account=rrg-pbellec
#SBATCH --job-name=fmriprep_study-harrypotter_sub-01_ses-None.job
#SBATCH --output=/lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter/code/fmriprep_study-harrypotter_sub-01_ses-None.out
#SBATCH --error=/lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter/code/fmriprep_study-harrypotter_sub-01_ses-None.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=4096M
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=basile.pinsard@gmail.com
 
set -e -u -x

export SINGULARITYENV_TEMPLATEFLOW_HOME=/data/sourcedata/templateflow


export LOCAL_DATASET=$SLURM_TMPDIR/$SLURM_JOB_NAME/
flock --verbose /lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter/.datalad_lock datalad clone /lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter $LOCAL_DATASET
cd $LOCAL_DATASET
datalad get -n -r -R1 . # get sourcedata/*
git submodule foreach --recursive git annex dead here
git checkout -b $SLURM_JOB_NAME
if [ -d sourcedata/freesurfer ] ; then
  git -C sourcedata/freesurfer checkout -b $SLURM_JOB_NAME
fi


datalad containers-run -m 'fMRIPrep_sub-01_ses-None' -n containers/fmriprep-lts --input 'sourcedata/*/sub-01/ses-None/{func,fmap}/*_{sbref,bold,epi}.nii.gz' --input 'sourcedata/*/sub-01/{func,fmap}/*_{sbref,bold,epi}.nii.gz' --input 'sourcedata/smriprep/sub-01/anat/*_{T1w,T2w,FLAIR}.nii.gz' --input 'sourcedata/templateflow/tpl-{MNI152NLin2009cAsym}'--output . -- fmriprep -w ./workdir --participant-label 01 --anat-derivatives ./sourcedata/smriprep --fs-subjects-dir ./sourcedata/smriprep/sourcedata/freesurfer --bids-filter-file code/fmriprep_study-harrypotter_sub-01_ses-None_bids_filters.json --output-layout bids --ignore slicetiming --use-syn-sdc --output-spaces MNI152NLin2009cAsym T1w:res-iso2mm --cifti-output 91k --notrack --write-graph --skip_bids_validation --omp-nthreads 8 --nprocs 16 --mem_mb 65536 --fs-license-file code/freesurfer.license --resource-monitor sourcedata/harrypotter ./ participant 
fmriprep_exitcode=$?
cp $SLURM_TMPDIR/fmriprep_wf/resource_monitor.json /scratch/bpinsard/fmriprep_study-harrypotter_sub-01_ses-None_resource_monitor.json 
if [ $fmriprep_exitcode -ne 0 ] ; then cp -R $SLURM_TMPDIR /scratch/bpinsard/fmriprep_study-harrypotter_sub-01_ses-None.workdir ; fi 
exit $fmriprep_exitcode 

flock --verbose /lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter/.datalad_lock datalad push -d ./ --to origin
if [ -d sourcedata/freesurfer] ; then
    flock --verbose /lustre03/project/6003287/datasets/cneuromod_processed/fmriprep/harrypotter/.datalad_lock datalad push -d sourcedata/freesurfer $LOCAL_DATASET --to origin
fi 
