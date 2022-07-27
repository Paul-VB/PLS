@lazyGlobal off.

//import statements
// #include "utils/orbitTools.ks"
// #include "utils/navigationDegreeTools.ks"
// #include "utils/extraMath.ks"

//Given a target orbit's inclination and a target velocity, calculate the required heading we must fire the engines at in order to 
//reach that desired orbital inclination and velocity at the same time. 
//this function takes into account the vessel's current prograde heading and velocity.
//tldr: current vector - target vector = thrust vector
function calculateThrustHeading{
	parameter targetOrbit,planeMatchVelocity.

	//lets grab our ship's current position
	declare local shipPos to ship:geoposition.

	//grab the ship's local lan in trig scale. we'll need it a few times
	declare local localTrigLan to getLocalTrigLanOfOrbit(ship:orbit).

	//grab the target orbit's current local lan
	declare local targetLocalTrigLan to getLocalTrigLanOfOrbit(targetOrbit).

	//calculate the heading of the target vector
	declare local targetHeading to 0.{

		//how far away from the LAN are we right now?
		declare local realDistanceFromLAN to signedLongitudinalDifference(shipPos:lng, targetLocalTrigLan).
		declare local longitudinalOffsetFromLocalTrigLanISWITP to convertAngleToNavScale(realDistanceFromLAN-longitudinalDistanceFromTargetOrbitalPlane(targetOrbit)).	
		print("old function for ISWITP gets: "+getLongitudinalOffsetFromLocalLanISWITP(targetOrbit)) at (0,30).	
		print("new function for ISWITP gets: "+longitudinalOffsetFromLocalTrigLanISWITP) at (0,31).	
		set targetHeading to calculateProgradeCompassHeading(longitudinalOffsetFromLocalTrigLanISWITP,ship:geoposition:lat).
	}
	//calculate the heading of the current vector
	declare local currentHeading to 0.
	{
		//grab the lan from our current (sub)orbit and find how how many logitudinal degrees left(-) or right(+) away from it the ship currently is
		declare local currentLanOffset to signedLongitudinalDifference(ship:geoposition:lng,localTrigLan).

		//and now calculate the heading
		set currentHeading to calculateProgradeCompassHeading(currentLanOffset,ship:geoposition:lat).
	}

	//calculate x and y components of target heading
	declare local targetX to planeMatchVelocity * sin(targetHeading).
	declare local targetY to planeMatchVelocity * cos(targetHeading).

	//calculate x and y components of current heading
	declare local currentVelocity to ship:orbit:velocity:orbit:mag.
	declare local currentX to currentVelocity * sin(currentHeading).
	declare local currentY to currentVelocity * cos(currentHeading).

	//compute current vector - target vector
	declare local thrustX to targetX - currentX.
	declare local thrustY to targetY - currentY.
	declare local thrustHeading to arcTan2(thrustX,thrustY).
	return thrustHeading.
}

//calculates what compass heading our prograde vector is at any given point in an orbit (or suborbital flight).
//we define the horizontal position of our ship in terms of distance from the ascending node. 
//the horizontal distance is a signed value. + for east, - for west
//we define the vertical position of our ship by just using it's current lattitude.
//this function calculates the heading using napier's rules for spherical right triangles.
//specificaly, the rule of tan(a) = tan(A)*sin(b)
//where A is the compassHeading or azimuth,
//a is the horizontal lognituddinal distance between the ship and the ascending node (localLAN)
//b is the ship's lattitude 
function calculateProgradeCompassHeading{
	parameter distanceFromLocalLan, shipLatt.
	declare local result to arcTan(tan(distanceFromLocalLan)/sin(shipLatt)).
	//if distanceFromLAN > 90, that means we need to correct for sign flips and such
	if abs(distanceFromLocalLan) > 90 {
		set result to result + 180.
	}
	set result to clampAngleBetween0and360(result).
	return result.
}
