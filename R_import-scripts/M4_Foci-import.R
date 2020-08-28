### Imports QuaSI annotation output from 'Foci detection' module
QuaSI.import <- function(){
print("Please enter the path to the Quantitation output, e.g. /Users/Documents/Experiment1/Analysis/Foci/")
ppp <- readline(prompt = "path: ")
slideA.txt <- list.files(ppp)[grep("^Maxima-.+\\.txt$", list.files(ppp))]
slideA <- gsub("^^Maxima-","",slideA.txt) # remove prefixes
slideA <- gsub("\\.txt$","",slideA) # remove suffixes
for (a in slideA.txt){
out.i <- read.delim(paste(ppp,"/",a,sep=""), header = T, skip = 1, stringsAsFactors = F)
out.i$image <- slideA[grep(a,slideA.txt)]
if (a == slideA.txt[1]){
out <- out.i  
} else {
out <- rbind(out, out.i)  
}
}
print("Data imported.")
print("Do you want to save data as txt or RData?")
dt <- readline(prompt = "txt/RData: ")
if (dt == "RData"){
save(out,file = paste(ppp,"/Foci-import.RData",sep = ""))
} else {
write.table(out, file = paste(ppp,"/Foci-import.txt",sep = ""), quote = F, sep = "\t", row.names = F)  
}
print("Import complete.")
}
QuaSI.import()
rm(list = "QuaSI.import")