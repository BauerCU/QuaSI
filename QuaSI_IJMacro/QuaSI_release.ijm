///// QuaSI Macro by Christina Bauer, Department of Biomedicine, University of Basel
//Beta-version August 2020: implementing final changes in functionalities before github-upload
	
/*
 * A) Header functions (number of images, image names, channel number, input/output folder location, ...)
 * HEADER FUNCTIONS ARE ALWAYS EXECUTED 
 */

/// version number and license
QuaSIv = "4-1-2";
QuaSIl = "QuaSI - Quantitation and Segmentation of microscopic Images \n"
+"\n"
+"Copyright (c) 2019 Christina U Bauer, Department of Biomedicine, University of Basel \n"
+" \n"
+"Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'),\n" 
+"to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, \n"
+"and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: \n"
+" \n"
+"The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. \n"
+"If this Software is referred to in a scientific publication, the link to the original github repository (https://github.com/BauerCU/QuaSI) shall be included. \n"
+" \n"
+"THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \n"
+"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \n"
+"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS \n"
+"IN THE SOFTWARE. \n"
+" \n"
+"version: ";

showMessage("License and version", QuaSIl + QuaSIv); 

// custom functions
function getIndex(ARRAY, VALUE){ // returns -1 if VALUE is not part of ARRAY
	i = 0;
	while (ARRAY[i] != VALUE && i < lengthOf(ARRAY)-1){
	i = i+1;}
	if (ARRAY[i] == VALUE){
	o = i;
	} else {
	o = -1;	
	}
return o;
}
function closeRegex(PATTERN){
	ALL = getList("image.titles");
	for (i = 0; i < lengthOf(ALL); i += 1){
	if (matches(ALL[i], PATTERN) == true){
	selectWindow(ALL[i]);
	close();}
	}
}
function StrToNumArray(STRING){ // function to convert comma and minus separated strings to array of numbers (e.g. "3,5,7-9" from user input)
	minusA = split(STRING,"-"); 
	commaA = split(STRING,",");
	if(lengthOf(minusA)==1){
		for (i = 0; i < lengthOf(commaA); i += 1){
		commaA[i] = parseInt(commaA[i]);	
		}
	numberA = commaA;
	} else if (lengthOf(commaA)==1){
	helperA = Array.getSequence(minusA[1]+1);
	numberA = Array.slice(helperA,minusA[0],minusA[1]+1);	
	} else {
	numberA = 0; // Dummy initiator, gets trimmed later
	for (i = 0; i < lengthOf(commaA); i += 1){
	ihelper = split(commaA[i],"-");
		if (lengthOf(ihelper) == 2){
		helperA = Array.slice(Array.getSequence(ihelper[1]+1),ihelper[0],ihelper[1]+1);	
		} else {
		helperA = commaA[i];	
		}
	numberA = Array.concat(helperA,numberA);
	}
	numberA = Array.trim(numberA,lengthOf(numberA)-1);
		for (l = 0; l < lengthOf(numberA); l += 1){
		numberA[l] = parseInt(numberA[l]);	
		}
	}
	Array.sort(numberA);
return numberA;
}
function parseIntArray(ARRAY){ 
	for (i = 0; i < lengthOf(ARRAY); i += 1){
	ARRAY[i] = parseInt(ARRAY[i]);	
	}
}
//initial variables
taskA = newArray("Visualization", "ROI mask generation", "ROI quantitation", "Foci analysis", "ROI inspection");
DyeA = newArray("DAPI", "GFP", "RFP", "FITC", "Cy3", "Cy5", "Far Red");
ColourA = newArray("blue", "green", "red", "gray", "cyan", "magenta", "yellow");
BIchannelA = newArray("zero","red","green","blue","gray","cyan","magenta","yellow"); // Built-in-channel Array - DO NOT change, reflects order of ImageJ's "Merge-colour" dialog
projectionA = newArray("Average Intensity", "Max Intensity", "Min Intensity", "Sum Slices", "Median", "Standard Deviation");
projectpreA = newArray("AVG", "MAX", "MIN", "SUM", "MED", "STD");
//start Macro
processSource = "default";
folderI = getDirectory("home");
useInfo = false;
do {
if(processSource != "process images in folder"){
seriesN = nImages(); //number of open images
seriesNA = getList("image.titles"); //list of image names
folder = getDirectory("image"); //default path for dialog box
} else {
seriesNA = getFileList(folderI);
seriesNA = Array.deleteValue(seriesNA, "Analysis/"); //Rewrite to get rid of all folders?
seriesN = lengthOf(seriesNA);
folder = folderI;	
}
if (seriesN != 0){
Array.show("Open images", seriesNA);
selectWindow("Open images");
setLocation(screenWidth*0.25, screenHeight*0.25);
// user defines functions to use
Dialog.create("Module selection");
	Dialog.addMessage("There are "+seriesN+" images about to be processed. \n Please select the tasks you want to perform.");
	Dialog.addCheckboxGroup(5,1,taskA,newArray(false, !true, !true, false, false));
	Dialog.addString("Folder path for analysis output", folder, 90);
	Dialog.addCheckbox("execute in 'Crash-Rescue mode'",false);
	Dialog.setLocation(screenWidth*0.5, screenHeight*0.25);
Dialog.show();
visB = Dialog.getCheckbox();
roiB = Dialog.getCheckbox();
quantB = Dialog.getCheckbox();
fociB = Dialog.getCheckbox();
inspB = Dialog.getCheckbox();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
crM = Dialog.getCheckbox();
if (File.exists(folder+"Analysis") == true && crM == false){
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified already contains an analysis ouput. This might lead to overwriting of data.\n"+
						"Do you want to specify an alternative folder?");
	Dialog.addString("folder path", folder, 90);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
} else if (File.exists(folder+"Analysis") == false && crM == true) {
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified does not contain an analysis ouput. 'Crash-Rescue mode' can only be executed \nwith the default Analysis folder structure."+
						"Please specify another folder path.");
	Dialog.addString("folder path", folder, 90);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}	
}
File.makeDirectory(folder+"Analysis");
File.makeDirectory(folder+"Analysis/Info");
File.makeDirectory(folder+"Analysis/Temp");	
if (visB == true){
File.makeDirectory(folder+"Analysis/Visualization");}
if (roiB == true){
File.makeDirectory(folder+"Analysis/ROIs");}
if (quantB == true){
File.makeDirectory(folder+"Analysis/Quant");}
if (fociB == true){
File.makeDirectory(folder+"Analysis/Foci");}
if (inspB == true){
File.makeDirectory(folder+"Analysis/ROI-inspection");}
selectWindow("Open images");
run("Close");
} else {
Dialog.create("No open images");
	Dialog.addMessage("There are no open images. How do you want to proceed?");
	Dialog.addChoice("select images", newArray("process images in folder","open images to process"));
Dialog.show();
processSource = Dialog.getChoice();
if (processSource == "process images in folder"){
Dialog.create("Specify image folder");
	Dialog.addString("Image folder path", folderI, 90);
	Dialog.addCheckbox("Use information from Info folder",false); 
Dialog.show();
folderI = Dialog.getString();
if (matches(folderI,".+/$") == false){
folderI = folderI+"/";	
}
imageSource = folderI;
useInfo = Dialog.getCheckbox();
if (useInfo == true){
do {
	if (matches(folderI, ".+/Temp/$") == true){
	fileInfo = substring(folderI, 0, lengthOf(folderI)-6)+"/Info/Image-Data_all.txt";
	} else {
	fileInfo = folderI+"Analysis/Info/Image-Data_all.txt";
	}
Dialog.create("Specify image data file to import");
	Dialog.addString("Image Data file", fileInfo, 90);
Dialog.show();
fileInfo = Dialog.getString();
} while (File.exists(fileInfo) == false)
}
} else {
waitForUser("Open Images", "Please open the images you want to process. \nConfirm with okay once images are loaded.");}
}
} while (seriesN == 0)
String.show("license and version", QuaSIl + QuaSIv);
save(folder+"Analysis/Info/License_version.txt");
selectWindow("License_version.txt");
run("Close");
setBatchMode(true);
seriesA = newArray(seriesN+1); // array to be created with new image names (without spaces, /, etc.)
widthA = newArray(seriesN+1);
heightA = newArray(seriesN+1);
channelA = newArray(seriesN+1); // number of channels
sliceA = newArray(seriesN+1);
frameA = newArray(seriesN+1);
XsizeA = newArray(seriesN+1);
YsizeA = newArray(seriesN+1);
ZsizeA = newArray(seriesN+1);
unitA = newArray(seriesN+1);
if (processSource != "process images in folder"){
imageSource = folder+"Analysis/Temp/";	
}
seriesNA = Array.concat("original name", seriesNA); // Array header for output file
for (i = 1; i <= seriesN; i += 1){ // begin central loop to create arrays for Image-Data-file
//showStatus("processing image "+i+"/"+seriesN);
seriesA[0] = "processed name"; // Array headers for output file
widthA[0] = "image width";
heightA[0] = "image height";
channelA[0] = "# channels";
sliceA[0] = "# slices";
frameA[0] = "# frames";
XsizeA[0] = "pixel width";
YsizeA[0] = "pixel height";
ZsizeA[0] = "pixel depth";
unitA[0] = "pixel size unit";
if (useInfo == false){ // opening images to retrieve metadata
if (processSource != "process images in folder"){
selectWindow(seriesNA[i]);
} else {
open(folderI+seriesNA[i]);	
}

	Stack.getDimensions(width, height, channels, slices, frames);
		widthA[i] = width;
		heightA[i] = height;
		channelA[i] = channels;
		sliceA[i] = slices;
		frameA[i] = frames;
	getVoxelSize(width, height, depth, unit);
		XsizeA[i] = width;
		YsizeA[i] = height;
		ZsizeA[i] = depth;
		unitA[i] = unit;
} else { 
infoList = split(File.openAsString(fileInfo),"\n\t"); //array of Image Data file - line after line
infoNo = (lengthOf(infoList)/11) - 2; // this is the number of images in the info file
infoSeriesNA = newArray(infoNo);
infoSeriesA = newArray(infoNo);
for (ic = 0; ic < infoNo; ic += 1){
infoSeriesNA[ic] = infoList[22+ic*11]; //rewrite this part to make independent of column number
infoSeriesA[ic] = infoList[23+ic*11];
}
if (getIndex(infoList, substring(seriesNA[i],0,indexOf(seriesNA[i],"."))) != -1){ 
oriName = getIndex(infoSeriesNA, seriesNA[i]) != -1; // t/f if image name is in the seriesNA column of the image data file
if(indexOf(seriesNA[i], ".tif") != -1){
shortName = getIndex(infoSeriesA, substring(seriesNA[i],0,indexOf(seriesNA[i], ".tif"))) != -1; // t/f if image name is in the seriesA column of the image data file
} else {
shortName = false;		
}
	if (oriName == true){
	ii = getIndex(infoList, seriesNA[i]);
	} else if (shortName == true){
	ii = getIndex(infoList, substring(seriesNA[i],0,indexOf(seriesNA[i], ".tif"))) - 1;
	}
widthA[i] = infoList[ii+getIndex(infoList,"widthA")];
heightA[i] = infoList[ii+getIndex(infoList,"heightA")];
channelA[i] = infoList[ii+getIndex(infoList,"channelA")];
sliceA[i] = infoList[ii+getIndex(infoList,"sliceA")];
frameA[i] = infoList[ii+getIndex(infoList,"frameA")];
XsizeA[i] = infoList[ii+getIndex(infoList,"XsizeA")];
YsizeA[i] = infoList[ii+getIndex(infoList,"YsizeA")];
ZsizeA[i] = infoList[ii+getIndex(infoList,"ZsizeA")];
unitA[i] = infoList[ii+getIndex(infoList,"unitA")];
seriesNA[i] = infoList[ii+getIndex(infoList,"seriesNA")];
seriesA[i] = infoList[ii+getIndex(infoList,"seriesA")];
} else {
showMessageWithCancel("Warning", seriesNA[i]+" \n is not included in Image-Data file!");
//suggestion: Make option to open image to retrieve metadata 		
}
} // if-loop for open/not open images
if (useInfo == false){
//reformatting image names for compatibility and clarity
series = seriesNA[i];
removers = newArray(" - ",".lif",".tif",".tiff",".png",".jpg",".JPG",".jpeg",".JPEG"," ",",","/",".",":",";"); // list of expressions to remove from file name
for (l = 0; l < lengthOf(removers); l += 1){
series = replace(series,removers[l], "_");}
while (matches(series, ".*__.*") == true) {
	series = replace(series, "__", "_");}
while (matches(series, "^_.*") == true) {
	series = replace(series, "^_", "");}
while (matches(series, ".*_$") == true) {
	series = replace(series, "_$", "");}
if (matches(series,".*Mark_and_Find_.*") == true){
	series = replace(series, "Mark_and_Find_", "MF");
	}
if (series != seriesNA[i]){
seriesA[i] = series;
} else {
seriesA[i] = series+"_1";} // to ensure that working copies have different name than original file
selectWindow(seriesNA[i]);
if (File.exists(folder+"Analysis/Temp/"+seriesA[i]+".tif") == false && processSource != "process images in folder"){
save(folder+"Analysis/Temp/"+seriesA[i]+".tif");}
close();
}
parseIntArray(widthA);
parseIntArray(heightA);
parseIntArray(channelA);
parseIntArray(sliceA);
parseIntArray(frameA);
Array.show("Basic Image Data", seriesNA, seriesA, widthA, heightA, channelA, sliceA, frameA, XsizeA, YsizeA, ZsizeA, unitA);
selectWindow("Basic Image Data");
if (useInfo == false){
save(folder+"Analysis/Info/Image-Data.txt");
selectWindow("Image-Data.txt");
run("Close");
} else {
save(folder+"Analysis/Info/Image-Data_cp.txt");
selectWindow("Image-Data_cp.txt");
run("Close");	
} 
} // end central loop to create arrays for Image-Data-file
warnIg = false; // initial value for warning messages
for (i = 2; i <= seriesN; i += 1){
	if (widthA[1] != widthA[i] || heightA[1] != heightA[i] || channelA[1] != channelA[i] || XsizeA[1] != XsizeA[i] || YsizeA[1] != YsizeA[i] || ZsizeA[1] != ZsizeA[i] || unitA[1] != unitA[i] /*|| sliceA[1] != sliceA[i]*/){
		if (warnIg == false){
		Dialog.create("Warning");
		Dialog.addMessage("One or more selected images have different dimensions, \n e.g. voxel size or number of channels. Do you wish to continue?");
		Dialog.addCheckbox("Ignore this warning", warnIg);
		Dialog.show();
		warnIg = Dialog.getCheckbox();}
	}
}
setBatchMode(false);

/* 
 * B) Visual inspection / Montage creation --> look at different projection types, mid sections etc.
 * include possibilty to mark images as "low quality" that will can be excluded during quantitations, add Dialog box to include counting mitosis o.a.
 */ 
