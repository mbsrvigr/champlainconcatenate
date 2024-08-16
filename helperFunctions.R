check_dirs <- function(dirs) {
  for (i in 1:length(dirs)) {
    if (! dir.exists(dirs[i])) {
      print(paste0("Directory ",dirs[i]," does not exist!!"))
      quit(status=1)
     }
  }
  print("Validation: Data directories present")
}


check_files <- function(files) {
  for (i in 1:length(files)) {
    if (! file.exists(files[i])) {
      print(paste0("File ",files[i]," does not exist!!"))
      quit(status=1)
     }
  }
  print("Validation: All files exist.")
}

validateSampleSheet <- function(sampleSheet,type, directories) {
  if (type %in% c("NANOPORE","GENERAL")) {
    data <- read.table(sampleSheet,header=TRUE,sep=",")
    header <- colnames(data)

    if (type=="NANOPORE") {
      header1 <- "BARCODE"
    } else {
      header1 <- "SAMPLE"
    }
    if (header[1]!=header1) {
      stop(paste0("First column must have ",header1," as the header."))
    }
    if (! all(grepl("DIRECTORY",header[2:length(header)]))) {
      stop("All columns except the first one must say DIRECTORYN, where N is a number")
    }
    dirs <- unlist(data[,2:ncol(data)])
    dirs <- unique(as.character(dirs[dirs!=""]))
    if (type=="NANOPORE") {
      check_dirs(dirs)
    } else {
      check_files(dirs)
    } 
  } else if (type=="SINGULAR") {
    check_dirs(directories)
  }
}
 
createNanoporeSamplesheets <- function(sampleSheet,outputFilename) {
  data <- read.table(sampleSheet,header=TRUE,sep=",")
  df <- do.call(rbind,lapply(1:nrow(data), function(n) {
    row <- data[n,]
    barcode <- tolower(row[,1])
    directories <- as.character(row[,2:ncol(row)])
    directories <- directories[directories!=""]
    fastqList <- c()
    for (j in 1:length(directories)) {
      dir <- paste0(directories[j],"/",barcode)
      pattern <- paste0(".*",barcode,".*.fastq.gz")
      fastqs <- list.files(dir,pattern=pattern,full.names=TRUE)
      fastqList <- c(fastqList,fastqs)
    }
    data.frame(id=barcode, fastqList=paste0('"',paste(fastqList,collapse=","),'"')) 
  }))
  write.table(df,file=outputFilename,row.names=FALSE,quote=FALSE,col.names=TRUE,sep=",")
}

createGeneralSamplesheets <- function(sampleSheet,outputFilename) {
  data <- read.table(sampleSheet,header=TRUE,sep=",")
  df <- do.call(rbind,lapply(1:nrow(data), function(n) {
    row <- data[n,]
    sample <- row[,1]
    files <- as.character(row[,2:ncol(row)])
    fastqList <- files[files!=""]
    data.frame(id=sample, fastqList=paste0('"',paste(fastqList,collapse=","),'"')) 
  }))
  write.table(df,file=outputFilename,row.names=FALSE,quote=FALSE,col.names=TRUE,sep=",")
}


createGeomxConcatSamplesheets <- function(sampleSheet,outputFilename) {
  data <- read.csv(sampleSheet)
  for (i in 1:nrow(data)) {
    fastqFiles <- gsub(" ","",strsplit(data[i,"FASTQ_file_location"],split=",")[[1]])
    iniFile <- data[i,"INI_Files"]
    if (!file.exists(iniFile)) {
      stop(paste0("INI file ",iniFile," does not exist"))
    }
    for (j in 1:length(fastqFiles)) {
      fastqFile <- fastqFiles[j]
      if (!file.exists(fastqFile)) {
        stop(paste0("Fastq file ",fastqFile," does not exist"))
      }
    }
  }

  geomxInput <- data.frame()
  for (i in 1:nrow(data)) {
    fastqFiles <- gsub(" ","",strsplit(data[i,"FASTQ_file_location"],split=",")[[1]])
    iniFile <- data[i,"INI_Files"]
    ini <- read.ini(iniFile)
    iniOutput <- paste0(outputDirectory,"/",basename(tools::file_path_sans_ext(iniFile)))
    if (!file.exists(iniOutput)) {
      dir.create(iniOutput)
    }
    
    aois <- names(ini$AOI_List)
    df<-do.call(rbind,lapply(1:length(aois),function(j) {
      aoi <- aois[j]
      R1 <- c()
      R2 <- c()
      for (k in 1:length(fastqFiles)) {
        fastqFile <- fastqFiles[k]
        filesR1 <- list.files(path=fastqFile,pattern=paste0(aoi,".*_R1_.*"),full.names=TRUE)
        R1 <- c(R1,filesR1)
        filesR2 <- list.files(path=fastqFile,pattern=paste0(aoi,".*_R2_.*"),full.names=TRUE)
        R2 <- c(R2,filesR2)
      }
      rbind(data.frame(ID=paste0(aoi,"_S111_L001_R1_001"),fastq=paste(R1,collapse=",")),
            data.frame(ID=paste0(aoi,"_S111_L001_R2_001"),fastq=paste(R2,collapse=",")))
      
    }))
    sampleSheet <- paste0(iniOutput,"/",basename(iniOutput),"_sampleSheet.csv")
    write.table(df,file=sampleSheet,row.names=FALSE,quote=FALSE,col.names=FALSE,sep=",")
    df <- data.frame(fastqDir=paste0(iniOutput,"/rawData"),outDir=paste0(iniOutput,"/dcc"),iniFile=iniFile)
    geomxInput <- rbind(geomxInput,df)
  }
}

createSingularSamplesheets <- function(sampleSheet,directories,outputFilename) {
  tmp <- read.csv(sampleSheet)
  idx <- which(tmp[,1]=="Sample_ID")
  data <- tmp[(idx+1):nrow(tmp),]
  colnames(data) <- tmp[idx,]
  sampleIds <- unique(data$Sample_ID)
  df <- do.call(rbind,lapply(1:length(sampleIds), function(i) {
    sampleID <- sampleIds[i]
    R1 <- c()
    R2 <- c()
    for (j in 1:length(directories)) {
      dir <- directories[j]
      filesR1 <- list.files(path=dir,pattern=paste0(sampleID,".*_R1_.*.fastq.gz"),full.names=TRUE)
      R1 <- c(R1,filesR1)
      filesR2 <- list.files(path=dir,pattern=paste0(sampleID,".*_R2_.*.fastq.gz"),full.names=TRUE)
      R2 <- c(R2,filesR2)
    }
    rbind(data.frame(id=paste0(sampleID,"_R1"),fastqList=paste0('"',paste(R1,collapse=","),'"')),
          data.frame(id=paste0(sampleID,"_R2"),fastqList=paste0('"',paste(R2,collapse=","),'"')))
  }))
  write.table(df,file=outputFilename,row.names=FALSE,quote=FALSE,col.names=TRUE,sep=",")
}


