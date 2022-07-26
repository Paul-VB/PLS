@lazyGlobal off.

//this script is meant to be run at least once before we use any of the code here.
declare local basePath to "0:/PLS/".

//import statements
runOncePath(basePath+"orbitTools.ks").
runOncePath(basePath+"navigationDegreeTools.ks").
runOncePath(basePath+"azCalc.ks").
runOncePath(basePath+"ApoLaunchPitchProgram.ks",(10)).
runOncePath(basePath+"engineBurnTimeCalc.ks").
runOncePath(basePath+"autoStage.ks").
runOncePath(basePath+"gui/parkingOrbit.ks").
runOncePath(basePath+"gui/guiSkin.ks").
runOncePath(basePath+"utils/extraMath.ks").
