### Imports QuaSI annotation output from 'ROI quantitation' module
QuaSI.import <- function(){
print("Please enter the path to the Quantitation output, e.g. /Users/Documents/Experiment1/Analysis/Quant/")
ppp <- readline(prompt = "path: ")
title <- "Quant"
slideA <- list.files(ppp)[grep("_\\D\\D\\D(\\.|_BG\\.)txt$", list.files(ppp))]
slideA <- gsub("^[^-]+-","",slideA) # remove prefixes
slideA <- gsub("_\\D\\D\\D(\\.|_BG\\.)txt$","",slideA)[-grep("Parameters",list.files(ppp))] # remove suffixes
slideN <- unique(slideA)
for (qb in c(1:2)){ 
  for (f in c(1:length(slideN))){
    indexQ <- grep(paste(slideN[f],".+[^_BG]\\.txt",sep=""), list.files(ppp))
    indexBG <- grep(paste(slideN[f],".+_BG",sep=""), list.files(ppp))
    if (qb == 1){
      index <- indexQ  
      typeA <- gsub(".*_","",list.files(ppp)[index])
      typeA <- gsub("\\.txt$","",typeA)
    } else if (qb == 2){
      index <- indexBG  
      typeA <- gsub("_BG\\.txt$","",list.files(ppp)[index])
      typeA <- gsub(".*_","",typeA)
    }
    channelA <- gsub("-.+_\\D\\D\\D(\\.|_BG\\.)txt$","",list.files(ppp)[index])
    z <- 0
    for (i in index){
      z <- z+1
      channel <- rep(channelA[z], times = dim(read.delim(paste(ppp,"/",list.files(ppp)[i],sep="")))[1])
      image <- rep(slideN[f], times = dim(read.delim(paste(ppp,"/",list.files(ppp)[i],sep="")))[1])
      type <- rep(typeA[z], times = dim(read.delim(paste(ppp,"/",list.files(ppp)[i],sep="")))[1])
      if(i == index[1]){
        data.ann <- read.delim(paste(ppp,"/",list.files(ppp)[i],sep=""))
        data.ann <- cbind(data.ann,channel,image,type)
      } else {
        dummy <- read.delim(paste(ppp,"/",list.files(ppp)[i],sep=""))
        dummy <- cbind(dummy,channel,image,type)
        data.ann <- rbind(data.ann,dummy)
      }
    }
    for (l in c(1:length(unique(paste(data.ann$channel,data.ann$image,sep="-_-"))))){ 
      l.list <- strsplit(unique(paste(data.ann$channel,data.ann$image,sep="-_-")),"-_-")
      S <- subset(subset(data.ann,  channel == l.list[[l]][1]), image == l.list[[l]][2])
      c <- dim(S)[1]/range(S$Slice)[2]
      roi <- rep(c(1:c),range(S$Slice)[2])
      S <- cbind(S,roi)
      if (l == 1){
        S.all <- S
      } else {
        S.all <- rbind(S.all,S)  
      }
    }
    if (f == 1){
      data.comb <- S.all
    } else {
      dummy.comb <- S.all
      data.comb <- rbind(data.comb, dummy.comb)
    }
    #rm(S, S.all, data.ann, dummy)
  }
  if (qb == 1){
    assign(title, data.comb)
  } else if (qb == 2){
    assign(paste(title,"BG",sep="."), data.comb)  
  }  
}
#rm(data.comb, dummy.comb, slideA, slideN,f, l, i, c, z, qb, l.list)
#rm(channel, image, type, indexQ, indexBG, roi, typeA, channelA, index, title)
print("Data imported.")
print("Do you want to subtract the background?")
bgs <- readline(prompt = "y/n: ")
if (bgs == "y"){
  quant <- Quant 
  bg <- Quant.BG 
  BGmeanA <- 0
  BGmedianA <- 0
  BGstdevA <- 0
  index <- ""
  for (m in c(1:dim(quant)[1])){
    index[m] <- paste(quant[m,"channel"],quant[m,"image"],quant[m,"type"],sep = "-_-")
  }
  for (i in c(1:dim(bg)[1])){
    matcher <- paste(bg[i,"channel"],bg[i,"image"],bg[i,"type"],sep = "-_-")
    BGmeanA[grep(matcher,index)] <- bg[i,"Mean"]
    BGmedianA[grep(matcher,index)] <- bg[i,"Median"]
    BGstdevA[grep(matcher,index)] <- bg[i,"StdDev"]
  }
  data.b <- cbind(quant,BGmeanA,BGmedianA,BGstdevA)
  names(data.b)[c((length(names(data.b))-2):length(names(data.b)))] <- c("Mean.BG","Median.BG","Stddev.BG")
  rm(bg,quant,BGmeanA,BGmedianA,BGstdevA,i,index,m,matcher)
  data <- data.b
    Mean.subBG <- data[,"Mean"] - data[,"Median.BG"]
    Median.subBG <- data[,"Median"] - data[,"Median.BG"]
    IntDen.subBG <- data[,"IntDen"] - data[,"Median.BG"]*data[,"Area"]
    data.b <- cbind(data.b,Mean.subBG,Median.subBG,IntDen.subBG)
    names(data.b)[c((length(names(data.b))-2):length(names(data.b)))] <- c("Mean.b","Median.b","IntDen.b")
    rm(data,IntDen.subBG,Mean.subBG,Median.subBG)
    print("Background subtracted.")
    }

print("Do you want to save data as txt or RData?")
dt <- readline(prompt = "txt/RData: ")
if (dt == "RData" & bgs == "y"){
save(data.b, file = paste(ppp,"/Quant-import.RData",sep = ""))
} else if (dt == "RData" & bgs == "n"){
save(Quant, Quant.BG, file = paste(ppp,"/Quant-import.RData",sep = ""))  
}else if (bgs != "y"){
write.table(Quant, file = paste(ppp,"/Quant-import.txt",sep = ""), quote = F, sep = "\t", row.names = F)
write.table(Quant.BG, file = paste(ppp,"/Quant-import_BG.txt",sep = ""), quote = F, sep = "\t", row.names = F)
} else {
write.table(data.b, file = paste(ppp,"/Quant-import_BGsubtracted.txt",sep = ""), quote = F, sep = "\t", row.names = F)  
}
print("Import complete.")
}
QuaSI.import()
rm(list = "QuaSI.import")