@lazyGlobal off.

//given a ship, return it's current horizontal orbital vector 
function getHorizontalOrbitalVector{
	parameter theShip to ship.
	return vectorExclude(theShip:up:vector,theShip:velocity:orbit).
}

//given a ship, return it's current vertical orbital vector 
function getVerticalOrbitalVector{
	parameter theShip to ship.
	return vectorExclude(getHorizontalOrbitalVector(theShip),theShip:velocity:orbit).
}

//given a ship, return it's current pitch angle to the horizon.
function getCurrentPitchAngle{
	parameter theShip to ship.
	return 90-vang(theShip:facing:vector,theShip:up:vector).
}