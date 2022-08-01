//@lazyGlobal off.

//#include "utils/orbitTools.ks"

//given a ship - at it's current location in its (sub)orbital flight -  what pitch is required
//to maintain a constant altitude at maximum engine thrust?
function calculateConstantAltitudeBurnPitch{
	parameter theShip to ship.

	//how far away is the ship from the center of the thing it is orbiting?
	declare local radius to theShip:altitude + theShip:orbit:body:radius.

	//what is the acceleration due to gravity at our current altitude?
	declare local gravitationalAcceleration to theShip:body:mu/(radius^2).

	//what is the apparent acceleration due to the centrifugal force at it's current orbital location
	declare local centrifugalAcceleration to ((getHorizontalOrbitalVector(theShip):mag/radius)^2)*radius.
}