if (visB == true){
VprojectionTA = newArray(seriesN+1); // Arrays to store parameters for subsequent processing
VfirstZA = newArray(seriesN+1);
VlastZA = newArray(seriesN+1);
VbadA = newArray(seriesN+1);
VchannelNA = newArray(seriesN+1); // stores channel names (entered by user) as string separated by ';'
VcontrastA = newArray(seriesN); // internal Array to store information of previous images
VscalebarA = newArray(seriesN+1);
VRGBbwA = newArray(seriesN+1);
VintscaleA = newArray(seriesN+1);
Vrepeat = false;
sameVP = false;
Vover = "yes";
skipVover = false;
VprojectionA = Array.concat(projectionA,"mid section");
VprefixA = Array.concat(projectpreA,"MID");
Vsave = true;
Vborder = "3";
VscaleL = 10;
VscaleH = 5;
VscaleHide = false;
VscaleP = "Lower Right";
Vintscale = "to bit-depth";
VRGBcol = "convert to greyscale";
VRGBbw = "light structure, dark background";
VskipRGB = false;
if (crM == true){ // debug, only works if "use info from info file" is unchecked?!
while (File.exists(folder+"Analysis/Visualization") == false){
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified does not contain any folder 'Analysis/Visualization'. 'Crash-Rescue mode' can only be executed \nwith the default Analysis folder structure."+
						"Please specify another folder path.");
	Dialog.addString("folder path", folder, 90);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
}	
visCrash = split(File.openAsString(folder+"Analysis/Visualization"+"/Image-Data_Visualization.txt"),"\n\t"); //array of Visualization file - line after line
visColumns = lengthOf(visCrash)/(seriesN+2);
i = 0;
do {
i = i +1;
crashI = getIndex(visCrash,seriesA[i]);
Nullcount = 0;
loopcount = 0;
for (c = 1; c < visColumns; c += 1){
	if (visCrash[crashI+c] == 0){
	Nullcount = Nullcount + 1;}
	loopcount = loopcount + 1;
}
	if (Nullcount == loopcount){
	allNull = true;	
	} else {
	allNull = false;	
	}
} while (i < seriesN && allNull == false); // i will be the first "missed" image file after crash
crashStart = i;
} else {
crashStart = 1;	
}
for (sl = 1; sl <= seriesN; sl += 1){ // begin central loop that loops over images
if (sl >= crashStart){
if (matches(imageSource, ".*/Analysis/Temp/$") == true){
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
}
rename("Tmp_"+seriesA[sl]);
setBatchMode(true); 
run("Duplicate...", "duplicate");
rename(seriesA[sl]);
if (channelA[sl] > 1 || sliceA[sl] > 1){
Stack.setDisplayMode("grayscale");	
} else if (bitDepth() == 24){ // check if RGB image
if (VskipRGB == false){
Dialog.create("RGB image");
	Dialog.addMessage("You have opened an RGB image - how should the image be handled?");
	//Dialog.addRadioButtonGroup("Colors: ", newArray("split to channels", "convert to greyscale"), 1, 2, VRGBcol); // code stub
	Dialog.addRadioButtonGroup("Structure of interest: ", newArray("dark structure, light background", "light structure, dark background"), 1, 2, VRGBbw);
	Dialog.addCheckbox("apply to all?", true)
Dialog.show();
//VRGBcol = Dialog.getRadioButton(); // code stub
VRGBbw = Dialog.getRadioButton();
VskipRGB = Dialog.getCheckbox();
}
if (VRGBcol == "convert to greyscale"){
run("RGB to Luminance"); // enhance this part with the option to split channels and rearrange in greyscale stack, see code stubs above
}
if (VRGBbw == "dark structure, light background"){
run("Invert LUT");}	
} else {
run("Grays");	
}
if (channelA[sl] > 1){
run("Split Channels"); // default naming: C1-series, C2-series, ...
} else {
rename("C1-"+seriesA[sl]);	
}
if (sliceA[sl] > 1){ // make Montages if image = stack
Mrows = floor(sqrt(sliceA[sl])); //calculate Mcolumns, Mrows for Montage creaction
Mcolumns = round(sliceA[sl]/Mrows);
	while (Mrows*Mcolumns < sliceA[sl]){
	Mcolumns = Mcolumns + 1; }
for (l = 1; l <= channelA[sl]; l += 1){
	selectWindow("C"+l+"-"+seriesA[sl]);
	run("Make Montage...", "columns="+Mcolumns+" rows="+Mrows+" scale=0.25 font=10 label");
	selectWindow("Montage");
	rename("Montage-C"+l+"-"+seriesA[sl]);
} // end loop Montage creation for stack visualization
setBatchMode("exit and display");
for (l = 1; l <= channelA[sl]; l += 1){ // arrange montages and Dialog box
selectWindow("Montage-C"+l+"-"+seriesA[sl]);
getLocationAndSize(x,y,width,height);
	Mwidth = width;
	Mheight = height;
	if (Mwidth*channelA[sl] > screenWidth){
	Mwidth = screenWidth/channelA[sl];	}
	if (Mheight > screenHeight){
	Mheight = screenHeight;}
setLocation(0+(l-1)*Mwidth,(screenHeight-Mheight)/2);	
}
} // end if loop for stacks (make Montages)
dwC = 0; // do-while-Counter
do { //start do-while loop for Visualization
	if (sl == crashStart && Vrepeat == false){ //start loop for initial values in dialog box
	channelNA = newArray(channelA[sl]);
	customColA = newArray(channelA[sl]);
	for (i = 0; i < channelA[sl]; i += 1){
	channelNA[i] = DyeA[i];	}
	for (i = 0; i < channelA[sl]; i += 1){
	customColA[i] = ColourA[i];	}
	customMan = "Apoptosis - Num;Mitosis - Num;Apoptosis stage - Str;Mitosis phase - Str";
	firstZ = 1;
	lastZ = sliceA[sl];
	if (sliceA[sl] > 1){
	VprojectionI = 3; // default value: sum slices
	} else {
	VprojectionI = getIndex(VprojectionA, "mid section");}
	} else if (sl > crashStart && Vrepeat == false){
	firstZ = 1;
	lastZ = sliceA[sl]; 	
	} // end if loop for initial values (default channel names, colours, etc.)
if (Vrepeat == true || sameVP == false){
Dialog.create("Visualization");
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addString("Name of channel C"+l, channelNA[l-1]);}
	Dialog.addMessage("Channel names should not include hyphens ('-').");
	if (channelA[sl] > 1){
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addChoice("Colour for channel C"+l, ColourA, customColA[l-1]);}}
	Dialog.addSlider("1st slice",1,sliceA[sl],firstZ);
	Dialog.addSlider("Last slice",1,sliceA[sl],lastZ);
	Dialog.addChoice("Visualization Mode/Projection type", VprojectionA, VprojectionA[VprojectionI]);
	Dialog.addString("line width between channels [px]", Vborder);
	Dialog.addString("scale bar length ["+unitA[sl]+"]", VscaleL);
	Dialog.addString("scale bar height [px]", VscaleH);
	Dialog.addCheckbox("hide scale label", VscaleHide);
	Dialog.addChoice("scale bar position", newArray("Upper Right","Upper Left","Lower Right","Lower Left"), VscaleP);
	Dialog.addRadioButtonGroup("scale pixel intensity", newArray("to bit-depth", "to Min/Max"), 1, 2, Vintscale);
	Dialog.addMessage("Intensity scaling WILL NOT AFFECT quantitation and is for visualization purposes only.");
	// include montage scaling factor?
	Dialog.addString("Custom manual analysis parameters (Name - Type), separated by ';'", customMan, 75); // evtl. add link to help page here ?!
	Dialog.addCheckbox("Same settings for all images?", sameVP);
	Dialog.setLocation(screenWidth*0.4,screenHeight*0.1);
Dialog.show();
setBatchMode(true); 
for (l = 1; l <= channelA[sl]; l += 1){
channelNA[l-1] = Dialog.getString();
channelNA[l-1] = replace(channelNA[l-1],"-","_");}	
if (channelA[sl] > 1){
for (l = 1; l <= channelA[sl]; l += 1){
customColA[l-1] = Dialog.getChoice();}}
firstZ = Dialog.getNumber(); // Slider
lastZ = Dialog.getNumber(); // Slider
VprojectionT = Dialog.getChoice();
Vborder = Dialog.getString();
VscaleL = Dialog.getString();
VscaleH = Dialog.getString();
VscaleHide = Dialog.getCheckbox();
VscaleP = Dialog.getChoice();
Vintscale = Dialog.getRadioButton();
if (VscaleHide == true){
	VscalePH = " hide ";
} else {
	VscalePH = " ";
}
customMan = Dialog.getString();
VprojectionI = getIndex(VprojectionA, VprojectionT);
	customManA = split(customMan,";"); //start extraction of custom analysis parameters
	customManNA = newArray(lengthOf(customManA)); // name array
	customManTA = newArray(lengthOf(customManA)); // type array
	for (i = 0; i < lengthOf(customManA); i += 1){
		helperA = split(customManA[i],"( - )");
		customManNA[i] = helperA[0];
		customManTA[i] = helperA[1];}
sameVP = Dialog.getCheckbox();
} // end if-loop Visualization-Dialog "same visualization parameters"
if (VprojectionT != "mid section"){
	for (l = 1; l <= channelA[sl]; l += 1){
	selectWindow("C"+l+"-"+seriesA[sl]);
	run("Z Project...", "start="+firstZ+" stop="+lastZ+" projection=["+VprojectionA[VprojectionI]+"]");
	selectWindow(projectpreA[VprojectionI]+"_C"+l+"-"+seriesA[sl]);
	// scale grayscale values to maximum bit Depth OR do autocontrast
	if (Vintscale == "to bit-depth"){
	setMinAndMax(0, pow(2,bitDepth()));
	} else { 
	getStatistics(area, mean, min, max);
	setMinAndMax(min, max);}
	}
} else {
plane = firstZ+floor((lastZ-firstZ+1)/2);
	for (l = 1; l <= channelA[sl]; l += 1){
	selectWindow("C"+l+"-"+seriesA[sl]);
	run("Duplicate...", "title=MID_C"+l+"-"+seriesA[sl]+" duplicate range="+plane+"-"+plane);
	selectWindow("MID_C"+l+"-"+seriesA[sl]);
	// scale grayscale values to maximum bit Depth OR do autocontrast
	if (Vintscale == "to bit-depth"){
	setMinAndMax(0, pow(2,bitDepth()));
	} else { 
	getStatistics(area, mean, min, max);
	setMinAndMax(min, max);}
	}
}// end loop that makes projections or selects mid section for individual channels
if (channelA[sl] > 1){
DefMergePara = ""; // define parameters for merging channels, initializer
	for (l = 1; l <= channelA[sl]; l += 1){
	w = getIndex(BIchannelA, customColA[l-1]);
	DefMergePara = DefMergePara+"c"+w+"="+VprefixA[VprojectionI]+"_C"+l+"-"+seriesA[sl]+" ";
	}
run("Merge Channels...", DefMergePara + "keep");
selectWindow("RGB");
rename(VprefixA[VprojectionI]+"_merge-"+seriesA[sl]);
run("Images to Stack", "name="+VprefixA[VprojectionI]+"_stack-"+seriesA[sl]+" title="+VprefixA[VprojectionI]+"_ keep"); // note: name: stack name to give; title: image titles that define images to be included in stack
selectWindow(VprefixA[VprojectionI]+"_stack-"+seriesA[sl]);
run("Make Montage...", "columns="+(channelA[sl]+1)+" rows=1 scale=1 border="+Vborder); 
selectWindow("Montage");
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Scale Bar...", "width="+VscaleL+" height="+VscaleH+" font=12 color=White background=None location=["+VscaleP+"]"+VscalePH+"overlay"); 
rename(VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]);
} else {
selectWindow(seriesA[sl]);	
if (bitDepth() == 24){ // for RGB-pictures: show greyscale and RGB side by side
run("Duplicate...", "duplicate");
rename(VprefixA[VprojectionI]+"_RGB_"+seriesA[sl]);
run("Images to Stack", "name="+VprefixA[VprojectionI]+"_stack-"+seriesA[sl]+" title="+VprefixA[VprojectionI]+"_ keep"); // note: name: stack name to give; title: image titles that define images to be included in stack
selectWindow(VprefixA[VprojectionI]+"_stack-"+seriesA[sl]);
run("Make Montage...", "columns="+(channelA[sl]+1)+" rows=1 scale=1 border="+Vborder); 
selectWindow("Montage");
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Scale Bar...", "width="+VscaleL+" height="+VscaleH+" font=12 color=White background=None location=["+VscaleP+"]"+VscalePH+"overlay"); 
rename(VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]);
} else {
selectWindow(VprefixA[VprojectionI]+"C1-"+seriesA[sl]);	
rename(VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]);
}
}
customManVA = newArray(lengthOf(customManA)); // Value array for custom manual analysis
Array.show(customManA,customManTA,customManNA);
setBatchMode("exit and display"); 
idwC = 0; // do-while Counter inner loop
do { // begin do-while loop for contrast adjustments
if (idwC > 0){
adContrast = false;
} else if (sl > 1) {
adContrast = VcontrastA[sl-2];	
} else {
adContrast = false;	}
Dialog.create("Visual inspection, image "+sl+" / "+seriesN);
	Dialog.addMessage("If you activate 'Adjust contrast', this dialog will appear again to allow annotations etc.");
	Dialog.addCheckbox("Adjust contrast / hide dialogue",adContrast);
	Dialog.addCheckbox("Save?",Vsave); // Montage will be saved as tif, parameters will be saved to arrays (potentially overwrites previous values)
	Dialog.addCheckbox("Mark image as bad quality",false); //can be excluded in other analysis like ROI generation etc. 
	Dialog.addCheckbox("Repeat visualization with different parameters",false); //loop through procedure again to make different projections etc.
	for (i = 0; i < lengthOf(customManA); i += 1){
		if (customManTA[i] == "Num"){
		Dialog.addNumber(customManNA[i],0);}
		else if (customManTA[i] == "Str"){
		Dialog.addString(customManNA[i],"");}
		else{
		Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	}
	Dialog.setLocation(screenWidth*0.4,screenHeight*0.01);
Dialog.show();
adContrast = Dialog.getCheckbox();
Vsave = Dialog.getCheckbox();
Vbad = Dialog.getCheckbox();
Vrepeat = Dialog.getCheckbox();
for (i = 0; i < lengthOf(customManA); i += 1){
if (customManTA[i] == "Num"){
customManVA[i] = Dialog.getNumber();}
else if (customManTA[i] == "Str"){
customManVA[i] = Dialog.getString();}
}
if (idwC == 0){
VcontrastA[sl-1] = adContrast;}
if (adContrast == true){
idwC = idwC + 1;
waitForUser("Brightness/Contrast", "You can adjust brightness and contrast of your image with 'Shift+C'." +
"\nThis will not affect any quantitations and is for data presentation purposes only.\nConfirm with Ok.");}
} while (adContrast == true)
if (Vsave == true && dwC == 0){
selectWindow(VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]);
saveAs("Tiff", folder+"Analysis/Visualization/"+VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]+".tif");
} else if (Vsave == true && dwC > 0){
selectWindow(VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]);
saveAs("Tiff", folder+"Analysis/Visualization/"+VprefixA[VprojectionI]+"_Montage-"+seriesA[sl]+"_"+dwC+".tif");	
}
closeRegex("^"+VprefixA[VprojectionI]+"_.*");
dwC = dwC + 1;
if (dwC > 1 && skipVover == false){
Dialog.create("Overwrite values?"); 
	Dialog.addMessage("Do you want to replace the stored values from the previous Visualization?");
	Dialog.addRadioButtonGroup("Overwrite?", newArray("yes","no"),1,2,Vover);
	Dialog.addCheckbox("Do not ask again", skipVover);
Dialog.show();
Vover = Dialog.getRadioButton();
skipVover = Dialog.getCheckbox();
} else if (dwC == 1 && skipVover == false) { Vover = "no";}
if (dwC == 1 || Vover == "yes"){
	VprojectionTA[sl] = VprojectionT; // Arrays to store parameters for subsequent processing
	VfirstZA[sl] = firstZ;
	VlastZA[sl] = lastZ;
	VbadA[sl] = Vbad; // stored as 1 (true) and 0 (false) --> exclude files when bad==1
	VscalebarA[sl] = VscaleL;
		channelN = ""; //initializer
		for (l = 0; l < channelA[sl]; l += 1){
		channelN = channelN + channelNA[l] + ";";	}
	VchannelNA[sl] = substring(channelN,0,lengthOf(channelN)-1); // crops off last ';'
	VRGBbwA[sl] = VRGBbw;
	VintscaleA[sl] = Vintscale;
	if (customMan != ""){ // add column headers here ...
		customManNA = Array.concat("Annotation",customManNA);
		customManTA = Array.concat("type", customManTA);
		customManVA = Array.concat("user input", customManVA);
		Array.show("Custom Manual Analysis",customManNA, customManTA, customManVA);
		selectWindow("Custom Manual Analysis");
		save(folder+"Analysis/Visualization/"+VprefixA[VprojectionI]+"-"+seriesA[sl]+"_Manual-Analysis.txt");
		selectWindow(VprefixA[VprojectionI]+"-"+seriesA[sl]+"_Manual-Analysis.txt");
		run("Close");
		customManNA = Array.slice(customManNA,1,lengthOf(customManNA));
		customManTA = Array.slice(customManTA,1,lengthOf(customManTA));
		customManVA = Array.slice(customManVA,1,lengthOf(customManVA));}
} // end if loop for image data storage
} while (Vrepeat == true) //end do/while loop for visualization
closeRegex(".*[_-]"+seriesA[sl]);
} else if (crM == true && sl < crashStart){ 
fileI = getIndex(visCrash,seriesA[sl]);
VchannelNA[sl] = visCrash[fileI+getIndex(visCrash,"VchannelNA")];
VprojectionTA[sl] = visCrash[fileI+getIndex(visCrash,"VprojectionTA")];
VfirstZA[sl] = visCrash[fileI+getIndex(visCrash,"VfirstZA")];
VlastZA[sl] = visCrash[fileI+getIndex(visCrash,"VlastZA")];
VbadA[sl] = visCrash[fileI+getIndex(visCrash,"VbadA")];
VscalebarA[sl] = visCrash[fileI+getIndex(visCrash,"VscalebarA")];
VRGBbwA[sl] = visCrash[fileI+getIndex(visCrash,"VRGBbwA")];
VintscaleA[sl] = visCrash[fileI+getIndex(visCrash,"VintscaleA")];
} // end if loop for crash rescue mode 
VchannelNA[0] = "Channel names";
VprojectionTA[0] = "Projection type";
VfirstZA[0] = "first slice";
VlastZA[0] = "last slice";
VbadA[0] = "bad quality?";
VscalebarA[0] = "bar length";
VRGBbwA[0] = "Structure of interest";
VintscaleA[0] = "intensity scaling";
Array.show("Image Data Visualization", seriesA, VchannelNA, VprojectionTA, VfirstZA, VlastZA, VbadA, VscalebarA, VRGBbwA, VintscaleA); // add RGB info and intensity scaling info here!
selectWindow("Image Data Visualization");
save(folder+"Analysis/Visualization/"+"Image-Data_Visualization.txt");
selectWindow("Image-Data_Visualization.txt");
run("Close");
} // end for loop that loops over images
waitForUser("Visualization completed", "You have completed the task 'Visualization'.");
} // end if loop for execution of the "Visualization" macro part

