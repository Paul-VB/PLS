@lazyGlobal off.

//given two longitude degrees or two latitude degrees, add the two together
function addDegrees{
	parameter degreeA,degreeB.

	//put both degrees in trig scale
	set degreeA to convertAngleToTrigScale(degreeA).
	set degreeB to convertAngleToTrigScale(degreeB).
	declare local result to 0.

	//now add the two together
	set result to degreeA + degreeB.

	//then convert back to nav scale
	return convertAngleToNavScale(result).
}

//given two longitude degrees or two latitude degrees, subtract one from the other
function subtractDegrees{
	parameter degree1,degree2.
	set degree2 to degree2 * -1.
	return addDegrees(degree1,degree2).
}

// //given a starting longitude, determine how many degrees EAST you need to go to reach the end lattitude
// function FindEastLongitudinalDifference{
// 	parameter startLongitude, endLongitude.
// 	//make sure both values are in nav scale
// 	set startLongitude to convertAngleToNavScale(startLongitude).
// 	set endLongitude to convertAngleToNavScale(endLongitude).
// 	// do endLong - startLong 

// 	declare local result to endLongitude - startLongitude.

// 	//clamp the value between 0 and 360. if it's below 0, that means you would need to cross the 180 degree mark (opposite the prime meridian) to get to the end target
// 	set result to clampAngleBetween0and360(result).
// 	return result.
// }

// //given a starting longitude, determine how many degrees WEST you need to go to reach the end lattitude
// function FindWestLongitudinalDifference{
// 	parameter startLongitude, endLongitude.
// 	//make sure both values are in nav scale
// 	set startLongitude to convertAngleToNavScale(startLongitude).
// 	set endLongitude to convertAngleToNavScale(endLongitude).

// 	//do startLong - endLong 
// 	declare local result to startLongitude - endLongitude.

// 	//clamp the value between 0 and 360. if it's below 0, that means you would need to cross the 180 degree mark (opposite the prime meridian) to get to the end target
// 	set result to clampAngleBetween0and360(result).
// 	return result.
// }

// //Gets the angular separation between two longitudinal values
// function absoluteLongitudinalDifference{
// 	parameter longA,longB.
// 	return min(FindEastLongitudinalDifference(longA,longB),FindWestLongitudinalDifference(longA:longB)).
// }

//given two Longitudinal points (start/A, and End/B), how many degrees directly east or west is the shortest path from A to B?
//this function returns a positive value if A is east of B, and a negative value if A is west of B.
//(+) A is east of B if the shortest route from A to B is to walk west (left), even across the 180 degree mark (opposite the prime meridian)
//(-) A is west of B if the shortest route from A to B is to walk east (right), even across the 180 degree mark (opposite the prime meridian)
function signedLongitudinalDifference{
	parameter startLongitude, endLongitude.
	//lets try to convert the start and end to trig scale first
	set startLongitude to convertAngleToTrigScale(startLongitude).
	set endLongitude to convertAngleToTrigScale(endLongitude).

	declare local result to startLongitude - endLongitude.
	//then convert back to nav scale
	return convertAngleToNavScale(result).
}

//accepts an angle given in traditional trigonometric scale (usually 0 to +360, but this function can also accept values outside that range), 
//and converts it to "navigation" scale.
//i define nagivation scale as ranging from -180 to +180, but its not just a simple shift down by -180.
//between 0 and 180 degrees, navigation scale and trig angles are identical.
//between 180 and 360 degrees in trig scale, nav scale wraps around to -180 and goes up to 0.
//its bascially how longitude and lattitude work in real life 
function convertAngleToNavScale{
	parameter angle.
	//first, constrain the angle to between 0 and 360
	declare local result to clampAngleBetween0and360(angle).
	if result > 180 {
		set result to result - 360.
	}
	return result.
}
//accepts an angle between -180 and +180, like in real-world longitude and lattitude navigation,
//and converts it to normal trigonometric scale.
//i define trig scale as ranging from 0 to +360, but its not just a simple shift up by +180.
//between 0 and +180 nav scale and trig scale are identical.
//between -180 and 0 in nav scale, trig scale ranges from +180 to +360
function convertAngleToTrigScale{
	parameter angle.
	declare local result to angle.
	if result < 0 {
		set result to result + 360.
	}
	return result.
}

//given any trig scale angle, clamp it to between 0 and +360, but keeping it's rotation value the same
function clampAngleBetween0and360{
	parameter angle.
	return mod(angle+360,360).

}