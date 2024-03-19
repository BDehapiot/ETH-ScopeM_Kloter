/// Open data ------------------------------------------------------------------

setBatchMode(true);

// Open data
//open("./data/230524_full_Phygocytosis.tif"); // !!! Dev !!! 
run("Open...");
setBatchMode("show");

// get info
Stack.getDimensions(width, height, channels, slices, frames)
getPixelSize(unit, pixelWidth, pixelHeight);
name = getTitle();
stem = File.nameWithoutExtension;
dir = File.directory;

// Initialize
run("Set Measurements...", "  redirect=None decimal=3");

/// Dialog box -----------------------------------------------------------------

rSize = 128;
sigma = 2;

//Dialog.create("Options");
//rSize = Dialog.addNumber("ROI size (pixels):", 128);
//sigma = Dialog.addNumber("Gaussian blur (pixels):", 2);
//Dialog.show();
//rSize = Dialog.getNumber();
//sigma = Dialog.getNumber();

/// Process --------------------------------------------------------------------

// Channel 1 (mTurquoise)
selectWindow(name);
run("Duplicate...", "duplicate channels=1"); rename("C1");
run("Z Project...", "projection=[Max Intensity] all"); rename("C1_max");
run("Grays"); run("32-bit"); run("Divide...", "value=255 stack");
setMinAndMax(0, 1);

// Channel 2 (eYFP)
selectWindow(name); 
run("Duplicate...", "duplicate channels=2"); rename("C2");
run("Z Project...", "projection=[Max Intensity] all"); rename("C2_max");
run("Grays"); run("32-bit"); run("Divide...", "value=255 stack");
setMinAndMax(0, 1);

// Channel 4 (Brightfield)
selectWindow(name);
run("Duplicate...", "duplicate channels=4"); rename("C4");
run("Z Project...", "projection=[Standard Deviation] all"); rename("C4_std");

/// Display --------------------------------------------------------------------

// Merge images
imageCalculator("Average create 32-bit stack", "C1_max","C2_max"); 
run("Gaussian Blur...", "sigma=" + sigma + " stack");
rename("Merged"); run("Fire");
run("Merge Channels...", "c1=Merged c4=C4_std create");
run("RGB Color", "frames");

// Close & display
close("C1"); close("C2"); close("C4");
selectWindow("Merged");
setBatchMode("show");
run("Tile");

/// Annotation -----------------------------------------------------------------

selectWindow("Merged");
setTool("point");
run("Point Tool...", "type=Circle color=Yellow size=XXXL auto-measure add_to label");
//open("C:/Users/bdeha/Desktop/Kloter/Results.csv"); // !!! Dev !!! 
waitForUser("Track object of interest, click OK when done");

/// Extraction -----------------------------------------------------------------

newImage("C1_crop", "8-bit grayscale-mode", rSize, rSize, 1, 1, nResults());
newImage("C2_crop", "8-bit grayscale-mode", rSize, rSize, 1, 1, nResults());

for (i=0; i<nResults(); i++){
	
	x = round((getResult("X", i) / pixelWidth));
	y = round((getResult("Y", i) / pixelWidth));
	t = getResult("Slice", i);
	
	selectWindow("C1_max"); setSlice(t);
	makeRectangle(x - rSize / 2, y - rSize / 2, rSize, rSize);
	run("Copy"); 	
	selectWindow("C1_crop"); setSlice(i + 1);
	run("Paste"); run("Select None");
	
	selectWindow("C2_max"); setSlice(t);
	makeRectangle(x - rSize / 2, y - rSize / 2, rSize, rSize);
	run("Copy"); 	
	selectWindow("C2_crop"); setSlice(i + 1);
	run("Paste"); run("Select None");

}

close("C1_max"); close("C2_max");
run("Clear Results");

/// Segment object -------------------------------------------------------------

run("Set Measurements...", "mean redirect=None decimal=3");

selectWindow("C1_crop"); 
run("Duplicate...", "duplicate"); rename("C1_crop_gb");
run("Gaussian Blur...", "sigma=" + sigma + " stack"); run("32-bit");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
run("Divide...", "value="+max+" stack");

selectWindow("C2_crop"); 
run("Duplicate...", "duplicate"); rename("C2_crop_gb");
run("Gaussian Blur...", "sigma=" + sigma + " stack"); run("32-bit");
Stack.getStatistics(voxelCount, mean, min, max, stdDev);
run("Divide...", "value="+max+" stack");

imageCalculator("Average create 32-bit stack", "C1_crop_gb","C2_crop_gb");
setMinAndMax(0, 1); run("8-bit");
run("Convert to Mask", "method=Otsu background=Dark black"); rename("C1C2_mask");
run("Analyze Particles...", "add stack");
roiManager("Show None");

close("C1_crop_gb"); close("C2_crop_gb");

/// Fluo. measurments ----------------------------------------------------------

n = roiManager("count")

selectWindow("C1_crop"); 
roiManager("Measure");
m475nm = newArray(nResults())
for(i=0; i<n; i++){
	m475nm[i] = getResult("Mean", i);
}
run("Clear Results");

selectWindow("C2_crop"); 
roiManager("Measure");
m525nm = newArray(nResults())
for(i=0; i<n; i++){
	m525nm[i] = getResult("Mean", i);
}
run("Clear Results");

mRatio = newArray(nResults())
for(i=0; i<n; i++){
	mRatio[i] = m475nm[i]/m525nm[i];
}

for(i=0; i<n; i++){
	setResult("475nm", i, m475nm[i]);
	setResult("525nm", i, m525nm[i]);
	setResult("ratio", i, mRatio[i]);
}

run("Summarize");

/// Format & save --------------------------------------------------------------

run("Merge Channels...", "c2=C1_crop c6=C2_crop create");
rename("crop");
setBatchMode("show");
setTool("rectangle");

newdir = dir + stem;
if (File.exists(newdir) == 0) {
	File.makeDirectory(newdir);
}

idx = 0;
exist = 1;
while (exist == 1) {
	idx = idx + 1;
	crop_path = newdir + "/track-" + idx + "_crop.tif";
	results_path = newdir + "/track-" + idx + "_results.csv";
	ROIs_path = newdir + "/track-" + idx + "_ROIset.zip";
    exist = File.exists(crop_path);
    if (exist == 0) {
		selectWindow("crop");
		saveAs("Tiff", crop_path);
		selectWindow("Results");
		saveAs("Results", results_path);
		roiManager("Save", ROIs_path);
    }
}

/// Close all ------------------------------------------------------------------

waitForUser( "Pause","Click Ok to close all");
macro "Close All Windows" { 
while (nImages>0) { 
selectImage(nImages); 
close();
}
if (isOpen("Log")) {selectWindow("Log"); run("Close");} 
if (isOpen("Summary")) {selectWindow("Summary"); run("Close");} 
if (isOpen("Results")) {selectWindow("Results"); run("Close");}
if (isOpen("Profiles")) {selectWindow("Profiles"); run("Close");}
if (isOpen("ROI Manager")) {selectWindow("ROI Manager"); run("Close");}
} 