/* 
 * C) Create ROI masks, enable enhance contrast/brightness at ROI mask confirmation, ask to exclude "bad quality images"
 */ 
if (roiB == true){
RchannelNA = newArray(seriesN+1); // arrays for 'Configuration file'
RchannelA = newArray(channelA[0]); // initial array
RprojectionTA = newArray(seriesN+1);
RfirstZA = newArray(seriesN+1);
RlastZA = newArray(seriesN+1);
maskChanA = newArray(seriesN+1);
badBA = newArray(seriesN+1);
rbrA = newArray(seriesN+1);
thrA = newArray(seriesN+1);
//cesA = newArray(seriesN+1);
pftyA = newArray(seriesN+1);
pfraA = newArray(seriesN+1);
ftyA = newArray(seriesN+1);
fraA = newArray(seriesN+1);
fihA = newArray(seriesN+1);
sizA = newArray(seriesN+1);
cirA = newArray(seriesN+1);
skipwsA = newArray(seriesN+1);
satA = newArray(seriesN+1);
roiCA = newArray(seriesN+1);
RRGBbwA = newArray(seriesN+1);
folderVis =folder+"Analysis/Visualization/";
rbr = 100;
thr = "none";
//ces = 5.0;
pfty = "Maximum";
pfra = 2;
fty = "Median";
fra = 6;
fih = "before watershed";
siz = "5-500";
cir = "0.30-1.00";
skipws = false;
slo = true;
skipconf = false;
skipBad = "no";
visBorders = "yes";
maskI = 0;
skipVW = false;
RRGBcol = "convert to greyscale";
RRGBbw = "light structure, dark background";
RskipRGB = false;
RprojectionA = Array.concat(projectionA,"mid section");
RprojectpreA = Array.concat(projectpreA,"MID");	
priorC = 0;
crExit = false;
Rcol = "yellow";
Rlab = false;
if (crM == true){
while (File.exists(folder+"Analysis/ROIs/Configuration.txt") == false){
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified does not contain any folder 'Analysis/ROIs' with a 'Configuration.txt' file.\n'Crash-Rescue mode' can only be executed with the default Analysis output structure."+
						" \nPlease specify another folder path.");
	Dialog.addString("folder path", folder, 90);
	Dialog.addCheckbox("Exit crash rescue mode", false);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
crExit = Dialog.getCheckbox();}
if (crExit == false){	
roiCrash = split(File.openAsString(folder+"Analysis/ROIs"+"/Configuration.txt"),"\n\t"); //array of Configuration file - line after line
roiColumns = lengthOf(roiCrash)/(seriesN+2); // 2 for first two header lines (variable name + description)
i = 0;
do {
i = i +1;
crashI = getIndex(roiCrash,seriesA[i]);
Nullcount = 0;
loopcount = 0;
for (c = 1; c < roiColumns; c += 1){
	if (roiCrash[crashI+c] == 0){
	Nullcount = Nullcount + 1;}
	loopcount = loopcount + 1;
}
	if (Nullcount == loopcount){
	allNull = true;	
	} else {
	allNull = false;	
	}
} while (i < seriesN && allNull == false); // i will be the first "missed" image file after crash
crashStart = i;
} else {
crM = false;
crashStart = 1;	
}
} else {
crashStart = 1;	
}
for (sl = 1; sl <= seriesN; sl += 1){ // begin central loop that loops over images
if (sl >= crashStart){
NOseries = false;
if (skipVW == false){ 
withoutPrior = "no";}
dataImport = false;
if(roiManager("Count") > 0){
		roiManager("Select All");
		roiManager("Delete"); }
do {
if (File.exists(folderVis+"Image-Data_Visualization.txt") == false || NOseries == true){ //if-else Visualization exists
if (skipVW == false) { 
Dialog.create("Warning");
	if (File.exists(folderVis+"Image-Data_Visualization.txt") == false){
	Dialog.addMessage("No image data file from Visualization analysis found.");}
	if (NOseries == true){
	Dialog.addMessage("Image is not represented in image data file.");}
	Dialog.addRadioButtonGroup("Continue without importing information from 'Visualization' analysis", newArray("yes","no"),1,2,withoutPrior);
	Dialog.addString("if 'no': specify folder path of 'Visualization' analysis.", folderVis, 90);
	Dialog.addMessage("The specified folder must contain a file named 'Image-Data_Visualization.txt'.")
	Dialog.addCheckbox("Do not display this warning for subsequent images",skipVW);
Dialog.show();
withoutPrior = Dialog.getRadioButton();
if (withoutPrior == "no"){
folderVis = Dialog.getString();
	if (matches(folderVis,".+/$") == false){
	folderVis = folderVis+"/";	
	}
}
skipVW = Dialog.getCheckbox();
}
} else { // if-else Visualization exists
withoutPrior = "no";}
if (withoutPrior == "yes"){ // generate default parameters (bad = false, channel numbers = channel names, projection type = sum slices)
RfirstZA[sl] = 1;
RlastZA[sl] = sliceA[sl];
if (sliceA[sl] > 1){
VprojectionT = RprojectionA[3];} // default: sum slices
else {
VprojectionT = "mid section";}
badBA[sl] = 0;
if (priorC == 0 || lengthOf(RchannelA) != channelA[sl]){
RchannelA = newArray(channelA[sl]);
RchannelN = ""; //initializer 
	if (priorC == 0) {
	Dialog.create("Channel names");
		Dialog.addMessage("Do you want to enter channel names? This will be applied to all images.");
		for (l = 1; l <= channelA[sl]; l += 1){
		Dialog.addString("Name of channel C"+l, l);}		
	Dialog.show();
	} else if (lengthOf(RchannelA) != channelA[sl-1]){
	Dialog.create("Channel names");
		Dialog.addMessage("The number of channels has changed. Do you want to enter new channel names?\nThis will be applied to all subsequent images.");
		for (l = 1; l <= channelA[sl]; l += 1){
		Dialog.addString("Name of channel C"+l, l);}		
	Dialog.show();	
	} // end if-else loop no prior information about channels (priorC)
for (l = 1; l <= channelA[sl]; l += 1){
RchannelA[l-1] = Dialog.getString();
RchannelA[l-1] = replace(RchannelA[l-1],"-","_");
RchannelN = RchannelN+";"+RchannelA[l-1];}
//RchannelNA[sl] = substring(RchannelN,1,lengthOf(RchannelN));
}
priorC = priorC + 1; // loop counter, to ask for channel names only once
RchannelNA[sl] = substring(RchannelN,1,lengthOf(RchannelN)); 
RRGBbwA[sl] = RRGBbw;
} else { 
visPara = split(File.openAsString(folderVis+"Image-Data_Visualization.txt"),"\n\t"); //array of Visualization file - line after line	
	if (getIndex(visPara,seriesA[sl]) != -1){
	i = getIndex(visPara,seriesA[sl]);
	RchannelNA[sl] = visPara[i+getIndex(visPara,"VchannelNA")]; // array of channel names separated by ';'
	RchannelA = split(RchannelNA[sl],";");
	VprojectionT = visPara[i+getIndex(visPara,"VprojectionTA")];
	RfirstZA[sl] = visPara[i+getIndex(visPara,"VfirstZA")];
	RlastZA[sl] = visPara[i+getIndex(visPara,"VlastZA")];
	badBA[sl] = visPara[i+getIndex(visPara,"VbadA")]; // array of Booleans for image quality bad=true=1, good=false=0
	RRGBbwA[sl] = visPara[i+getIndex(visPara,"VRGBbwA")];
	dataImport = true;
	} else {
	NOseries = true;
	withoutPrior = "no";}
} // end if-else loop to import data from 'Visualization' analysis OR set default parameters
} while (dataImport == false && withoutPrior == "no")
if (sl == crashStart){ // initial values for first looping
RprojectionI = getIndex(RprojectionA, VprojectionT);
} 
do { // start do-while loop for mask generation
if (skipconf == false){
Dialog.create("Generate ROI mask, image "+sl+" / "+seriesN); // Select option to skip this dialog
	Dialog.addChoice("Select channel for ROI mask generation", RchannelA, RchannelA[maskI]); 
	Dialog.addChoice("Projection type for mask generation", RprojectionA, RprojectionA[RprojectionI]); // potentially add Z-borders here (firstZ, lastZ)
	if (skipVW == false && withoutPrior == "no"){
	Dialog.addRadioButtonGroup("Exclude images that have been marked as 'bad quality'", newArray("yes","no"),1,2,skipBad);
	Dialog.addRadioButtonGroup("Use first and last slice as specified in 'Visualization'", newArray("yes","no"),1,2,visBorders);	
	}
Dialog.show();
maskChan = Dialog.getChoice();
RprojectionT = Dialog.getChoice();
if (skipVW == false && withoutPrior == "no"){
skipBad = Dialog.getRadioButton();
visBorders = Dialog.getRadioButton();
} else {
skipBad = "no";
visBorders = "no";	
}
maskI = getIndex(RchannelA, maskChan); // index of channel that is used for mask creation
RprojectionI = getIndex(RprojectionA, RprojectionT); // index of projection type
}
if (skipBad == "no" || badBA[sl] == 0){ // start loop that executes mask generation if quality is good
if (visBorders == "no"){
RfirstZA[sl] = 1;
RlastZA[sl] = sliceA[sl];	
}
if (matches(imageSource, ".*/Analysis/Temp/$") == true){
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
}
rename("Tmp_"+seriesA[sl]);
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape"+
	" feret's integrated median skewness kurtosis area_fraction stack nan redirect=None decimal=3");
if (skipconf == false){
Dialog.create("ROI mask, image "+sl+" / "+seriesN);
		Dialog.addMessage("Please adjust parameters.");
		//Dialog.addNumber("Contrast enhancement, saturation (%)", ces);
		Dialog.addNumber("Background substraction, radius (px)", rbr);
		Dialog.addChoice("Threshold", newArray("none","Default","Huang","Intermodes","IsoData","IJ_IsoData","Li","MaxEntropy","Mean","MinError","Minimum",
		"Moments","Otsu","Percentile","RenyiEntropy","Shanbhag","Triangle","Yen"),thr); // Thresholding of 16bit-images might not work (implemented in ImageJ only experimentally)
		//Dialog.addMessage("Thresholding not recommended for 16bit images (frequent crashes).");
		Dialog.addChoice("Filter for preprocessing", newArray("none", "Variance", "Maximum", "Minimum", "Edges"), pfty);
		Dialog.addNumber("Preprocessing radius", pfra);
		Dialog.addChoice("Filter type", newArray("none","Gaussian Blur", "Median", "Mean", "Variance", "Maximum", "Minimum"), fty);
		Dialog.addNumber("Filter radius", fra);
		Dialog.addChoice("Fill Holes", newArray("no", "before watershed", "after watershed"), fih);
		Dialog.addCheckbox("Skip watershed", skipws);
		Dialog.addString("Particle size ("+unitA[sl]+"^2)", siz);
		Dialog.addString("Circularity of particles (0-1)", cir);
		Dialog.addCheckbox("SlowMo mask generation", slo);
		Dialog.addChoice("Selection colour", ColourA, Rcol);
		Dialog.addCheckbox("show ROIs with labels?", Rlab);
Dialog.show();
//ces = Dialog.getNumber();
rbr = Dialog.getNumber();
thr = Dialog.getChoice();
pfty = Dialog.getChoice();
pfra = Dialog.getNumber();
fty = Dialog.getChoice();
fra = Dialog.getNumber();
fih = Dialog.getChoice();
skipws = Dialog.getCheckbox();
siz = Dialog.getString();
cir = Dialog.getString();
slo = Dialog.getCheckbox(); 
Rcol = Dialog.getChoice();
Rlab = Dialog.getCheckbox();}
if (skipconf == true || slo == false) {setBatchMode(true);}
selectWindow("Tmp_"+seriesA[sl]);
run("Duplicate...", "duplicate range="+RfirstZA[sl]+"-"+RlastZA[sl]);
rename(seriesA[sl]);
selectWindow(seriesA[sl]);
if (channelA[sl] > 1){
run("Split Channels"); // default naming: C1-series, C2-series, ...
selectWindow("C"+(maskI+1)+"-"+seriesA[sl]);}
else {
rename("C"+(maskI+1)+"-"+seriesA[sl]);
}
if (RprojectionT != "mid section"){
run("Z Project...", "projection=["+projectionA[RprojectionI]+"]");}
else {
Zdifference = parseInt(RlastZA[sl]) - parseInt(RfirstZA[sl]);
plane = RfirstZA[sl]+floor(0.5*(Zdifference+1));
run("Duplicate...", "title=MID_C"+(maskI+1)+"-"+seriesA[sl]+" duplicate range="+plane+"-"+plane);
}
selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
if (bitDepth() == 24){ // check if RGB image
if (RskipRGB == false){
Dialog.create("RGB image");
	Dialog.addMessage("You have opened an RGB image - how should the image be handled?");
	//Dialog.addRadioButtonGroup("Colors: ", newArray("split to channels", "convert to greyscale"), 1, 2, RRGBcol); // code stub
	Dialog.addRadioButtonGroup("Structure of interest: ", newArray("dark structure, light background", "light structure, dark background"), 1, 2, RRGBbwA[sl]);
	Dialog.addCheckbox("apply to all?", true)
Dialog.show();
//RRGBcol = Dialog.getRadioButton(); // code stub
RRGBbw = Dialog.getRadioButton();
RskipRGB = Dialog.getCheckbox();
}
if (RRGBcol == "convert to greyscale"){
run("RGB to Luminance"); // enhance this part with the option to split channels and rearrange in greyscale stack, see code stubs above
}
if (RRGBbw == "dark structure, light background"){
run("Invert LUT");}
rename("mask-"+seriesA[sl]);
} else {
RRGBbw = "light structure, dark background";
run("Duplicate...", "title=mask-"+seriesA[sl]);
selectWindow("mask-"+seriesA[sl]);}
//run("Enhance Contrast...", "saturated="+ces);
//if (skipconf == false || slo == true) {wait(1500);}
run("Subtract Background...", "rolling="+rbr);
if (skipconf == false || slo == true) {wait(1500);}
if (thr != "none"){
if (bitDepth() != 32){
run("32-bit"); }
setAutoThreshold(thr+" dark");
if (skipconf == false || slo == true) {wait(1500);}
run("NaN Background");
}
if (pfty != "none" && pfty != "Edges"){
	run(pfty+"...", "radius="+pfra);
	} else if (pfty == "Edges"){
	run("Find Edges");	}
if (skipconf == false || slo == true) {wait(1500);}
if (fty == "Gaussian Blur"){
	radius = "sigma";
} else {
	radius = "radius";
}
if (fty != "none"){
run(fty+"...", radius+"="+fra);}
if (skipconf == false || slo == true) {wait(1500);}
setOption("BlackBackground", false);
run("Make Binary");
if (skipconf == false || slo == true) {wait(1500);}
if (fih == "no" && skipws == false)
	{
		run("Watershed");
	} else if (fih == "before watershed" && skipws == false)
	{
		run("Fill Holes");
		run("Watershed");
	} else if (skipws == false)
	{
		run("Watershed");
		run("Fill Holes");
	} else if (skipws == true && fih != "no")
	{
		run("Fill Holes");
	}
if(roiManager("Count") > 0){
	roiManager("Select All");
	roiManager("Delete"); }
run("Analyze Particles...", "size="+siz+" circularity="+cir+" display exclude add");
selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
if (skipconf == true || slo == false) {setBatchMode("exit and display");}
selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
roiManager("Show None");
roiManager("Show All");
run("Clear Results");
maskChanA[sl] = maskChan;
RprojectionTA[sl] = RprojectionT;
rbrA[sl] = rbr;
thrA[sl] = thr;
//cesA[sl] = ces;
pftyA[sl] = pfty;
pfraA[sl] = pfra;
ftyA[sl] = fty;
fraA[sl] = fra;
fihA[sl] = fih;
sizA[sl] = siz;
cirA[sl] = cir;
skipwsA[sl] = skipws;
RRGBbwA[sl] = RRGBbw;
if (skipconf == false){
do {
selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
roiManager("Set Color", Rcol); 
if (Rlab == true){
roiManager("Show All with labels");
} else {
roiManager("Show All without labels");		
}
Dialog.create("ROI mask, image "+sl+" / "+seriesN);
	Dialog.addMessage("Save this ROI mask?");
	Dialog.addRadioButtonGroup("save?",newArray("yes", "no", "manual curation", "skip image"),1,4,"yes");
	Dialog.addCheckbox("skip manual confirmation for subsequent images", skipconf);
Dialog.show();
sat = Dialog.getRadioButton();
skipconf = Dialog.getCheckbox();
	if (sat == "no") {
	selectWindow("mask-"+seriesA[sl]);
	close();
	selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
	close();
		if(roiManager("Count") > 0){
		roiManager("Select All");
		roiManager("Delete"); }
	} else if (sat == "manual curation"){
	selectWindow(RprojectpreA[RprojectionI]+"_C"+(maskI+1)+"-"+seriesA[sl]);
	roiManager("Show None");
	roiManager("Show All");	
	selectWindow("ROI Manager");
	setTool("freehand");
	waitForUser("Please adjust ROIs for mask (delete, combine, etc).\nUse freehand selection tool to manually define ROIs, add to Manager with 't'.\nConfirm with OK.");
	}
} while (sat == "manual curation");
} else { sat = "yes"; }
} else {
sat = "skip image";	
} // end-else if loop for 'good quality' images
} while (sat == "no")
if (sat == "yes" && roiManager("Count") > 0){
for (roi = 0; roi < roiManager("Count"); roi += 1){ // rename ROIs in ROI Manager
roiManager("Select", roi);
roiManager("Rename", "roi"+(roi+1));}
roiManager("Save", folder+"Analysis/ROIs/"+seriesA[sl]+".zip");
roiCA[sl] = roiManager("Count");
} else {
roiCA[sl] = 0;	
}
roiManager("Show None");
closeRegex(".*[_-]"+seriesA[sl]);
satA[sl] = sat;
} else if (crM == true && sl < crashStart){ 
fileI = getIndex(roiCrash,seriesA[sl]);
RchannelNA[sl] = roiCrash[fileI+getIndex(roiCrash,"RchannelNA")];
RprojectionTA[sl] = roiCrash[fileI+getIndex(roiCrash,"RprojectionTA")];
maskChanA[sl] = roiCrash[fileI+getIndex(roiCrash,"maskChanA")];
rbrA[sl] = roiCrash[fileI+getIndex(roiCrash,"rbrA")];
thrA[sl] = roiCrash[fileI+getIndex(roiCrash,"thrA")];
/*cesA[sl] = roiCrash[fileI+getIndex(roiCrash,"cesA")];*/
pftyA[sl] = roiCrash[fileI+getIndex(roiCrash,"pftyA")];
pfraA[sl] = roiCrash[fileI+getIndex(roiCrash,"pfraA")];
ftyA[sl] = roiCrash[fileI+getIndex(roiCrash,"ftyA")];
fraA[sl] = roiCrash[fileI+getIndex(roiCrash,"fraA")];
fihA[sl] = roiCrash[fileI+getIndex(roiCrash,"fihA")];
sizA[sl] = roiCrash[fileI+getIndex(roiCrash,"sizA")];
cirA[sl] = roiCrash[fileI+getIndex(roiCrash,"cirA")];
skipwsA[sl] = roiCrash[fileI+getIndex(roiCrash,"skipwsA")];
satA[sl] = roiCrash[fileI+getIndex(roiCrash,"satA")];
RfirstZA[sl] = roiCrash[fileI+getIndex(roiCrash,"RfirstZA")];
RlastZA[sl] = roiCrash[fileI+getIndex(roiCrash,"RlastZA")];
roiCA[sl] = roiCrash[fileI+getIndex(roiCrash,"roiCA")];
RRGBbwA[sl] = roiCrash[fileI+getIndex(roiCrash,"RRGBbwA")];
}// end if-else loop for Crash rescue mode
RchannelNA[0] = "channel names";
RprojectionTA[0] = "projection type";
maskChanA[0] = "channel for mask";
rbrA[0] = "Radius Rolling Ball";
thrA[0] = "threshold type";
/*cesA[0] = "contrast enhancement";*/
pftyA[0] = "preprocessing filter";
pfraA[0] = "preprocessing radius";
ftyA[0] = "filter type";
fraA[0] = "filter radius";
fihA[0] = "fill holes";
sizA[0] = "size range";
cirA[0] = "circularity range";
skipwsA[0] = "skip watershed?";
satA[0] = "mask satisfaction";
RfirstZA[0] = "first slice";
RlastZA[0] = "last slice";
roiCA[0] = "# rois";
RRGBbwA[0] = "structure of interest";
Array.show("ROI configuration", seriesA, RchannelNA, RprojectionTA, maskChanA, rbrA, thrA,/*cesA,*/pftyA,pfraA,ftyA,fraA,fihA,sizA,cirA,skipwsA,satA,RfirstZA,RlastZA,roiCA,RRGBbwA);
selectWindow("ROI configuration");
save(folder+"Analysis/ROIs/"+"Configuration.txt");
selectWindow("Configuration.txt");
run("Close");
} // end for loop that loops over images
waitForUser("ROI masks completed", "You have completed the task 'ROI mask generation'.");
} // end if loop for execution of "Roi mask generation" part

