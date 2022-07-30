@lazyGlobal off.

//this script is meant to be run at least once before we use any of the code here.
declare local basePath to "0:/PLS/".

//import statements
runOncePath(basePath+"utils/orbitTools.ks").
runOncePath(basePath+"utils/navigationDegreeTools.ks").
runOncePath(basePath+"azCalc.ks").
runOncePath(basePath+"ApoLaunchPitchProgram.ks",(13)).
runOncePath(basePath+"engineBurnTimeCalc.ks").
runOncePath(basePath+"launchWindowCalc.ks").
runOncePath(basePath+"utils/autoStage.ks").
runOncePath(basePath+"gui/parkingOrbit.ks").
runOncePath(basePath+"gui/guiSkin.ks").
runOncePath(basePath+"gui/hudStuff.ks").
runOncePath(basePath+"gui/warpPrompt.ks").
runOncePath(basePath+"utils/extraMath.ks").
