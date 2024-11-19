#!/bin/bash
export samplesheet=$1
export type=$2
export outSampleSheet=$3
export directories=$4

cmd="./champlain.R -s ${samplesheet} -i ${type} -o ${outSampleSheet} -d ${directories}"
echo $cmd
$cmd

if [ $? -eq 0 ]
then
  echo "Validation Successful."
else
  echo "Validation failure, fix the sample sheet!!" >&2
  exit 1
fi

nextflow run main.nf -profile singularity --input ${outSampleSheet} --outdir ${outdir} -work-dir ${workdir}
#nextflow clean -f
mamba deactivate