/*
 * D) Quantitate fluorescence intensities within ROIs, background quantitation 
 */
if (quantB == true){
	if (roiB == false){
	showMessageWithCancel("ROI quantitation","You cannot perform this task if you have not generated ROI masks for your images in a prior session.");}
QchannelNA = newArray(seriesN+1); // array of channel names separated by ';' for storage
QchannelA = newArray(channelA[0]); // array of channel names for internal processing
QfirstZA = newArray(seriesN+1);
QlastZA = newArray(seriesN+1);
badBA = newArray(seriesN+1);
QsatA = newArray(seriesN+1);
QprojectionTA = newArray(seriesN+1);
QRGBbwA = newArray(seriesN+1);
NOseries = false;
QprojectionA = Array.concat(projectionA,"all slices separately");
QprojectpreA = Array.concat(projectpreA, "SEP");
QprojectionTA[0] = "projection type";
QchannelNA[0] = "channel names";
QfirstZA[0] = "first slice";
QlastZA[0] = "last slice";
badBA[0] = "bad quality?";
QsatA[0] = "mask satisfaction";
QRGBcol = "convert to greyscale";
QRGBbw = "light structure, dark background";
QskipRGB = false;
if (sliceA[1] > 1){
QprojectionI = 3; // default set to SUM SLICES	
} else {
QprojectionI = getIndex(QprojectionA, "all slices separately");	}
Dialog.create("Quantify intensities within ROIs");
	Dialog.addMessage("Please select a Z-projection type to quantify intensities. This will be applied to all images.");
	Dialog.addChoice("Z-projection type", QprojectionA, QprojectionA[QprojectionI]); 
	Dialog.addMessage("Do you want to apply information from 'Visualization' analysis?"); 
	Dialog.addCheckboxGroup(2,1,newArray("exclude 'bad quality' images", "use first and last Z as specified"), newArray(true,true));
Dialog.show();
QprojectionT = Dialog.getChoice();
QprojectionI = getIndex(QprojectionA, QprojectionT);
exBadB = Dialog.getCheckbox();
customZ = Dialog.getCheckbox();
folderRoi = folder+"Analysis/ROIs/";
folderVis = folder+"Analysis/Visualization/";
elseC = 0;
skipFound = false;
crExit = false;
if (crM == true){
while (File.exists(folder+"Analysis/Quant/Parameters.txt") == false){
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified does not contain any folder 'Analysis/Quant' with a 'Parameters.txt' file.\n'Crash-Rescue mode' can only be executed with the default Analysis output structure."+
						" \nPlease specify another folder path.");
	Dialog.addString("folder path", folder, 90);
	Dialog.addCheckbox("Exit crash rescue mode", false);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
crExit = Dialog.getCheckbox();}
if (crExit == false){	
quantCrash = split(File.openAsString(folder+"Analysis/Quant"+"/Parameters.txt"),"\n\t"); //array of Parameters file - line after line
quantColumns = lengthOf(quantCrash)/(seriesN+2); // 2 for first two header lines (variable name + description)
i = 0;
do {
i = i +1;
crashI = getIndex(quantCrash,seriesA[i]);
Nullcount = 0;
loopcount = 0;
for (c = 1; c < quantColumns; c += 1){
	if (quantCrash[crashI+c] == 0){
	Nullcount = Nullcount + 1;}
	loopcount = loopcount + 1;
}
	if (Nullcount == loopcount){
	allNull = true;	
	} else {
	allNull = false;	
	}
} while (i < seriesN && allNull == false); // i will be the first "missed" image file after crash
crashStart = i;
} else {
crM = false;
crashStart = 1;	
}
} else {
crashStart = 1;	
}
for (sl = 1; sl <= seriesN; sl += 1){ // begin central loop that loops over images
if (sl >= crashStart){
QprojectionTA[sl] = QprojectionA[QprojectionI];
if (exBadB == true || customZ == true){
passVisB = File.exists(folderVis);
} else {
passVisB = true;}
if (File.exists(folderRoi) != true || passVisB != true || skipFound == false){
Dialog.create("Info: Image " + seriesNA[sl]);
	if (File.exists(folderRoi) == false){
	Dialog.addMessage("No ROIs found.");
	Dialog.addString("Specify folder path of ROI information.", folderRoi, 90);}
	else {Dialog.addMessage("ROI data found.");}
	if (exBadB == true || customZ == true){
	if (File.exists(folderVis) == false){
	Dialog.addMessage("No 'Visualization' information found.");
	Dialog.addString("Specify folder path where 'Visualization' data are stored.", folderVis, 90);}
	else { Dialog.addMessage("Visualization data found.")}
	}
	if (File.exists(folderRoi) == true || File.exists(folderVis) == true){
	Dialog.addCheckbox("Do not show this message again.",skipFound);}
Dialog.show();
if (File.exists(folderRoi) == false){
folderRoi = Dialog.getString();
if (matches(folderRoi,".+/$") == false){
folderRoi = folderRoi+"/";	
}
}
if (exBadB == true || customZ == true){
if (File.exists(folderVis) == false){
folderVis = Dialog.getString();
if (matches(folderVis,".+/$") == false){
folderVis = folderVis+"/";	
}
}
}
if (File.exists(folderRoi) == true || File.exists(folderVis) == true){
skipFound = Dialog.getCheckbox();}
}
do {
roiPara = split(File.openAsString(folderRoi+"Configuration.txt"),"\n\t"); //array of Roi configuration file - line after line
if (getIndex(roiPara,seriesA[sl]) != -1){ // import information from ROI generation
	igRoi = false;
	i = getIndex(roiPara,seriesA[sl]);
	QsatA[sl] = roiPara[i+getIndex(roiPara,"satA")]; // info if image has been skipped during ROI mask generation, values: "yes" OR "skip image"
	QRGBbwA[sl] = roiPara[i+getIndex(roiPara,"RRGBbwA")];
	if (File.exists(folderRoi+seriesA[sl]+".zip") == false && roiPara[i+getIndex(roiPara,"satA")] == "yes"){
	showMessage("Warning: image "+seriesNA[sl], "Corresponding ROI file not found. Image will be ignored.");
	QsatA[sl] = "no .zip";}
	} else {
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'ROI configuration' file.");
	Dialog.addString("Specify folder path where 'ROI configuration' are stored.", folderRoi, 90);
	Dialog.addCheckbox("Skip image", false);
	Dialog.show();
	folderRoi = Dialog.getString();
	if (matches(folderRoi,".+/$") == false){
	folderRoi = folderRoi+"/";	
	}
	igRoi = Dialog.getCheckbox();
	if (igRoi == true){
	QsatA[sl] = "skip image";}
	}
} while (getIndex(roiPara,seriesA[sl]) == -1 && igRoi == false)
if (exBadB == true || customZ == true){ // if-else loop import Visualization data
do {
visPara = split(File.openAsString(folderVis+"Image-Data_Visualization.txt"),"\n\t"); //array of Visualization image data file - line after line
if (getIndex(visPara,seriesA[sl]) != -1){ // if-else loop image (not) found in Visualization data
	igVis = false;
	i = getIndex(visPara,seriesA[sl]);
	QchannelNA[sl] = visPara[i+getIndex(visPara,"VchannelNA")]; // array of channel names separated by ';'
	QchannelA = split(QchannelNA[sl],";");
		if (customZ == true){
		QfirstZA[sl] = visPara[i+getIndex(visPara,"VfirstZA")];
		QlastZA[sl] = visPara[i+getIndex(visPara,"VlastZA")];
		} else { QfirstZA[sl] = 1;
		QlastZA[sl] = sliceA[sl];}	
		if (exBadB == true){
		badBA[sl] = visPara[i+getIndex(visPara,"VbadA")];
		} else { badBA[sl] = 0;}
	} else { // if-else loop image (not) found in Visualization data
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'Visualization' image data file.");
	Dialog.addString("Specify folder path where 'Visualization' data are stored.", folderVis, 90);
	Dialog.addCheckbox("Ignore 'Visualization' data for this image", false);
	Dialog.show();
	folderVis = Dialog.getString();
	if (matches(folderVis,".+/$") == false){
	folderVis = folderVis+"/";	
	}
	igVis = Dialog.getCheckbox();}
} while (getIndex(visPara,seriesA[sl]) == -1 && igVis == false)
} else { // if-else loop import Visualization data
if (elseC == 0 || lengthOf(QchannelA) != channelA[sl]){
QchannelA = newArray(channelA[sl]);
QchannelN = ""; //initializer 
if (elseC == 0) {
Dialog.create("Channel names");
	Dialog.addMessage("Do you want to enter channel names? This will be applied to all images.");
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addString("Name of channel C"+l, l);}		
Dialog.show();
} else if (lengthOf(QchannelA) != channelA[sl]){
Dialog.create("Channel names");
	Dialog.addMessage("The number of channels has changed. Do you want to enter new channel names?\nThis will be applied to all subsequent images.");
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addString("Name of channel C"+l, l);}		
Dialog.show();	
}
for (l = 1; l <= channelA[sl]; l += 1){
QchannelA[l-1] = Dialog.getString();
QchannelA[l-1] = replace(QchannelA[l-1],"-","_");
QchannelN = QchannelN+";"+QchannelA[l-1];}
}	
QfirstZA[sl] = 1;
QlastZA[sl] = sliceA[sl];
badBA[sl] = 0;
elseC = elseC + 1;	
QchannelNA[sl] = substring(QchannelN,1,lengthOf(QchannelN)); 
} // end if-else loop for import Visualization data
setBatchMode(true);
if (badBA[sl] == 0 && QsatA[sl] == "yes"){ // begin if loop that imports ROIs into manager IF Roi file exists
//MAIN QUANTITATION PART
if(roiManager("Count") > 0){
		roiManager("Select All");
		roiManager("Delete"); }
roiManager("Open", folderRoi+seriesA[sl]+".zip");
if (matches(imageSource, ".*/Analysis/Temp/$") == true){
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
}
rename("Tmp_"+seriesA[sl]);
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape"+
	" feret's integrated median skewness kurtosis area_fraction stack nan redirect=None decimal=3");
