@lazyGlobal off.

//import statmeents
// #include "navigationDegreeTools.ks"
// #include "extraMath.ks"

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

//calculate the instantaneous speed we need to raise our apoapsis to a target altitude using the vis-viva equasion
//this function takes into account our current (sub)orbital parameters
function calculateSpeedRequiredForApoapsis{
	parameter targetApoapsis.
	declare local sma to (ship:orbit:periapsis + targetApoapsis )/2 + ship:body:radius.
	declare local distanceToCenterOfBody to ship:altitude + ship:body:radius.
	declare local requiredSpeed to sqrt(ship:body:mu * ((2/distanceToCenterOfBody)-(1/sma))).
	return requiredSpeed.
}


//How far east or west is the ship from intersecting a target orbital plane?
//this is given in longitudinal degrees. 
//positive (+) values represent east
//negative (-) values represent west
function longitudinalDistanceFromTargetOrbitalPlane{
	parameter targetOrbit.
	//we will find how far east or west outside the target orbital plane we are by doing the following:
	//1. figure how how far east or west we *would be* from the local LAN if we were in the orbital plane at our current latitude
	//		since there are always two possible answers to that question, we will use the answer that is closest to the ship's actual longitude.
	//2. how far east or west we *actually* are from the local LAN of the target orbit. 
	//3. take the difference of those two values, and we should get our longitudinal distance to the orbital plane

	//first lets grab our ship's current position
	declare local shipPos to ship:geoposition.

	//next, grab the target orbit's local LAN
	declare local targetLocalTrigLan to getLocalTrigLanOfOrbit(targetOrbit).

	//if the ship *was* in the target orbital plane (ISWITP), what would our longitudinal distance to the LAN be at our current latitude?
	//pretend the ship is dragged east or west such that it intersects that orbital plane.
	//The ship's latitude stays the same. Only the longitude is changed.
	//At the ship's new imaginary location, how far east or west would the ship be from that target orbit's local LAN?
	//The local LAN of an orbit is the longitude where the orbit's plane intersects it's parent planet's equator. this constantly changes as the parent planet rotates
	//since there are always two possible answers to that question, we will use the answer that is closest to the ship's actual longitude.
	declare local longitudinalOffsetFromLocalLanISWITP to 0.
	{
		//determine if we are closer to the ascending or decending node of the target orbit
		declare local closerToDecendingNode to abs(signedLongitudinalDifference(ship:geoposition:lng,targetLocalTrigLan)) > 90.

		//next, find the inclination of the nearest node, either ascending or decending
		declare local nearestNodeInclination to targetOrbit:inclination.
		if closerToDecendingNode{
			set nearestNodeInclination to nearestNodeInclination *-1.
		}
		
		//if the ship *was* in the target orbital plane (ISWITP), what would our longitudinal distance to the *NEAREST* node (either ascending or decending) be at our current latitude?
		declare local longitudinalOffsetFromNearestNodeISWITP to arcSin(clamp(tan(shipPos:lat)/tan(nearestNodeInclination),-1,1)).

		//now that we know the distance to the nearest node, we can compute the distance to the ascending node.
		//if the nearrest node IS the ascending node... then we did it.
		set longitudinalOffsetFromLocalLanISWITP to longitudinalOffsetFromNearestNodeISWITP.
		if closerToDecendingNode{
			//if we're closer to the decending node, we need to flip it
			set longitudinalOffsetFromLocalLanISWITP to convertAngleToNavScale(addDegrees(longitudinalOffsetFromLocalLanISWITP,180)).
		}
	}

	//how far away from the LAN are we right now?
	declare local realDistanceFromLAN to signedLongitudinalDifference(shipPos:lng, targetLocalTrigLan).

	//now we subtract the two...
	declare local result to realDistanceFromLAN - longitudinalOffsetFromLocalLanISWITP.

	//and make sure that it's a value between -180 and +180
	set result to convertAngleToNavScale(result).

	return result.
}

//DEPRECIATED. im keeping this for now since i know this function works properly.
//Given a target orbital plane, pretend the ship is dragged east or west such that it intersects that orbital plane.
//The ship's latitude stays the same. Only the longitude is changed.
//At the ship's new imaginary location, how far east or west would the ship be from that target orbit's local LAN?
//The local LAN of an orbit is the longitude where the orbit's plane intersects it's parent planet's equator. this constantly changes as the parent planet rotates
//since there are always two possible answers to that question, we will use the answer that is closest to the ship's actual longitude.
function getLongitudinalOffsetFromLocalLanISWITP{
	parameter targetOrbit.

	//first lets grab our ship's current position
	declare local shipPos to ship:geoposition.

	//next, grab the target orbit's local LAN
	declare local targetLocalTrigLan to getLocalTrigLanOfOrbit(targetOrbit).

	//determine if we are closer to the ascending or decending node of the target orbit
	declare local closerToDecendingNode to abs(signedLongitudinalDifference(ship:geoposition:lng,targetLocalTrigLan)) > 90.

	//next, find the inclination of the nearest node, either ascending or decending
	declare local nearestNodeInclination to targetOrbit:inclination.
	if closerToDecendingNode{
		set nearestNodeInclination to nearestNodeInclination *-1.
	}

	//if the ship *was* in the target orbital plane (ISWITP), what would our longitudinal distance to the nearest node (either ascending or decending) be at our current latitude?
	//since there are always two possible answers to that question, we will use the answer that is closest to the ship's actual longitude.
	declare local longitudinalOffsetFromNearestNodeISWITP to arcSin(clamp(tan(shipPos:lat)/tan(nearestNodeInclination),-1,1)).

	//now that we know the distance to the nearest node, we can compute the distance to the ascending node.
	//if the nearrest node IS the ascending node... then we did it.
	declare local longitudinalOffsetFromLocalLanISWITP to longitudinalOffsetFromNearestNodeISWITP.
	if closerToDecendingNode{
		//if we're closer to the decending node, we need to flip it
		set longitudinalOffsetFromLocalLanISWITP to convertAngleToNavScale(addDegrees(longitudinalOffsetFromLocalLanISWITP,180)).
	}
	return longitudinalOffsetFromLocalLanISWITP.
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

