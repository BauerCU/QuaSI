### Imports QuaSI annotation output from 'ROI inspection' module
QuaSI.import <- function(){
print("Please enter the path to the Quantitation output, e.g. /Users/Documents/Experiment1/Analysis/ROI-inspection/")
ppp <- readline(prompt = "path: ")
INSP.man <- list.files(ppp)[grep("^Manual-analysis_.+\\.txt$", list.files(ppp))]
INSP.roi <- list.files(ppp)[grep("^ROI-annotation_.+\\.txt$", list.files(ppp))]
INSP.foc <- list.files(ppp)[grep("^Foci-annotation_.+\\.txt$", list.files(ppp))]
out.list <- list(manual = "", ROIs = "", Foci = "")
if (length(INSP.man) > 0){
slideA <- gsub("^Manual-analysis_","",INSP.man) # remove prefixes
slideA <- gsub("\\.txt$","",slideA) # remove suffixes ### INCLUDE out$type as factor with levels "Str", "Num"
  for (a in INSP.man){
    out.i <- read.delim(paste(ppp,"/",a,sep=""), header = T, skip = 1, stringsAsFactors = F)
    out.i$image <- slideA[grep(a,INSP.man)]
    if (a == INSP.man[1]){
      out <- out.i  
    } else {
      out <- rbind(out, out.i)  
    }
  }
out.list[[1]] <- out
out.list[[1]]$type <- factor(out.list[[1]]$type, levels = c("Str","Num")) 
rm(out, out.i, slideA, a)
} 
if (length(INSP.roi) > 0){
slideA <- gsub("^ROI-annotation_","",INSP.roi) # remove prefixes
slideA <- gsub("\\.txt$","",slideA) # remove suffixes
  for (a in INSP.roi){
    out.i <- read.delim(paste(ppp,"/",a,sep=""), header = T, skip = 1, stringsAsFactors = F)
    out.i$image <- slideA[grep(a,INSP.roi)]
    if (a == INSP.roi[1]){
      out <- out.i  
    } else {
      out <- rbind(out, out.i)  
    }
  }
out.list[[2]] <- out
out.list[[2]]$type <- factor(out.list[[2]]$type, levels = c("Str","Num")) 
rm(out, out.i, slideA, a)
} 
if (length(INSP.foc) > 0){
slideA <- gsub("^Foci-annotation_","",INSP.foc) # remove prefixes
slideA <- gsub("\\.txt$","",slideA) # remove suffixes
  for (a in INSP.foc){
    out.i <- read.delim(paste(ppp,"/",a,sep=""), header = T, skip = 1, stringsAsFactors = F)
    out.i$image <- slideA[grep(a,INSP.foc)]
    if (a == INSP.foc[1]){
      out <- out.i  
    } else {
      out <- rbind(out, out.i)  
    }
  }
out.list[[3]] <- out
out.list[[3]]$type <- factor(out.list[[3]]$type, levels = c("Str","Num")) 
rm(out, out.i, slideA, a)
}
print("Data imported.")
print("Do you want to save data as txt or RData?")
dt <- readline(prompt = "txt/RData: ")
insp.list <- list(manual = "", ROIs = "", Foci = "")
for (i in names(out.list)){ 
  if (length(out.list[[i]]) > 1){
  insp.list[[i]] <- split(out.list[[i]], out.list[[i]]$Annotation)
  nt <- table(out.list[[i]]$Annotation, out.list[[i]]$type)[,"Num"] != 0
    for (ii in names(insp.list[[i]])){
      insp.list[[i]][[ii]]$Annotation <- NULL
      insp.list[[i]][[ii]]$type <- NULL
      if (T %in% nt & nt[ii] == T){
        insp.list[[i]][[ii]]$user.input <- as.numeric(insp.list[[i]][[ii]]$user.input)
      }  
    }
  } else {
  insp.list[[i]] <- NULL  
  }
}
if (dt == "RData"){
  save(insp.list,file = paste(ppp,"/ROI-inspector_import.RData",sep = ""))
} else {
  for (i in names(out.list)){
    if (length(out.list[[i]]) > 1){
    write.table(out.list[[i]], file = paste(ppp,"/ROI-inspector_",i,".txt",sep = ""), quote = F, sep = "\t", row.names = F)
    }
  }
}
print("Import complete.")
}
QuaSI.import()
rm(list = "QuaSI.import")