run("Duplicate...", "duplicate range="+QfirstZA[sl]+"-"+QlastZA[sl]);
rename(seriesA[sl]);
selectWindow(seriesA[sl]);
if (bitDepth() == 24){ // check if RGB image
if (QskipRGB == false){
Dialog.create("RGB image");
	Dialog.addMessage("You have opened an RGB image - how should the image be handled?");
	//Dialog.addRadioButtonGroup("Colors: ", newArray("split to channels", "convert to greyscale"), 1, 2, RRGBcol); // code stub
	Dialog.addRadioButtonGroup("Structure of interest: ", newArray("dark structure, light background", "light structure, dark background"), 1, 2, QRGBbwA[sl]);
	Dialog.addCheckbox("apply to all?", QskipRGB)
Dialog.show();
//RRGBcol = Dialog.getRadioButton(); // code stub
QRGBbw = Dialog.getRadioButton();
QskipRGB = Dialog.getCheckbox();
}
if (QRGBcol == "convert to greyscale"){
run("RGB to Luminance"); // enhance this part with the option to split channels and rearrange in greyscale stack, see code stubs above
}
if (QRGBbw == "dark structure, light background"){
run("Invert LUT");}
QRGBbwA[sl] = QRGBbw;
}
if (channelA[sl] > 1) {
run("Split Channels");// default naming: C1-series, C2-series, ...
} else {
rename("C1-"+seriesA[sl]);	
}
if (QprojectionT != "all slices separately"){
for (l = 1; l <= channelA[sl]; l += 1){
selectWindow("C"+l+"-"+seriesA[sl]);
run("Z Project...", "projection=["+QprojectionA[QprojectionI]+"]");
selectWindow(QprojectpreA[QprojectionI]+"_C"+l+"-"+seriesA[sl]);
for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select", roi);
	roiManager("Measure");}
saveAs("Results", folder+"Analysis/Quant/"+QchannelA[l-1]+"-"+seriesA[sl]+"_"+QprojectpreA[QprojectionI]+".txt");
run("Clear Results");
roiManager("Show None");
selectWindow(QprojectpreA[QprojectionI]+"_C"+l+"-"+seriesA[sl]);
run("Select All");
run("Measure");
saveAs("Results", folder+"Analysis/Quant/"+QchannelA[l-1]+"-"+seriesA[sl]+"_"+QprojectpreA[QprojectionI]+"_BG.txt"); // Background file
run("Clear Results");
} // end for loop that loops through channels
} else {
for (l = 1; l <= channelA[sl]; l += 1){
selectWindow("C"+l+"-"+seriesA[sl]);
rename(QprojectpreA[QprojectionI]+"_C"+l+"-"+seriesA[sl]);
	for (slice = 1; slice <= QlastZA[sl]-QfirstZA[sl]+1; slice += 1){
	setSlice(slice);
	for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select", roi);
	roiManager("Measure");}
	}	
saveAs("Results", folder+"Analysis/Quant/"+QchannelA[l-1]+"-"+seriesA[sl]+"_"+QprojectpreA[QprojectionI]+".txt");
run("Clear Results");
selectWindow(QprojectpreA[QprojectionI]+"_C"+l+"-"+seriesA[sl]);
	for (slice = 1; slice <= QlastZA[sl]-QfirstZA[sl]+1; slice += 1){
	setSlice(slice);
	run("Select All");
	run("Measure");}
saveAs("Results", folder+"Analysis/Quant/"+QchannelA[l-1]+"-"+seriesA[sl]+"_"+QprojectpreA[QprojectionI]+"_BG.txt"); // Background file
run("Clear Results");
roiManager("Show None");
} // end for loop that loops through channels
} // end if-else loop for projections
} // end if loop that imports ROIs into manager
} else if (crM == true && sl < crashStart){
fileI = getIndex(quantCrash,seriesA[sl]);
QprojectionTA[sl] = quantCrash[fileI+getIndex(quantCrash,"QprojectionTA")];
QchannelNA[sl] = quantCrash[fileI+getIndex(quantCrash,"QchannelNA")];
QfirstZA[sl] = quantCrash[fileI+getIndex(quantCrash,"QfirstZA")];
QlastZA[sl] = quantCrash[fileI+getIndex(quantCrash,"QlastZA")];
badBA[sl] = quantCrash[fileI+getIndex(quantCrash,"badBA")];
QsatA[sl] = quantCrash[fileI+getIndex(quantCrash,"QsatA")];
QRGBbwA[sl] = quantCrash[fileI+getIndex(quantCrash,"QRGBbwA")];
} // end if loop execution of 'crash-rescue-mode'
Array.show("ROI quantitation", seriesA, QprojectionTA,QchannelNA,QfirstZA,QlastZA,badBA,QsatA,QRGBbwA);
selectWindow("ROI quantitation");
save(folder+"Analysis/Quant/"+"Parameters.txt");
selectWindow("Parameters.txt");
run("Close");
closeRegex(".*[_-]"+seriesA[sl]);
} // end central for loop that loops over images
setBatchMode(false);
waitForUser("Quantitation completed", "You have completed the task 'ROI quantitation'.");
} // end if loop for execution of 'Quantitation' part

/*
 * E) Foci detection
 */
if (fociB == true){
overlapYN = "yes";
exBadB = true;
customZ = true;
skipFound = false;
FskipFirst = false;
FchannelNA = newArray(seriesN+1); // array of channel names separated by ';' for storage
FchannelA = newArray(channelA[0]); // array of channel names for internal processing
FfirstZA = newArray(seriesN+1);
FlastZA = newArray(seriesN+1);
badBA = newArray(seriesN+1);
FsatA = newArray(seriesN+1);
maximaIA = newArray(seriesN+1);
noiseA = newArray(seriesN+1);
circradA = newArray(seriesN+1);
satFA = newArray(seriesN+1);
FprojectionTA = newArray(seriesN+1);
FprojectionTA[0] = "projection type";
FchannelNA[0] = "channel names";
FfirstZA[0] = "first slice";
FlastZA[0] = "last slice";
badBA[0] = "bad quality?";
FsatA[0] = "roi mask satisfaction";
maximaIA[0] = "index of channel for foci detection";
noiseA[0] = "noise level for foci detection";
circradA[0] = "radius of selection circle";
satFA[0] = "foci mask satisfaction";
FprojectionA = Array.concat(projectionA,"mid section");
FprojectpreA = Array.concat(projectpreA, "MID");
folderRoi = folder+"/Analysis/ROIs/";
folderVis = folder+"/Analysis/Visualization/";
elseC = 0;
FchannelI = 0;
noise = 10;
circrad = 3;
skipconfF = false;
NOfociYN = "yes";
FRGBcol = "convert to greyscale";
FRGBbw = "light structure, dark background";
FskipRGB = false;
if (crM == true){
while (File.exists(folder+"/Analysis/Foci/Info.txt") == false){
Dialog.create("Warning");
	Dialog.addMessage("The folder path you specified does not contain any folder 'Analysis/Foci' with a 'Info.txt' file.\n'Crash-Rescue mode' can only be executed with the default Analysis output structure."+
						" \nPlease specify another folder path.");
	Dialog.addString("folder path", folder, 90);
	Dialog.addCheckbox("Exit crash rescue mode", false);
Dialog.show();
folder = Dialog.getString();
if (matches(folder,".+/$") == false){
folder = folder+"/";	
}
crExit = Dialog.getCheckbox();}
if (crExit == false){	
fociCrash = split(File.openAsString(folder+"Analysis/Foci"+"/Info.txt"),"\n\t"); //array of Visualization file - line after line
fociColumns = lengthOf(fociCrash)/(seriesN+2); // 2 for first two header lines (variable name + description)
i = 0;
do {
i = i +1;
crashI = getIndex(fociCrash,seriesA[i]);
Nullcount = 0;
loopcount = 0;
for (c = 1; c < fociColumns; c += 1){
	if (fociCrash[crashI+c] == 0){
	Nullcount = Nullcount + 1;}
	loopcount = loopcount + 1;
}
	if (Nullcount == loopcount){
	allNull = true;	
	} else {
	allNull = false;	
	}
} while (i < seriesN && allNull == false); // i will be the first "missed" image file after crash
crashStart = i;
} else {
crM = false;
crashStart = 1;	
}
} else {
crashStart = 1;	
}
for (sl = 1; sl <= seriesN; sl += 1){ // begin central for loop that loops over images
if (sl >= crashStart){
	if(roiManager("Count") > 0){
	roiManager("Deselect");
	roiManager("Delete");}
	run("Clear Results");
if (FskipFirst == false){
Dialog.create("Import previous data?");
	Dialog.addRadioButtonGroup("Overlap foci with ROIs", newArray("yes","no"),1,2,overlapYN);
	Dialog.addMessage("Do you want to apply information from 'Visualization' analysis?"); 
	Dialog.addCheckboxGroup(3,1,newArray("exclude 'bad quality' images", "use first and last Z as specified"), newArray(exBadB,customZ));
	Dialog.addCheckbox("apply to all",FskipFirst);
Dialog.show();
overlapYN = Dialog.getRadioButton();
exBadB = Dialog.getCheckbox();
customZ = Dialog.getCheckbox();
FskipFirst = Dialog.getCheckbox();
}
if (overlapYN == "yes" || exBadB == true || customZ == true){
if (File.exists(folderRoi) != true || File.exists(folderVis) != true || skipFound == false){
Dialog.create("Info: Image "+seriesNA[sl]);
	if (overlapYN == "yes"){
	if (File.exists(folderRoi) == false){
	Dialog.addMessage("No ROIs found.");
	Dialog.addString("Specify folder path of ROI information.", folderRoi, 90);}
	else {Dialog.addMessage("ROI data found.");}
	}
	if (exBadB == true || customZ == true){
	if (File.exists(folderVis) == false){
	Dialog.addMessage("No 'Visualization' information found.");
	Dialog.addString("Specify folder path where 'Visualization' data are stored.", folderVis, 90);}
	else { Dialog.addMessage("Visualization data found.")}
	}
	if (File.exists(folderRoi) == true && File.exists(folderVis) == true){ /// change this part to skip confirmation if Vis is ignored
	Dialog.addCheckbox("Do not show this message again.",skipFound);}
Dialog.show();
if (File.exists(folderRoi) == false){
folderRoi = Dialog.getString();
	if (matches(folderRoi,".+/$") == false){
	folderRoi = folderRoi+"/";	
	}
}
if (exBadB == true || customZ == true){
if (File.exists(folderVis) == false){
folderVis = Dialog.getString();
if (matches(folderVis,".+/$") == false){
folderVis = folderVis+"/";	
}
}
}
if (File.exists(folderRoi) == true && File.exists(folderVis) == true){
skipFound = Dialog.getCheckbox();}
} // end if loop for existence of Roi and Vis data
} // end if loop for import of Roi and Vis data
if (overlapYN == "yes"){
do {
roiPara = split(File.openAsString(folderRoi+"Configuration.txt"),"\n\t"); //array of Roi configuration file - line after line
if (getIndex(roiPara,seriesA[sl]) != -1){ // import information from ROI generation
	igRoi = false;
	i = getIndex(roiPara,seriesA[sl]);
	FsatA[sl] = roiPara[i+getIndex(roiPara,"satA")]; // info if image has been skipped during ROI mask generation, values: "yes" OR "skip image"
	FprojectionI = getIndex(FprojectionA,roiPara[i+getIndex(roiPara,"RprojectionTA")]);
	} else {
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'ROI configuration' file.");
	Dialog.addString("Specify folder path where 'ROI configuration' are stored.", folderVis, 90);
	Dialog.addCheckbox("Skip image", false);
	Dialog.show();
	folderRoi = Dialog.getString();
	if (matches(folderRoi,".+/$") == false){
	folderRoi = folderRoi+"/";	
	}
	igRoi = Dialog.getCheckbox();
	if (igRoi == true){
	FsatA[sl] = "skip image";}
	}
} while (getIndex(roiPara,seriesA[sl]) == -1 && igRoi == false)
} else {
FsatA[sl] = "yes";	
}
if (exBadB == true || customZ == true){ // if-else loop import Visualization data
do {
visPara = split(File.openAsString(folderVis+"Image-Data_Visualization.txt"),"\n\t"); //array of Visualization image data file - line after line
if (getIndex(visPara,seriesA[sl]) != -1){ // if-else loop image (not) found in Visualization data
	FchannelA = newArray(channelA[sl]);
	igVis = false;
	i = getIndex(visPara,seriesA[sl]);
	FchannelNA[sl] = visPara[i+getIndex(visPara,"VchannelNA")]; // array of channel names separated by ';'
	FchannelA = split(FchannelNA[sl],";");
	if (overlapYN == "no"){
	FprojectionI = getIndex(FprojectionA,visPara[i+getIndex(visPara,"VprojectionTA")]);}
		if (customZ == true){
		FfirstZA[sl] = visPara[i+getIndex(visPara,"VfirstZA")];
		FlastZA[sl] = visPara[i+getIndex(visPara,"VlastZA")];} else {
		FfirstZA[sl] = 1;
		FlastZA[sl] = sliceA[sl];}	
		if (exBadB == true){
		badBA[sl] = visPara[i+getIndex(visPara,"VbadA")];} else {
		badBA[sl] = 0;}
	} else { // if-else loop image (not) found in Visualization data
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'Visualization' image data file.");
	Dialog.addString("Specify folder path where 'Visualization' data are stored.", folderVis, 90);
	Dialog.addCheckbox("Ignore 'Visualization' data for this image", false);
	Dialog.show();
	folderVis = Dialog.getString();
	if (matches(folderVis,".+/$") == false){
	folderVis = folderVis+"/";	
	}
	igVis = Dialog.getCheckbox();}
} while (getIndex(visPara,seriesA[sl]) == -1 && igVis == false)
} else { // if-else loop import Visualization data
if (elseC == 0 || lengthOf(FchannelA) != channelA[sl]){
FchannelN = ""; //initializer 
FchannelA = newArray(channelA[sl]);
if (elseC == 0) {
Dialog.create("Channel names");
	Dialog.addMessage("Do you want to enter channel names? This will be applied to all images.");
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addString("Name of channel C"+l, l);}		
Dialog.show();
} else if (lengthOf(FchannelA) != channelA[sl]){
Dialog.create("Channel names");
	Dialog.addMessage("The number of channels has changed. Do you want to enter new channel names?\nThis will be applied to all subsequent images.");
	for (l = 1; l <= channelA[sl]; l += 1){
	Dialog.addString("Name of channel C"+l, l);}		
Dialog.show();	
}
for (l = 1; l <= channelA[sl]; l += 1){
FchannelA[l-1] = Dialog.getString();
FchannelA[l-1] = replace(FchannelA[l-1],"-","_");
FchannelN = FchannelN+";"+FchannelA[l-1];
}
}	
FfirstZA[sl] = 1;
FlastZA[sl] = sliceA[sl];
badBA[sl] = 0;
if (elseC == 0 && overlapYN == "no"){
if (sliceA[sl] > 1){
FprojectionI = getIndex(FprojectionA,"Sum Slices");}
else {
FprojectionI = getIndex(FprojectionA,"mid section");}		
}
elseC = elseC + 1;
FchannelNA[sl] = substring(FchannelN,1,lengthOf(FchannelN));	
} // end if-else loop for import Visualization data
if (badBA[sl] == 0 && FsatA[sl] == "yes"){ // execution if images are 'good quality' or no Vis/Roi info has been imported
dwC = 0;
do { // start do-while loop for FindMaxima
if(roiManager("Count") > 0){
	roiManager("Select All");
	roiManager("Delete"); }
	run("Clear Results");
if (skipconfF == false){
Dialog.create("Settings for foci detection, image "+sl+" / "+seriesN);
	Dialog.addChoice("Please select a channel for foci detection", FchannelA, FchannelA[FchannelI]);
	Dialog.addMessage("Please select a Z-projection type to detect foci on.");
	Dialog.addChoice("Z-projection type", FprojectionA, FprojectionA[FprojectionI]); 
	Dialog.addNumber("Noise tolerance of 'Find Maxima': ", noise); 
	Dialog.addNumber("Maxima: circle radius [px]: ", circrad);// suggestion: Option to combine overlapping foci
	// suggestion: include option to choose foci selection colour
Dialog.show();
FchannelT = Dialog.getChoice();
FprojectionT = Dialog.getChoice();
noise = Dialog.getNumber();
circrad = Dialog.getNumber();
FchannelI = getIndex(FchannelA,FchannelT);
FprojectionI = getIndex(FprojectionA,FprojectionT);
}
setBatchMode(true);
if (matches(imageSource, ".*/Analysis/Temp/$") == true){
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
}
rename("Tmp_"+seriesA[sl]);
if(roiManager("Count") > 0){
roiManager("Deselect");	}
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Duplicate...", "duplicate range="+FfirstZA[sl]+"-"+FlastZA[sl]);
rename(seriesA[sl]);
selectWindow(seriesA[sl]);
if (bitDepth() == 24){ // check if RGB image
if (FskipRGB == false){
Dialog.create("RGB image");
	Dialog.addMessage("You have opened an RGB image - how should the image be handled?");
	//Dialog.addRadioButtonGroup("Colors: ", newArray("split to channels", "convert to greyscale"), 1, 2, RRGBcol); // code stub
	Dialog.addRadioButtonGroup("Structure of interest: ", newArray("dark structure, light background", "light structure, dark background"), 1, 2, FRGBbw);
	Dialog.addCheckbox("apply to all?", FskipRGB)
Dialog.show();
//RRGBcol = Dialog.getRadioButton(); // codes stub
FRGBbw = Dialog.getRadioButton();
FskipRGB = Dialog.getCheckbox();
}
if (QRGBcol == "convert to greyscale"){
run("RGB to Luminance"); // enhance this part with the option to split channels and rearrange in greyscale stack, see code stubs
}
if (QRGBbw == "dark structure, light background"){
run("Invert LUT");}
} // end if loop RGB
if (channelA[sl] > 1) {
run("Split Channels");// default naming: C1-series, C2-series, ...
} else {
rename("C1-"+seriesA[sl]);	
}
selectWindow("C"+(FchannelI+1)+"-"+seriesA[sl]);
if (FprojectionT != "mid section"){
run("Z Project...", "projection=["+projectionA[FprojectionI]+"]");}
else {
Zdifference = parseInt(FlastZA[sl]) - parseInt(FfirstZA[sl]);
plane = FfirstZA[sl]+floor((Zdifference+1)*0.5);
run("Duplicate...", "title=MID_C"+(FchannelI+1)+"-"+seriesA[sl]+" duplicate range="+plane+"-"+plane);
}
selectWindow(FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]);
if (skipconfF == false){
setBatchMode("exit and display");} 
run("Find Maxima...", "noise="+noise+" output=List exclude"); 
maximaI = getValue("results.count");
maxNameA = newArray(maximaI);
maximaXA = newArray(maximaI);
maximaYA = newArray(maximaI);
for (max = 0; max < maximaI; max += 1){
maximaXA[max] = getResult("X",max);
maximaYA[max] = getResult("Y",max);}
for (max = 0; max < maximaI; max += 1){
makeOval(maximaXA[max]-circrad, maximaYA[max]-circrad, 2*circrad, 2*circrad);
roiManager("Add");}
for (max = 0; max < roiManager("Count"); max += 1){ // rename ROIs in ROI Manager
roiManager("Select", max);
roiManager("Rename", "max"+(max+1));
maxNameA[max] = "max"+(max+1);} 
run("Clear Results"); 
do { // do-while loop foci mask confirmation
selectWindow(FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]); // NEW
if(roiManager("Count") > 0){
roiManager("Deselect");	}
roiManager("Set Color", "magenta");
roiManager("Show None"); 
roiManager("Show All without labels"); 
if (skipconfF == false){ 
Dialog.create("Foci");
	Dialog.addMessage("Proceed with these foci? Image: "+sl+" / "+seriesN);
	Dialog.addRadioButtonGroup("proceed?", newArray("yes", "adjust visual","manual curation", "no", "skip image"),1,4,"yes");
	Dialog.addCheckbox("skip manual confirmation for subsequent images", skipconfF);
Dialog.show();
satF = Dialog.getRadioButton();
skipconfF = Dialog.getCheckbox();
} else {satF = "yes";}
/*suggestion: in this if loop: include sorting foci by XY instead of intensity? --> roiManager("Sort") 
 * --> careful not to mismatch maxima with other features (order of array!)
 */
if (satF == "adjust visual"){ 
selectWindow(FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]);
run("Duplicate...", "title=Copy-"+FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]+" duplicate");
selectWindow("Copy-"+FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]);
roiManager("Set Color", "magenta");
roiManager("Show All without labels");
selectWindow("ROI Manager");
waitForUser("Adjust visual", "Adjust brightness/contrast with 'Shift+C' or hide maxima in ROI Manager \n(deactivate 'Show All'). Confirm with OK.");	
} else if (satF == "manual curation"){
selectWindow(FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]);
selectWindow("ROI Manager");
if(roiManager("Count") > 0){
roiManager("Deselect");	}
roiManager("Set Color", "magenta");
roiManager("Show All without labels");
setTool("multipoint");
waitForUser("Manual curation", "Please delete unwanted foci from ROI Manger and/or manually select foci" 
+ "\nwith the 'Multipoint' tool (add to Manager with 't').\nConfirm with OK after you are satisfied with the foci selection.");
run("Clear Results"); 
if (roiManager("Count") > 0){
for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select",roi);
	roiManager("Measure");} // retrieve locations of user-selected rois
