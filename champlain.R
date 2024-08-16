#!/usr/bin/env Rscript

suppressWarnings(library(readxl))
library(tools)
library(ini)
library(stringr)
library(optparse)
source("helperFunctions.R")

parser <- OptionParser()
option_list <- list(
   make_option(c("-i", "--instrument"), help="singular, nanopore, geomx, or general"),
   make_option(c("-s", "--samplesheet"), help="sample sheet as described on the website"),
   make_option(c("-o", "--outputDirectory"), help="directory where the results will go"),
   make_option(c("-d", "--directories"), help="For Singular only: Directories where the data is located")                                  
)

opt <- parse_args(OptionParser(option_list=option_list))
type <- toupper(opt$instrument)
sampleSheet <- opt$samplesheet
samplesheetBasename <- sub(pattern = "(.*)\\..*$", replacement = "\\1", basename(sampleSheet))

outputDirectory <- opt$outputDirectory
dir.create(file.path(outputDirectory), showWarnings = FALSE)

if (type=="SINGULAR") {
  directories <- strsplit(opt$directories,",")[[1]]
} else {
  directories <- NA
}
outputSampleSheet <- paste0(outputDirectory,"/",samplesheetBasename,".csv")
workDirectory <- paste0("./deleteme/",samplesheetBasename)

validateSampleSheet(sampleSheet,type,directories)

print(paste0("Instrument: ",type))
if (type=="GEOMX") {
  concatenationSampleSheets <- createGeomxConcatSamplesheets(sampleSheet,outputSampleSheet)
  cmd <- paste0("sbatch runConcatenation.sh ",sampleSheet," ",iniOutput)
}
if (type=="NANOPORE") {
  concatenationSampleSheets <- createNanoporeSamplesheets(sampleSheet,outputSampleSheet)
}
if (type=="SINGULAR") {
  concatenationSampleSheets <- createSingularSamplesheets(sampleSheet,directories,outputSampleSheet)
} 
if (type=="GENERAL") {
  concatenationSampleSheets <- createGeneralSamplesheets(sampleSheet,outputSampleSheet)
} 

cmd <- paste0("module load singularity/3.7.1;source ~/.bashrc;mamba activate env_nf;export NXF_SINGULARITY_CACHEDIR=/gpfs1/mbsr_tools/NXF_SINGULARITY_CACHEDIR;nextflow run main.nf -profile singularity --input ",outputSampleSheet," --outdir ",outputDirectory," -work-dir ",workDirectory)
system(cmd)
