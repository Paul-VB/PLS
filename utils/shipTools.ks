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

//this function is meant to be run in a loop. 
//It is similar to 'lock steering to ...', but the difference here is that
//it allows the player to take over manual control at any point
//the parameter steeringDirectionDelegate MUST be a delegate/anonymous function that returns a direction object
function lockSteeringToWithManualOverride{
	parameter steeringDirectionDelegate.
	//check if steering should be unlocked
	if (SAS){
		//the player can turn on SAS at any time to disengage the autopilot
		print("WARNING!! SAS mode is on, autopilot disengaged             ") at (0,0).
		unlock steering.
		unlock throttle.
	}
	else if(isPlayerTryingToSteer()) {
		//the player can turn on SAS at any time to disengage the autopilot
		print("WARNING!! Manual pilot input detected. autopilot disengaged") at (0,0).
		unlock steering.
		unlock throttle.
	}
	else {
		//we know we should be steering. Next check if we currently *are* steering
		if (not steeringManager:enabled){
			lock steering to steeringDirectionDelegate:call().
		}
		print("Autopilot active.                                          ") at (0,0).
	}
}

//checks whether or not the ship is landed or prelaunch
function isShipLanded{
	parameter shipToCheck is ship.
	declare local listOfAcceptableShipStatuses to list("PRELAUNCH","LANDED").
	return not(listOfAcceptableShipStatuses:indexOf(shipToCheck:status) = -1).
}

//returns whether or not the player is trying to take over manual control by pressing WASDQE
//Does not check the throttle position at all.
function isPlayerTryingToSteer{
	return SHIP:CONTROL:PILOTROTATION <> v(0,0,0).
}

//this function returns the height of the tallest launch clamp of a ship. 
//this is useful to know when we have cleared all launch clamps, and can begin the roll program safely.
//If there are no launch clamps, then 0 is returned.
function getLaunchTowerMaxHeight{
	declare local maxLaunchClampHeight to 0.
	//a list of all known launch clamp names to look for
	declare local ListOfKnownLaunchClampNames to list("TT18-A Launch Stability Enhancer").

	//loop over each part on the ship
	for currPart in ship:parts{

		//if we find a launch clamp...
		if (ListOfKnownLaunchClampNames:indexOf(currPart:title) <> -1){
			//...find the height of that launch clamp.
			declare local PartBounds to currPart:bounds.
			declare local currLaunchClampHeight to PartBounds:size:mag.

			//and set the maxLaunchClampHeight
			set maxLaunchClampHeight to max(maxLaunchClampHeight,currLaunchClampHeight).
		}
	}
	return maxLaunchClampHeight.
}