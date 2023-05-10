/// --- Dialog Box --- ///
Dialog.create("Options");
thresh = Dialog.addNumber("segment. thresh.", 25.0000);
Dialog.show();
thresh = Dialog.getNumber();

/// --- Initialize --- ///
src = getTitle();
setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);
run("Set Measurements...", "mean redirect=None decimal=3");

setBatchMode(true);

/// --- Extract --- ///
selectWindow(src);
setSlice(1);
run("Duplicate...", " channels=1");
rename("475nm");
selectWindow(src);
setSlice(2);
run("Duplicate...", " channels=2");
rename("525nm");

/// --- Mask --- ///
run("Concatenate...", "title=temp keep open image1=475nm image2=525nm image3=[-- None --]");
run("Z Project...", "projection=[Sum Slices]");
run("Gaussian Blur...", "sigma=3");
setMinAndMax(0, 510);
run("8-bit");
setThreshold(thresh, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
rename("mask");
close("temp");

/// --- Measure --- ///

run("Analyze Particles...", "add");
n = roiManager("count")

m475nm = newArray(nResults())
selectWindow("475nm");
roiManager("Measure");
for(i=0; i<n; i++){
	m475nm[i] = getResult("Mean", i);
}
run("Clear Results");

m525nm = newArray(nResults())
selectWindow("525nm");
roiManager("Measure");
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

/// --- Display --- ///

selectWindow("mask");
run("Remove Overlay");
run("Outline");
run("Dilate");
run("Merge Channels...", "c2=525nm c4=mask c6=475nm create");
rename("Display");

setBatchMode("exit and display");

run("Tile");
selectWindow(src);
run("Out [-]");
selectWindow("Display");
run("Out [-]");