maximaI = getValue("results.count");
maxNameA = newArray(maximaI); 
maximaXA = newArray(maximaI);
maximaYA = newArray(maximaI);
for (max = 0; max < maximaI; max += 1){ // needs to be adjusted for pixel size here 
maximaXA[max] = getResult("X",max)/XsizeA[sl];
maximaYA[max] = getResult("Y",max)/YsizeA[sl];}
roiManager("Select All");
roiManager("Delete");
for (max = 0; max < maximaI; max += 1){ // make oval selection of user-selection rois
makeOval(maximaXA[max]-circrad, maximaYA[max]-circrad, 2*circrad, 2*circrad);
roiManager("Add");} 
for (max = 0; max < roiManager("Count"); max += 1){ // rename ROIs in ROI Manager
roiManager("Select", max);
roiManager("Rename", "max"+(max+1));
maxNameA[max] = "max"+(max+1);} 
run("Clear Results");
}
}
} while (satF == "adjust visual" || satF == "manual curation");
closeRegex(".*[_-]"+seriesA[sl]);
dwC = dwC + 1;
} while (satF == "no"); // end do-while loop for FindMaxima
run("Clear Results");
//after foci confirmation, save ROI mask, remeasure foci and write output arrays
if (satF != "skip image"){
if (matches(imageSource, ".*/Analysis/Temp/$") == true){ 
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
} 
rename("Tmp_"+seriesA[sl]);
if(roiManager("Count") > 0){
roiManager("Deselect");	}
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
run("Duplicate...", "duplicate range="+FfirstZA[sl]+"-"+FlastZA[sl]);
rename(seriesA[sl]);
selectWindow(seriesA[sl]);
run("Split Channels"); // default naming: C1-series, C2-series, ...
selectWindow("C"+(FchannelI+1)+"-"+seriesA[sl]);
if (FprojectionT != "mid section"){
run("Z Project...", "projection=["+projectionA[FprojectionI]+"]");}
else {
Zdifference = parseInt(FlastZA[sl]) - parseInt(FfirstZA[sl]);
plane = FfirstZA[sl]+floor((Zdifference+1)*0.5);
run("Duplicate...", "title=MID_C"+(FchannelI+1)+"-"+seriesA[sl]+" duplicate range="+plane+"-"+plane);
}
selectWindow(FprojectpreA[FprojectionI]+"_C"+(FchannelI+1)+"-"+seriesA[sl]); 
run("Set Scale...", "distance=1 known="+XsizeA[sl]+" pixel=1 unit="+unitA[sl]);
if (roiManager("Count") != 0){ // measure mean, max, etc.
for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select",roi);
	roiManager("Measure");}
NOfociYN = "no";
roiManager("Save", folder+"Analysis/Foci/"+seriesA[sl]+".zip");
} else if (roiManager("Count") == 0) {
Dialog.create("No foci detected");
	Dialog.addMessage("There have been no foci detected in this image. Do you want to store this information?");
	Dialog.addRadioButtonGroup("save 'no foci'", newArray("yes","no"),1,2, NOfociYN);
Dialog.show();
NOfociYN = Dialog.getRadioButton();
	if (NOfociYN == "yes"){
	maximaI = 1;
	maxNameA = newArray(maximaI);
	maximaXA = newArray(maximaI);
	maximaYA = newArray(maximaI);}	
}
meanA = newArray(maximaI);
stddevA = newArray(maximaI);
maxIntA = newArray(maximaI);
medianA = newArray(maximaI);
intdenA = newArray(maximaI);
if (roiManager("Count") != 0){
	for (max = 0; max < maximaI; max += 1){
		meanA[max] = getResult("Mean",max);
		maxIntA[max] = getResult("Max", max);
		stddevA[max] = getResult("StdDev",max); 
		medianA[max] = getResult("Median",max);
		intdenA[max] = getResult("IntDen",max);}
} else if (NOfociYN == "yes"){
maxNameA[0] = 0; // new
maximaXA[0] = 0;
maximaYA[0] = 0;
meanA[0] = 0;
maxIntA[0] = 0;
stddevA[0] = 0;
medianA[0] = 0;
intdenA[0] = 0;
maximaI = 0;
} // end 1st if-else loop number of foci
if (roiManager("Count") > 0) {
roiManager("Select All");
roiManager("Delete");}
run("Clear Results");
if (overlapYN == "yes" && NOfociYN == "no"){
roiManager("Open", folderRoi+seriesA[sl]+".zip");
ROIsI = roiManager("Count");
maximaNA = newArray(maximaI);
	for (max = 0; max < maximaI; max += 1){
		roi = 1;
		do {
		roiManager("Select",roi-1);
			if (Roi.contains(maximaXA[max],maximaYA[max]) == 1){
				maximaNA[max] = "roi"+roi;
			} else if (roi == ROIsI) { maximaNA[max] = "out";}
		roi = roi +1;
		} while (roi <= ROIsI && Roi.contains(maximaXA[max],maximaYA[max]) != 1)
	}
} else if (overlapYN == "yes" && NOfociYN == "yes"){
maximaNA = newArray(1);
maximaNA[0] = "no foci";
} // end if-else loop assignment of foci to ROIs
if (roiManager("Count") > 0) {
roiManager("Deselect");
roiManager("Delete");}
run("Clear Results");
maxNameA = Array.concat("Foci ID",maxNameA);
maximaXA = Array.concat("X coordinate",maximaXA);
maximaYA = Array.concat("Y coordinate", maximaYA);
meanA = Array.concat("mean focus intensity", meanA);
maxIntA = Array.concat("max. focus intensity", maxIntA);
stddevA = Array.concat("focus intensity std deviation", stddevA);
medianA = Array.concat("median focus intensity", medianA);
intdenA = Array.concat("focus integrated density", intdenA);
if (overlapYN == "no"){
Array.show("Maxima-"+seriesA[sl], maxNameA, maximaXA, maximaYA, meanA, maxIntA, stddevA, medianA, intdenA); // include maxima names/numbers
} else {
maximaNA = Array.concat("associated ROI",maximaNA);
Array.show("Maxima-"+seriesA[sl], maxNameA, maximaNA, maximaXA, maximaYA, meanA, maxIntA, stddevA, medianA, intdenA);}
selectWindow("Maxima-"+seriesA[sl]);
save(folder+"Analysis/Foci/"+"Maxima-"+seriesA[sl]+".txt");
selectWindow("Maxima-"+seriesA[sl]+".txt");
run("Close");
} else {
maximaI = 0;}// end if-loop for non 'skip image' pictures
satFA[sl] = satF; // satFA can have 2 values "yes", "skip image"
maximaIA[sl] = maximaI;
noiseA[sl] = noise;
circradA[sl] = circrad;
} else {
satFA[sl] = "skip image";
}// end if-loop for execution of 'good quality' images
closeRegex(".*[_-]"+seriesA[sl]);
} else if (crM == true && sl < crashStart){
fileI = getIndex(fociCrash,seriesA[sl]);
FprojectionTA[sl] = fociCrash[fileI+getIndex(fociCrash,"FprojectionTA")];
FchannelNA[sl] = fociCrash[fileI+getIndex(fociCrash,"FchannelNA")];
FfirstZA[sl] = fociCrash[fileI+getIndex(fociCrash,"FfirstZA")];
FlastZA[sl] = fociCrash[fileI+getIndex(fociCrash,"FlastZA")];
badBA[sl] = fociCrash[fileI+getIndex(fociCrash,"badBA")];
FsatA[sl] = fociCrash[fileI+getIndex(fociCrash,"FsatA")];
maximaIA[sl] = fociCrash[fileI+getIndex(fociCrash,"maximaIA")];
noiseA[sl] = fociCrash[fileI+getIndex(fociCrash,"noiseA")]; 
circradA[sl] = fociCrash[fileI+getIndex(fociCrash,"circradA")];
satFA[sl] = fociCrash[fileI+getIndex(fociCrash,"satFA")];
} // end if loop execution of 'crash-rescue-mode'
Array.show("Foci detection", seriesA, FprojectionTA,FchannelNA,FfirstZA,FlastZA,badBA,FsatA,maximaIA,noiseA,circradA,satFA);
selectWindow("Foci detection");
save(folder+"Analysis/Foci/"+"Info.txt");
selectWindow("Info.txt");
run("Close");
} // end central for loop that loops over images
waitForUser("Foci detection completed", "You have completed the task 'Foci detection'.");
} // end if loop for execution of 'Foci detection part'

