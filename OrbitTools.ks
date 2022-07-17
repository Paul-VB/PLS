@lazyGlobal off.

//import statmeents
// #include "navigationDegreeTools.ks"

//given a target orbit and a launch location, give me the best-possible initial parking orbit achievable
function calculateParkingOrbit{
	parameter targetOrbit, launchLocation.
	//first, lets determine if we can launch directly into the orbital plane. 
	//If our launch lattitude is higher than the target orbit inclination, then direct is not possible
	//if direct launch is not possible, then we'll get as close as we can
	declare local parkingOrbitInclination to max(targetOrbit:inclination,abs(launchLocation:lat)).
	
	//next determine the apoapsis/periapsis (altitude) of the parking orbit. 
	//Since the parking orbit will be circular, the apoapsis will be the same height as periapsis
	//the altitude of the parking orbit should be equal the periapsis of the targit orbit
	declare local parkingOrbitSemiMajorAxis to targetOrbit:body:radius + targetOrbit:periapsis.

	//for the sake of saftey, the altitude of the parking orbit should NEVER be below the atmosphere of the body we are orbiting + a saftey margin
	declare local parkingOrbitAtmosphereSafteyMargin to 1000.
	if (targetOrbit:body:atm:exists) {
		declare local minimumSafeSemiMajorAxis to targetOrbit:body:radius + targetOrbit:body:atm:height + parkingOrbitAtmosphereSafteyMargin.
		set parkingOrbitSemiMajorAxis to max(parkingOrbitSemiMajorAxis,minimumSafeSemiMajorAxis).
	}

	declare local parkingOrbit to createOrbit(parkingOrbitInclination,0,parkingOrbitSemiMajorAxis,targetOrbit:LAN,targetOrbit:ARGUMENTOFPERIAPSIS,0,0,targetOrbit:body).

	return parkingOrbit.
}

//given an orbit, imagine a new, coplanar orbit with identiacl paramets except that the apoapsis is set to the periapsis, thus making the new orbit a circular one
//then, calculate the orbital velocity (in meters per second, or m/s) of this new circular orbit
function getOrbitalVelocityOfCircularOrbit{
	parameter targetOrbit.
	declare local bodyMass to targetOrbit:body:mass.
	declare local orbitalRadius to targetOrbit:body:radius + targetOrbit:periapsis.
	declare local orbitalVelocity to sqrt((constant:G * bodyMass)/orbitalRadius).
	return orbitalVelocity.
}

//creats a new circular orbit that is co-planar to the sourceOrbit. 
function createCircularCoplanarOrbit{
	parameter sourceOrbit, altitudeOfNewOrbit.
	declare local newOrbit to createOrbit(sourceOrbit:inclination,0,sourceOrbit:body:radius+altitudeOfNewOrbit,sourceOrbit:lan,sourceOrbit:ARGUMENTOFPERIAPSIS,0,0,sourceOrbit:body).
	return newOrbit.

}

function printOrbitInfo{
	
	parameter theOrbit, orbitName is "orbit".
	print("inclination of "+orbitName+"'s orbit is "+theOrbit:inclination).
	print("eccentircity of "+orbitName+"'s orbit is "+theOrbit:eccentricity).
	print("semi-major axis of "+orbitName+"'s orbit is "+theOrbit:semimajoraxis).
	print("lattitude of ascending node of "+orbitName+"'s orbit is "+theOrbit:lan).
	print("argumentOfPeriapsis of "+orbitName+"'s orbit is "+theOrbit:argumentofperiapsis).
	print("Epoch of "+orbitName+"'s orbit is "+theOrbit:epoch).
	print("body of "+orbitName+"'s orbit is "+theOrbit:body).
}

//given an orbit, calculate it's LAN in terms of it's parent body. the resulting value will be given in "trig" scale (0 to +360)
function getLocalTrigLanOfOrbit{
	parameter theOrbit.
	//first, we know that the LAN suffix is given in a range of 0 to +360
	//we also know that planetRotationangle is also in a range of 0 to +360
	declare local planetRotAngle to theOrbit:body:rotationangle.
	declare local localLan to theOrbit:LAN - planetRotAngle.
    set localLan to clampAngleBetween0and360(localLan).
	return localLan.
}

//determine if the oribit is prograde or retrograde
function isOrbitPrograde{
	parameter theOrbit.
	return theOrbit:inclination <= 90.
}

//calculates what compass heading the prograde vector is for a ship at any given point in an orbit (or suborbital flight) - correct
// function calculateProgradeCompassHeading_old{
// 	parameter targetOrbit,shipPosition.
// 	declare local longDifference to absoluteLongitudinalDifference(getLocalTrigLanOfOrbit(targetOrbit),shipPosition:lng).
// 	declare local result to arcTan(tan(longDifference)/sin(abs(shipPosition:lat))).
// 		if longDifference > 90 {
// 			set result to result + 180.
// 		}
// 	if not isOrbitPrograde(targetOrbit){
// 		set result to mod(360 - result,-360).
// 	}
// 	return result.
// }

