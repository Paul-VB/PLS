@lazyGlobal off.
clearScreen.

//"import" statements
// #include "orbitTools.ks"
// #include "ApoLaunchPitchProgram.ks"
// #include "azCalc.ks"
// #include "gui/parkingOrbit.ks"
runOncePath("PLS/init.ks").


Main().


function Main{
	//next, lets grab our launch co-oridinates as we will need them later.
	declare local LaunchPosition to ship:geoposition.
	//and grab the launch altitude. we will need this later
	declare local LaunchAltitude to ship:altitude.

	//first, ask the user to enter stats for the parking orbit.
	declare local parkingOrbit to promptUserForParkingOrbit().
	//lets redefine our parking orbit to an orbit we can actually physically reach. we'll need this incase our target orbit's inclination is below our launch lattitude.
	set parkingOrbit to calculateParkingOrbit(parkingOrbit,LaunchPosition).

	//next, lets declare the target velocity we want be at when we match our orbital plane with the target plane.
	//Its basically how fast we should be going once we've killed our normal velocity
	declare local planeMatchVelocity to getOrbitalVelocityOfCircularOrbit(parkingOrbit).

	//next, find out how long it will take to acheve plane match. 
	//Basically how long after launch will our orbital plane be lined up with the target orbital plane
	//if there will be no coast phase before we match planes, then this can be calculated right from planeMatchVelocity with the ideal rocket equasion
	declare local planeMatchTime to 120.
	declare local planeMatchTimeStamp to timestamp() + timespan(planeMatchTime).


	//next, lets get the height of the launch tower (the tallest launch clamp)
	declare local towerHeight to getLaunchTowerMaxHeight().

	//now we wait until we have launched.
	print("waiting for liftoff...").
	// until (isShipLanded()){
	// 	//wait for it....
	// }
	print("Liftoff!").
	//launch phase 0: things that must happen immediatly upon launch
	{
		//turn SAS off. There is a known bug in KOS with SAS and cooked controls
		SAS off.
		//set throttle to max.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
	}

	//launch phase 1: clear the tower
	{
		declare local towerIsClear to false.
		//do we even have a tower to clear?
		if towerHeight = 0{
			//no tower to clear
			set towerIsClear to true.
		}
		//launch straight up with no roll until we clear the tower
		declare local initialFacingRoll to ship:facing:roll.
		lock steering to up + r(0,0,initialFacingRoll).
		until(towerIsClear){
			//keep checking if we have cleared the tower
			set towerIsClear to ship:altitude - LaunchAltitude > towerHeight.
		}
		print("tower clear").
	}
	
	//launch phase 2: roll program
	{
		print("starting roll program...").
		declare local rollComplete to false.
		declare local maxRollErrorAngle to 1.
		declare local initalAzimuth to calculateThrustHeading(parkingOrbit,planeMatchVelocity).
		lock steering to heading(initalAzimuth,90).
		until(rollComplete){
			//see if we have rolled enough
			declare local currentRollErrorAngle to abs(initalAzimuth - ship:facing:roll)-180.
			if currentRollErrorAngle<=maxRollErrorAngle {
				set rollComplete to true.
			}

		}
		print("Roll complete.").		
	}

	//launch phase 3: the main launch ascent
	{
		unlock steering.
		//keep firing until our current apoapsis meets our target
		until (ship:orbit:apoapsis >= parkingOrbit:apoapsis){
			//check if steering should be unlocked
			if (SAS or isPlayerTryingToSteer()){
				//the player can turn on SAS at any time to disengage the autopilot
				print("WARNING!! SAS mode is on, or player is trying to manually steer. autopilot disengaged") at (0,0).
				UNLOCK STEERING.
				UNLOCK THROTTLE.
			} else {
				//we know we should be steering. Next check if we currently *are* steering
				if (not steeringManager:enabled){
					lock steering to heading(calculateThrustHeading(parkingOrbit,planeMatchVelocity),calculateCurrentRequiredPitchAngle(parkingOrbit)).

				}
			}
		}
	}

	//launch phase 4: keep burning the engines a bit to counteract atmospheric drag
	{
		//set throttle to 0.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	}
}

//the mighty apo turn! used to calculate pitch
function calculateCurrentRequiredPitchAngle{
	parameter targetOrbit.
	return calculatePitchAngle(targetOrbit).

}
function isShipLanded{
	parameter shipToCheck is ship.
	declare local listOfAcceptableShipStatuses to list("PRELAUNCH","LANDED").
	return (listOfAcceptableShipStatuses:indexof(shipToCheck:status) = -1).
	}

//returns whether or not the player is trying to take over manual control by pressing WASDQE
//Does not check the throttle position at all.
function isPlayerTryingToSteer{
	return SHIP:CONTROL:PILOTROTATION <> v(0,0,0).
}

//this function returns the height of the tallest launch clamp. 
//this is useful to know when we have cleared all launch clamps, and can begin the roll program safely.
//If there are no launch clamps, then 0 is returned.
function getLaunchTowerMaxHeight{
	declare local maxLaunchClampHeight to 0.
	//a list of all known launch clamp names to look for
	declare local ListOfKnownLaunchClampNames to list("TT18-A Launch Stability Enhancer").

	//loop over each part on the ship
	for currPart in ship:parts{

		//if we find a launch clamp...
		if (ListOfKnownLaunchClampNames:indexof(currPart:title) <> -1){
			//...find the height of that launch clamp.
			declare local PartBounds to currPart:bounds.
			declare local currLaunchClampHeight to PartBounds:size:mag.

			//and set the maxLaunchClampHeight
			set maxLaunchClampHeight to max(maxLaunchClampHeight,currLaunchClampHeight).
		}
	}
	return maxLaunchClampHeight.
}