/*
 * F) ROI inspection: open ROIs (ROI and foci in different colours, open annotation window, include option to work on projections)
 */
if (inspB == true){
skipFound = false;
hideDia = true;
folderRoi = folder+"Analysis/ROIs/";
folderFoci = folder+"Analysis/Foci/";
skipFoci = false; // set to true to omit foci annotation (not really meaningful)
skipRois = false;
IprojectionA = Array.concat(projectionA, "keep stack");
IprojectpreA = Array.concat(projectpreA, "STK");
//IprojectionT = IprojectionA[3]; // new: defined within loop dependent on channel number
IcustomMan = "Missed Rois - Num;Image Quality - Str";
roiAnnot = "Apoptotic - Str;Inclusion - Num";
fociAnnot = "Size - Num;Remark - Str";
IsplitB = false;
Isave = true;
IsatA = newArray(seriesN+1);
IsatA[0] = "satisfaction ROIs";
IsatFA = newArray(seriesN+1);
IsatFA[0] = "satisfaction foci";
IfirstZA = newArray(seriesN+1);
IlastZA = newArray(seriesN+1);
IroiCA = newArray(seriesN+1); //NEW 4-1-0
IfociCA = newArray(seriesN+1); //NEW 4-1-0
for (sl = 1; sl <= seriesN; sl += 1){ // begin central for loop that loops over images
roiSelect = "3,5,7-12";
fociSelect = "20-35,37";
if(roiManager("Count") > 0){
roiManager("Select All");
roiManager("Delete"); }
if (File.exists(folderRoi) != true || File.exists(folderFoci) != true || skipFound == false){
Dialog.create("Info: Image "+seriesNA[sl]);
	if (File.exists(folderRoi) == false){
	Dialog.addMessage("No ROIs found.");
	Dialog.addString("Specify folder path of ROI information.", folderRoi, 90);}
	else {Dialog.addMessage("ROI data found.");}
	if (File.exists(folderFoci) == false){
	Dialog.addMessage("No 'Foci' files found.");
	Dialog.addString("Specify folder path where 'Foci' data are stored.", folderFoci, 90);}
	else { Dialog.addMessage("Foci data found.")}
	if (File.exists(folderRoi) == true && File.exists(folderFoci) == true){
	Dialog.addCheckbox("Do not show this message again.",skipFound);}
	Dialog.addCheckbox("Do not analyze ROIs",skipRois);
	Dialog.addCheckbox("Do not analyze foci",skipFoci);
Dialog.show();
if (File.exists(folderRoi) == true && File.exists(folderFoci) == true){
skipFound = Dialog.getCheckbox();}
if (File.exists(folderRoi) == false){
folderRoi = Dialog.getString();
if (matches(folderRoi,".+/$") == false){
folderRoi = folderRoi+"/";	
}
}
if (File.exists(folderFoci) == false){
folderFoci = Dialog.getString();
if (matches(folderFoci,".+/$") == false){
folderFoci = folderFoci+"/";	
}}
skipRois = Dialog.getCheckbox();
skipFoci = Dialog.getCheckbox();
} // end if loop for existence of Roi and Foci data
if (skipRois == false){
do {
roiPara = split(File.openAsString(folderRoi+"/Configuration.txt"),"\n\t"); //array of Roi configuration file - line after line
if (getIndex(roiPara,seriesA[sl]) != -1){ // import information from ROI generation
	igRoi = false;
	i = getIndex(roiPara,seriesA[sl]);
	IsatA[sl] = roiPara[i+getIndex(roiPara,"satA")]; // info if image has been skipped during ROI mask generation, values: "yes" OR "skip image"
	IfirstZA[sl] = roiPara[i+getIndex(roiPara,"RfirstZA")]; 
	IlastZA[sl] = roiPara[i+getIndex(roiPara,"RlastZA")];
	IroiCA[sl] = roiPara[i+getIndex(roiPara,"roiCA")]; // NEW 4-1-0
	} else {
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'ROI configuration' file.");
	Dialog.addString("Specify folder path where 'ROI configuration' are stored.", folderRoi, 90);
	Dialog.addCheckbox("Skip image", false);
	Dialog.show();
	folderRoi = Dialog.getString();
	if (matches(folderRoi,".+/$") == false){
	folderRoi = folderRoi+"/";	
	}
	igRoi = Dialog.getCheckbox();
	if (igRoi == true){
	IsatA[sl] = "skip image";}
	}
} while (getIndex(roiPara,seriesA[sl]) == -1 && igRoi == false)
} else { IsatA[sl] = "skip image";}
if (skipFoci == false){
do {
fociPara = split(File.openAsString(folderFoci+"Info.txt"),"\n\t"); //array of Foci information file - line after line
if (getIndex(fociPara,seriesA[sl]) != -1){ // import information from ROI generation
	igFoci = false;
	i = getIndex(fociPara,seriesA[sl]);
	IsatFA[sl] = fociPara[i+getIndex(fociPara,"satFA")]; 
	IfociCA[sl] = fociPara[i+getIndex(fociPara,"maximaIA")]; // NEW 4-1-0
	} else {
	Dialog.create("Warning: image "+seriesNA[sl]);
	Dialog.addMessage("The image is not found in the 'Foci info' file.");
	Dialog.addString("Specify folder path where foci information is stored.", folderFoci, 90);
	Dialog.addCheckbox("Skip image", false);
	Dialog.show();
	folderFoci = Dialog.getString();
	if (matches(folderFoci,".+/$") == false){
	folderFoci = folderFoci+"/";	
	}
	igFoci = Dialog.getCheckbox();
	if (igFoci == true){
	IsatFA[sl] = "skip image";}
	}
} while (getIndex(fociPara,seriesA[sl]) == -1 && igFoci == false)	
} else { IsatFA[sl] = "skip image";} // end if loop for Foci analysis
if (IsatA[sl] != "skip image" || IsatFA[sl] != "skip image"){
if (sl == 1 || sliceA[sl] != sliceA[sl-1]){
if (sliceA[sl] > 1){ 
IprojectionT = 	IprojectionA[3];	
} else {
IprojectionT = 	IprojectionA[6];	
}
}
Dialog.create("Inspection settings, image "+sl+" / "+seriesN); // suggestion: add option to hide this dialog and use same settings for all!!!
	Dialog.addMessage("Please specify how you want to visualize your image.");
	Dialog.addCheckbox("Split Channels",IsplitB);
	Dialog.addChoice("Stack options", IprojectionA, IprojectionT);
	Dialog.addString("Custom manual analysis parameters (Name - Type), separated by ';'", IcustomMan, 75);
	if (skipRois == false && IsatA[sl] != "skip image"){
	Dialog.addString("ROI annotations (Name - Type), separated by ';'", roiAnnot, 75);}
	if (skipFoci == false && IsatFA[sl] != "skip image"){
	Dialog.addString("Foci annotations (Name - Type), separated by ';'", fociAnnot, 75);}
	// suggestions: let user choose selection colour for foci and ROIs
Dialog.show();
IsplitB = Dialog.getCheckbox();
IprojectionT = Dialog.getChoice();
IprojectionI = getIndex(IprojectionA,IprojectionT);
IcustomMan = Dialog.getString();
IcustomManA = split(IcustomMan,";"); //start extraction of custom analysis parameters
	IcustomManNA = newArray(lengthOf(IcustomManA)); // name array
	IcustomManTA = newArray(lengthOf(IcustomManA)); // type array
	for (i = 0; i < lengthOf(IcustomManA); i += 1){
		helperA = split(IcustomManA[i],"( - )");
		IcustomManNA[i] = helperA[0];
		IcustomManTA[i] = helperA[1];}
if (skipRois == false && IsatA[sl] != "skip image"){
roiAnnot = Dialog.getString();
roiAnnotA = split(roiAnnot,";"); //start extraction of custom analysis parameters
	roiAnnotNA = newArray(lengthOf(roiAnnotA)); // name array
	roiAnnotTA = newArray(lengthOf(roiAnnotA)); // type array
	for (i = 0; i < lengthOf(roiAnnotA); i += 1){
		helperA = split(roiAnnotA[i],"( - )");
		roiAnnotNA[i] = helperA[0];
		roiAnnotTA[i] = helperA[1];}
} else { roiAnnotA = newArray(0);}
if (skipFoci == false && IsatFA[sl] != "skip image"){
fociAnnot = Dialog.getString();
fociAnnotA = split(fociAnnot,";"); //start extraction of custom analysis parameters
	fociAnnotNA = newArray(lengthOf(fociAnnotA)); // name array
	fociAnnotTA = newArray(lengthOf(fociAnnotA)); // type array
	for (i = 0; i < lengthOf(fociAnnotA); i += 1){
		helperA = split(fociAnnotA[i],"( - )");
		fociAnnotNA[i] = helperA[0];
		fociAnnotTA[i] = helperA[1];}
} else { fociAnnotA = newArray(0);}
if (matches(imageSource, ".*/Analysis/Temp/$") == true){
open(imageSource+seriesA[sl]+".tif");
} else {
open(imageSource+seriesNA[sl]);	
}
rename("Tmp_"+seriesA[sl]);
run("Duplicate...", "duplicate");
rename(seriesA[sl]);
if (IsplitB == true){
Stack.setDisplayMode("grayscale");
run("Split Channels");} // default naming: C1-series, C2-series, ...
if (IprojectionT != "keep stack" && IsplitB == true){
	ioiA = newArray(channelA[sl]);
	for (l = 1; l <= channelA[sl]; l += 1){
	selectWindow("C"+l+"-"+seriesA[sl]);
	run("Z Project...", "start="+IfirstZA[sl]+" stop="+IlastZA[sl]+" projection=["+IprojectionA[IprojectionI]+"]");
	selectWindow(IprojectpreA[IprojectionI]+"_C"+l+"-"+seriesA[sl]);
	ioiA[l-1] = IprojectpreA[IprojectionI]+"_C"+l+"-"+seriesA[sl];
	}
} else if (IprojectionT != "keep stack" && IsplitB == false){
selectWindow(seriesA[sl]);
run("Z Project...", "start="+IfirstZA[sl]+" stop="+IlastZA[sl]+" projection=["+IprojectionA[IprojectionI]+"]");
ioiA = newArray(1);
ioiA[0] = IprojectpreA[IprojectionI]+"_"+seriesA[sl];	
} else if (IprojectionT == "keep stack" && IsplitB == true){
ioiA = newArray(channelA[sl]);
for (l = 1; l <= channelA[sl]; l += 1){
ioiA[l-1] = "C"+l+"-"+seriesA[sl];	}
} else if (IprojectionT == "keep stack" && IsplitB == false){
ioiA = newArray(1);
ioiA[0] = seriesA[sl];
} // end if-else loop projections; write names of images of interest in ioiA (image of interest Array) --> select Images in ioiA ...
if (skipRois == false && IsatA[sl] != "skip image" && IroiCA[sl] != 0){ // NEW 4-1-0: last condition
roiManager("Open", folderRoi+seriesA[sl]+".zip");
roiCount = 0;
for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select",roi);
	if (matches(Roi.getName,"roi[0-9]*") == true){
	Roi.setStrokeColor("yellow");
	roiCount = roiCount+1;}
	}
} else {roiCount = 0;}
if (skipFoci == false && IsatFA[sl] != "skip image" && IfociCA[sl] != 0){ // NEW 4-1-0: last condition
roiManager("Open", folderFoci+seriesA[sl]+".zip");
fociCount = 0;
for (roi = 0; roi < roiManager("Count"); roi += 1){
	roiManager("Select",roi);
	if (matches(Roi.getName,"max[0-9]*") == true){
	Roi.setStrokeColor("magenta");
	fociCount = fociCount+1;}
	}
} else { fociCount = 0;}
for (l = 0; l < lengthOf(ioiA); l += 1){
selectWindow(ioiA[l]);
getLocationAndSize(x,y,width,height);
	Iwidth = width;
	Iheight = height;
	if (Iwidth*lengthOf(ioiA) > screenWidth){
	Iwidth = screenWidth/lengthOf(ioiA);	}
	if (Iheight > screenHeight){
	Iheight = screenHeight;}
setLocation(0+l*Iwidth,(screenHeight-Iheight)/2);	
roiManager("Show All without labels"); // allow user to choose with/without labels and set stroke colour individually!
}
IcustomManVA = newArray(lengthOf(IcustomManA)); // Value array for custom manual analysis
if (lengthOf(IcustomManA) + (roiCount * lengthOf(roiAnnotA)) + (fociCount * lengthOf(fociAnnotA)) <= 18){ // Decision loop for # of Dialog boxes based on roiCount, fociCount, roiAnnotA, fociAnnotA
diaC = 1;	// one Dialog box with all custom analysis parameters
roiAnnotVA = newArray(lengthOf(roiAnnotA)*roiCount);
fociAnnotVA = newArray(lengthOf(fociAnnotA)*fociCount);
roiSelectA = Array.slice(Array.getSequence(roiCount+1),1,roiCount+1);
fociSelectA = Array.slice(Array.getSequence(fociCount+1),1,fociCount+1);
} else if ((roiCount * lengthOf(roiAnnotA)) + lengthOf(IcustomManA) <= 18){
diaC = 2;	// 2 Dialog boxes (1st: general + ROIs, 2nd: Foci)
roiAnnotVA = newArray(lengthOf(roiAnnotA)*roiCount);
roiSelectA = Array.slice(Array.getSequence(roiCount+1),1,roiCount+1);
} else {
diaC = 3;	// 3 Dialog boxes (1st: general, 2nd: ROIs, 3rd: Foci)
}
do { // begin loops 1st Dialog box
Dialog.create("ROI inspector, image "+sl+" / "+seriesN); // 1st Dialog box ADD OPTION to hide Dialog boxes to enable the user to adjust the image ...
	Dialog.addCheckbox("Save image(s) with ROIs as overlay",Isave); // suggestion: include option to flatten?
	for (i = 0; i < lengthOf(IcustomManA); i += 1){
		if (IcustomManTA[i] == "Num"){
		Dialog.addNumber(IcustomManNA[i],0);}
		else if (IcustomManTA[i] == "Str"){
		Dialog.addString(IcustomManNA[i],"");}
		else{
		Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	}
	if(skipRois == false && IsatA[sl] != "skip image"){
	if (diaC == 1 || diaC == 2){ 
		for (a = 0; a < lengthOf(roiAnnotA); a += 1){
		for (i = 0; i < roiCount; i += 1){
		if (roiAnnotTA[a] == "Num"){
			Dialog.addNumber(roiAnnotNA[a]+", roi"+(i+1),0);}
			else if (roiAnnotTA[a] == "Str"){
			Dialog.addString(roiAnnotNA[a]+", roi"+(i+1),"");}
			else{
			Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}	
		} // end for ROIs
		} // end for annotation types
	}}
	if (skipFoci == false && IsatFA[sl] != "skip image"){
	if (diaC == 1){
	for (a = 0; a < lengthOf(fociAnnotA); a += 1){
	for (i = 0; i < fociCount; i += 1){
		if (fociAnnotTA[a] == "Num"){
			Dialog.addNumber(fociAnnotNA[a]+", max"+(i+1),0);}
			else if (fociAnnotTA[a] == "Str"){
			Dialog.addString(fociAnnotNA[a]+", max"+(i+1),"");}
			else{
			Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}	
		} // end for foci
		} // end for annotation types
	}}
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
Isave = Dialog.getCheckbox();
for (i = 0; i < lengthOf(IcustomManA); i += 1){
if (IcustomManTA[i] == "Num"){
IcustomManVA[i] = Dialog.getNumber();}
else if (IcustomManTA[i] == "Str"){
IcustomManVA[i] = Dialog.getString();}
}
if (skipRois == false && IsatA[sl] != "skip image"){
if (diaC == 1 || diaC == 2){
for (a = 0; a < lengthOf(roiAnnotA); a += 1){
for (i = 0; i < roiCount; i += 1){
	if (roiAnnotTA[a] == "Num"){
	roiAnnotVA[a*roiCount+i] = Dialog.getNumber();} // value array: Annotation 1 for rois 1...n, Annotation 2 for rois 1...n, ... Annotation n for rois 1...n
	else if (roiAnnotTA[a] == "Str"){
	roiAnnotVA[a*roiCount+i] = Dialog.getString();}	
	}
	}
}}
if (skipFoci == false && IsatFA[sl] != "skip image"){
if (diaC == 1){
for (a = 0; a < lengthOf(fociAnnotA); a += 1){
for (i = 0; i < fociCount; i += 1){
	if (fociAnnotTA[a] == "Num"){
	fociAnnotVA[a*fociCount+i] = Dialog.getNumber();}
	else if (fociAnnotTA[a] == "Str"){
	fociAnnotVA[a*fociCount+i] = Dialog.getString();}}
	}	
}} // end loops 1 Dialog box
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} while (hideDia == true);
hideDia = true;
if (diaC == 3 && skipRois == false && IsatA[sl] != "skip image"){ // start if loop 3 Dialog boxes; Dialog for ROIs
do {
if (roiCount * lengthOf(roiAnnotA) <= 20){
roiSelectA = Array.slice(Array.getSequence(roiCount+1),1,roiCount+1);
Dialog.create("ROI annotations"); // 2nd Dialog box
	for (a = 0; a < lengthOf(roiAnnotA); a += 1){
	for (i = 0; i < roiCount; i += 1){
	if (roiAnnotTA[a] == "Str"){
	Dialog.addString(roiAnnotNA[a]+", roi"+(i+1),"");		
	} else if (roiAnnotTA[a] == "Num"){
	Dialog.addNumber(roiAnnotNA[a]+", roi"+(i+1),0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop rois
	} // end for loop annotations
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
roiAnnotVA = newArray(roiCount * lengthOf(roiAnnotA));
for (a = 0; a < lengthOf(roiAnnotA); a += 1){
	for (i = 0; i < roiCount; i += 1){
	if (roiAnnotTA[a] == "Str"){
	roiAnnotVA[a*roiCount+i] = Dialog.getString();		
	} else if (roiAnnotTA[a] == "Num"){
	roiAnnotVA[a*roiCount+i] = Dialog.getNumber();}
	} // end for loop rois
	} // end for loop annotations
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manager, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} else if (roiCount <= 20){
roiSelectA = Array.slice(Array.getSequence(roiCount+1),1,roiCount+1);
roiAnnotVA = newArray(roiCount * lengthOf(roiAnnotA));
for (a = 0; a < lengthOf(roiAnnotA); a += 1){
Dialog.create("ROI annotations: "+roiAnnotNA[a]); // 2nd Dialog box
	for (i = 0; i < roiCount; i += 1){
	if (roiAnnotTA[a] == "Str"){
	Dialog.addString(roiAnnotNA[a]+", roi"+(i+1),"");		
	} else if (roiAnnotTA[a] == "Num"){
	Dialog.addNumber(roiAnnotNA[a]+", roi"+(i+1),0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop rois
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
for (i = 0; i < roiCount; i += 1){
	if (roiAnnotTA[a] == "Str"){
	roiAnnotVA[a*roiCount+i] = Dialog.getString();		
	} else if (roiAnnotTA[a] == "Num"){
	roiAnnotVA[a*roiCount+i] = Dialog.getNumber();}
	} // end for loop rois	
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} // end for loop annotations (1 Dialog box / annotation
} else {
Dialog.create("Select ROIs");
	Dialog.addMessage("More than 20 ROIs have been detected. Please specify ROIs you want to annotate.");
	Dialog.addString("ROIs (separated by ',' or '-')",roiSelect);
	Dialog.addMessage("Enter ROI numbers as in ROI list (number after 'roi'), NOT as in 'labels' as displayed on image.");
Dialog.show();
roiSelect = Dialog.getString();
roiSelectA = StrToNumArray(roiSelect);
roiAnnotVA = newArray(lengthOf(roiSelectA) * lengthOf(roiAnnotA));
for (a = 0; a < lengthOf(roiAnnotA); a += 1){
Dialog.create("ROI annotations: "+roiAnnotNA[a]); // 2nd Dialog box
	for (i = 0; i < lengthOf(roiSelectA); i += 1){
	if (roiAnnotTA[a] == "Str"){
	Dialog.addString(roiAnnotNA[a]+", roi"+roiSelectA[i],"");		
	} else if (roiAnnotTA[a] == "Num"){
	Dialog.addNumber(roiAnnotNA[a]+", roi"+roiSelectA[i],0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop rois
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
for (i = 0; i < lengthOf(roiSelectA); i += 1){
	if (roiAnnotTA[a] == "Str"){
	roiAnnotVA[a*lengthOf(roiSelectA)+i] = Dialog.getString();		
	} else if (roiAnnotTA[a] == "Num"){
	roiAnnotVA[a*lengthOf(roiSelectA)+i] = Dialog.getNumber();}
	} // end for loop rois	
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} // end for loop annotations (1 Dialog box / annotation)
} // end if-else < 20 annotation lines
} while (hideDia == true);
hideDia = true;
} // end if 3 Dialog boxes (separate Dialog box for ROIs)
if (skipFoci == false && IsatFA[sl] != "skip image"){
if (diaC == 2 || diaC == 3){ 
do{
if (fociCount * lengthOf(fociAnnotA) <= 20){
fociSelectA = Array.slice(Array.getSequence(fociCount+1),1,fociCount+1);
Dialog.create("Foci annotations"); // 2nd or 3rd Dialog box
	for (a = 0; a < lengthOf(fociAnnotA); a += 1){
	for (i = 0; i < fociCount; i += 1){
	if (fociAnnotTA[a] == "Str"){
	Dialog.addString(fociAnnotNA[a]+", max"+(i+1),"");		
	} else if (fociAnnotTA[a] == "Num"){
	Dialog.addNumber(fociAnnotNA[a]+", max"+(i+1),0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop foci
	} // end for loop annotations
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
fociAnnotVA = newArray(fociCount * lengthOf(fociAnnotA));
for (a = 0; a < lengthOf(fociAnnotA); a += 1){
	for (i = 0; i < fociCount; i += 1){
	if (fociAnnotTA[a] == "Str"){
	fociAnnotVA[a*fociCount+i] = Dialog.getString();		
	} else if (fociAnnotTA[a] == "Num"){
	fociAnnotVA[a*fociCount+i] = Dialog.getNumber();}
	} // end for loop foci
	} // end for loop annotations
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} else if (fociCount <= 20){
fociSelectA = Array.slice(Array.getSequence(fociCount+1),1,fociCount+1);
fociAnnotVA = newArray(fociCount * lengthOf(fociAnnotA));
for (a = 0; a < lengthOf(fociAnnotA); a += 1){
Dialog.create("Foci annotations: "+fociAnnotNA[a]); // 2nd or 3rd Dialog box
	for (i = 0; i < fociCount; i += 1){
	if (fociAnnotTA[a] == "Str"){
	Dialog.addString(fociAnnotNA[a]+", max"+(i+1),"");		
	} else if (fociAnnotTA[a] == "Num"){
	Dialog.addNumber(fociAnnotNA[a]+", max"+(i+1),0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop foci	
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);
Dialog.show();
for (i = 0; i < fociCount; i += 1){
	if (fociAnnotTA[a] == "Str"){
	fociAnnotVA[a*fociCount+i] = Dialog.getString();		
	} else if (fociAnnotTA[a] == "Num"){
	fociAnnotVA[a*fociCount+i] = Dialog.getNumber();}
	} // end for loop foci	
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} // end for loop annotations (1 Dialog box / annotation
} else {
Dialog.create("Select Foci");
	Dialog.addMessage("More than 20 foci have been detected. Please specify foci you want to annotate.");
	Dialog.addString("foci (separated by ',' or '-')",fociSelect);
	Dialog.addMessage("Enter ROI numbers as in ROI list (number after 'max'), NOT as in 'labels' as displayed on image.");
Dialog.show();
fociSelect = Dialog.getString();
fociSelectA = StrToNumArray(fociSelect);
fociAnnotVA = newArray(lengthOf(fociSelectA) * lengthOf(fociAnnotA));
for (a = 0; a < lengthOf(fociAnnotA); a += 1){
Dialog.create("Foci annotations: "+fociAnnotNA[a]); // 2nd or 3rd Dialog box
	for (i = 0; i < lengthOf(fociSelectA); i += 1){
	if (fociAnnotTA[a] == "Str"){
	Dialog.addString(fociAnnotNA[a]+", max"+fociSelectA[i],"");		
	} else if (fociAnnotTA[a] == "Num"){
	Dialog.addNumber(fociAnnotNA[a]+", max"+fociSelectA[i],0);	
	} else { Dialog.addMessage("Error: parameter type must be either 'Num' or 'Str'");}
	} // end for loop foci
	Dialog.addCheckbox("Hide Dialog to adjust active slice, contrast etc.",!hideDia);	
Dialog.show();
for (i = 0; i < lengthOf(fociSelectA); i += 1){
	if (fociAnnotTA[a] == "Str"){
	fociAnnotVA[a*lengthOf(fociSelectA)+i] = Dialog.getString();		
	} else if (fociAnnotTA[a] == "Num"){
	fociAnnotVA[a*lengthOf(fociSelectA)+i] = Dialog.getNumber();}
	} // end for loop foci	
hideDia = Dialog.getCheckbox();
if (hideDia == true){
waitForUser("Pause", "You can look at ROIs separately with the Manger, adjust brightness/contrast etc.\nIf you want to continue with the analysis, click OK and have 'hide Dialog' unchecked in the Dialog box.");	
}
} // end for loop annotations (1 Dialog box / annotation
} // end if-else < 20 annotation lines
} while (hideDia == true);
hideDia = true; 
} // end if 2 Dialog boxes (separate foci Dialog)
} // end if for execution only if foci are not excluded
if (Isave == true){
	for (l = 0; l < lengthOf(ioiA); l += 1){
	selectWindow(ioiA[l]);
	run("From ROI Manager");
	saveAs("Tiff",folder+"Analysis/ROI-inspection/"+ioiA[l]+".tif");
	close();}
}
if (IcustomMan != ""){
IcustomManNA = Array.concat("Annotation", IcustomManNA);
IcustomManTA = Array.concat("type", IcustomManTA);
IcustomManVA = Array.concat("user input", IcustomManVA);	
Array.show("ROI inspection", IcustomManNA,IcustomManTA,IcustomManVA);
selectWindow("ROI inspection");
save(folder+"Analysis/ROI-inspection/Manual-analysis_"+seriesA[sl]+".txt");
selectWindow("Manual-analysis_"+seriesA[sl]+".txt");
run("Close");}
if (skipRois == false && roiAnnot != "" && IsatA[sl] != "skip image" && IroiCA[sl] != 0){ // NEW 4-1-0 last condition
annotNameR = newArray(roiCount*lengthOf(roiAnnotA));
annotTypeR = newArray(roiCount*lengthOf(roiAnnotA));
annotValueR = newArray(roiCount*lengthOf(roiAnnotA));
allrois = Array.slice(Array.getSequence(roiCount+1),1,roiCount+1);
for (a = 0; a < lengthOf(roiAnnotA); a += 1){
	for (i = 0; i < roiCount; i += 1){
	annotNameR[a*roiCount+i] = roiAnnotNA[a];
	annotTypeR[a*roiCount+i] = roiAnnotTA[a];
	si = getIndex(roiSelectA,(i+1));
	if (si != -1){ 
	annotValueR[a*roiCount+i] = roiAnnotVA[a*lengthOf(roiSelectA)+si]; // value array: Annotation 1 for rois 1...n, Annotation 2 for rois 1...n, ... Annotation n for rois 1...n
	} else {
	annotValueR[a*roiCount+i] = "NA";	
	}
	}
if (a == 0){
allroisA = allrois;} else {
allroisA = Array.concat(allroisA,allrois);}
}
allroisA = Array.concat("ROI #", allroisA);
annotNameR = Array.concat("Annotation", annotNameR);
annotTypeR = Array.concat("type", annotTypeR);
annotValueR = Array.concat("user input", annotValueR);
Array.show("ROI inspection", allroisA, annotNameR, annotTypeR, annotValueR); 
selectWindow("ROI inspection");
save(folder+"Analysis/ROI-inspection/ROI-annotation_"+seriesA[sl]+".txt");
selectWindow("ROI-annotation_"+seriesA[sl]+".txt");
run("Close");}
if (skipFoci == false && fociAnnot != "" && IsatFA[sl] != "skip image" && IfociCA[sl] != 0){ // New 4-1-0 last condition
annotNameF = newArray(fociCount*lengthOf(fociAnnotA));
annotTypeF = newArray(fociCount*lengthOf(fociAnnotA));
annotValueF = newArray(fociCount*lengthOf(fociAnnotA));
allfoci = Array.slice(Array.getSequence(fociCount+1),1,fociCount+1);
for (a = 0; a < lengthOf(fociAnnotA); a += 1){
	for (i = 0; i < fociCount; i += 1){
	annotNameF[a*fociCount+i] = fociAnnotNA[a];
	annotTypeF[a*fociCount+i] = fociAnnotTA[a];
	si = getIndex(fociSelectA,(i+1));
	if (si != -1){
	annotValueF[a*fociCount+i] = fociAnnotVA[a*lengthOf(fociSelectA)+si]; // value array: Annotation 1 for rois 1...n, Annotation 2 for rois 1...n, ... Annotation n for rois 1...n
	} else {
	annotValueF[a*fociCount+i] = "NA";	
	}
	}
if (a == 0){
allfociA = allfoci;} else {
allfociA = Array.concat(allfociA,allfoci);}
}
allfociA = Array.concat("Focus #", allfociA);
annotNameF = Array.concat("Annotation", annotNameF);
annotTypeF = Array.concat("type", annotTypeF);
annotValueF = Array.concat("user input", annotValueF);
Array.show("ROI inspection", allfociA, annotNameF, annotTypeF, annotValueF); 
selectWindow("ROI inspection");
save(folder+"Analysis/ROI-inspection/Foci-annotation_"+seriesA[sl]+".txt");
selectWindow("Foci-annotation_"+seriesA[sl]+".txt");
run("Close");}	
closeRegex(".*[-_]"+seriesA[sl]);
closeRegex(seriesA[sl]);
} // end if loop for execution only on non-skipped images
} // end central loop that loops over images
waitForUser("ROI inspection completed", "You have completed the task 'ROI inspection'.");
} // end central if loop for execution of ROI inspector part
// final part after each macro execution - ALWAYS EXECUTED IF  MACRO RUN IS COMPLETED
widthA[0] = "image width";
heightA[0] = "image height";
channelA[0] = "# channels";
sliceA[0] = "# slices";
frameA[0] = "# frames";
Array.show("Basic Image Data", seriesNA, seriesA, widthA, heightA, channelA, sliceA, frameA, XsizeA, YsizeA, ZsizeA, unitA);
selectWindow("Basic Image Data");
save(folder+"Analysis/Info/Image-Data_all.txt"); // this file is only written if macro executes without crashes/cancellations
selectWindow("Image-Data_all.txt");
run("Close");
Dialog.create("Save temporary image files?");
	Dialog.addMessage("Do you want to discard the Temp folder and the images within?");
	Dialog.addRadioButtonGroup("discard?", newArray("yes","no"),1,2,"no");
Dialog.show();
delTempYN = Dialog.getRadioButton();
if (delTempYN == "yes"){
	for (i = 1; i <= seriesN; i += 1){
File.delete(folder+"Analysis/Temp/"+seriesA[i]+".tif");
	}
File.delete(folder+"Analysis/Temp");	
}
//close("*"); // personal convenience, execute with Cmd+Shift+R to close all open image windows