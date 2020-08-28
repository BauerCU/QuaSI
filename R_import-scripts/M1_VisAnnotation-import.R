### Imports QuaSI annotation output from 'Visualization' module
QuaSI.import <- function(){
print("Please enter the path to the Quantitation output, e.g. /Users/Documents/Experiment1/Analysis/Visualization/")
ppp <- readline(prompt = "path: ")
slideA.txt <- list.files(ppp)[grep("^\\D\\D\\D-.+_Manual-Analysis\\.txt$", list.files(ppp))]
slideA <- gsub("^[^-]+-","",slideA.txt) # remove prefixes
slideA <- gsub("_Manual-Analysis\\.txt$","",slideA) # remove suffixes
for (a in slideA.txt){
out.i <- read.delim(paste(ppp,"/",a,sep=""), header = T, skip = 1, stringsAsFactors = F)
out.i$image <- slideA[grep(a,slideA.txt)]
if (a == slideA.txt[1]){
out <- out.i  
} else {
out <- rbind(out, out.i)  
}
}
out$type <- factor(out$type, levels = c("Str","Num"))
print("Data imported.")
print("Do you want to save data as txt or RData?")
dt <- readline(prompt = "txt/RData: ")
if (dt == "RData"){
  annot.list <- split(out, out$Annotation)
  nt <- table(out$Annotation, out$type)[,"Num"] != 0
  for (i in names(annot.list)){
    annot.list[[i]]$Annotation <- NULL
    annot.list[[i]]$type <- NULL
  if (T %in% nt & nt[i] == T){
    annot.list[[i]]$user.input <- as.numeric(annot.list[[i]]$user.input)
  }  
  }
  save(annot.list,file = paste(ppp,"/Annot-import.RData",sep = ""))
} else {
  write.table(out, file = paste(ppp,"/Annot-import.txt",sep = ""), quote = F, sep = "\t", row.names = F)  
}
print("Import complete.")
}
QuaSI.import()
rm(list = "QuaSI.import")