@lazyGlobal off.

// #include "utils/OrbitTools.ks"

//Given a target orbit and the launch duration (usually the MET at MECO), at what time is our next launch window?
//The launch window is defined as just before our target orbit passes directly above our launch site.
//We need to launch a little bit early to account for how long it takes for the rocket to get up to speed.
function calculateNextLaunchWindow{
	parameter targetOrbit, launchDuration.

	//to calculate the launch window' we do the following:
	//1. determine how many degrees east the target orbital plane is from our current location.
	//2. determine how long it will take the planet we are sitting on to rotate that many degrees.
	//3. that many seconds from now (minus launch duration) will be the time of our next launch window.

	//how many degrees east away is the target orbital plane?
	declare local degreesEastToLaunchWindow to longitudinalDistanceFromTargetOrbitalPlane(targetOrbit)*-1.
	//if degreesEastToLaunchWindow is negative, that means we are east of the orbital plane and we just missed a launch window. 
	//We need to aim for the next window
	if degreesEastToLaunchWindow < 0 {
		set degreesEastToLaunchWindow to degreesEastToLaunchWindow + 180.
	}

	//how many seconds will it take the planet to rotate that many degrees?
	declare local timeToRotate to rotationSpeed(targetOrbit:body)*degreesEastToLaunchWindow.	

	//how long do we need to wait until the next launch window?
	declare local waitDuration to timeToRotate - launchDuration.

	//what time stamp is waitDuration seconds after now?
	return time+waitDuration.
}

//how many degrees per second does a given body rotate?
function rotationSpeed{
	parameter theBody.
	return theBody:rotationPeriod/360.
}