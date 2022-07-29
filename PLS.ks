@lazyGlobal off.
clearScreen.

//"import" statements
// #include "utils/orbitTools.ks"
// #include "ApoLaunchPitchProgram.ks"
// #include "azCalc.ks"
// #include "launchWindowCalc.ks"
// #include "gui/parkingOrbit.ks"
// #include "gui/hudStuff.ks"
// #include "engineBurnTimeCalc.ks"
// #include "utils/autoStage.ks"
runOncePath("PLS/init.ks").


Main().


function Main{
	//next, lets grab our launch co-ordinates as we will need them later.
	declare local LaunchPosition to ship:geoposition.
	//and grab the launch altitude. we will need this later
	declare local LaunchAltitude to ship:altitude.

	//first, ask the user to enter stats for the parking orbit.
	declare local parkingOrbit to promptUserForParkingOrbit().
	//lets redefine our parking orbit to an orbit we can actually physically reach. we'll need this incase our target orbit's inclination is below our launch lattitude.
	set parkingOrbit to calculateParkingOrbit(parkingOrbit,LaunchPosition).

	//next, lets declare the target velocity we want be at when we match our orbital plane with the target plane.
	//Its basically how fast we should be going once we've killed our normal velocity
	declare local planeMatchVelocity to calculateSpeedRequiredForApoapsis(parkingOrbit:apoapsis).

	//next, find out how long it will take to acheve plane match velocity. 
	//Basically how long after launch will our orbital plane be lined up with the target orbital plane
	//if there will be no coast phase before we match planes, then this can be calculated right from planeMatchVelocity with the ideal rocket equasion

	//TODO: this should use the difference between our starting velocity and planeMatchVelocity
	declare local launchDuration to calculateEngineBurnTime(planeMatchVelocity).

	//next, we need to find out when the next launch window is.
	declare local nextLaunchWindowTimestamp to calculateNextLaunchWindow(parkingOrbit,launchDuration).

	//next, lets get the height of the launch tower (the tallest launch clamp)
	declare local towerHeight to getLaunchTowerMaxHeight().

	print("Parking Orbit Summary: ").
	print("Parking Orbit Altitude: "+parkingOrbit:periapsis).
	print("Parking Orbit Inclination: "+parkingOrbit:inclination).
	print("Parking Orbit LAN: "+parkingOrbit:LAN).

	//next, lets define the launchPhases, aka runmodes.
	declare local launchPhases to list().
	launchPhases:add("countdown").
	launchPhases:add("clearTheTower").
	launchPhases:add("rollProgram").
	launchPhases:add("mainAscent").
	launchPhases:add("coastAndCircularize").
	launchPhases:add("done").

	//how long we want the countdown to be
	declare local countdownTime to 10.

	//how much leeway (in seconds) we want to have for checking if now is a launch window
	declare local launchWindowLeeway to 1.

	//are we close to the launch window time?
	local lock timeRemaining to time:seconds - nextLaunchWindowTimestamp:seconds.
	
	//now we just need to wait until the next launch window
	warpTo(nextLaunchWindowTimestamp:seconds - countdownTime).
	hudPrint0("Warping to launch time: "+timestamp(nextLaunchWindowTimestamp:seconds - countdownTime):full, countdownTime).
	until(timeRemaining*-1 <= countdownTime){
		wait 1.
	}

	//the index of the current launch phase we are in
	declare local currLaunchPhaseIndex to 0.

	//the launch loop
	until launchPhases[currLaunchPhaseIndex] = "done"{

		//count down until liftoff
		if launchPhases[currLaunchPhaseIndex] = "countdown"{
			declare local timeStep to 1.
			until(0<timeRemaining and timeRemaining < launchWindowLeeway){
				hudPrint0("T"+round(timeRemaining,0),timeStep).
				wait timeStep.
			}
			//things that must happen immediately upon launch
			//turn SAS off. There is a known bug in KOS with SAS and cooked controls
			SAS off.
			//set throttle to max.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
			//lets light this candle!
			autoStage().
			print("Liftoff!").
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}		

		//clear the tower
		else if launchPhases[currLaunchPhaseIndex] = "clearTheTower"{
			//do we even have a tower to clear?
			declare local towerExists to towerHeight <> 0.
			if towerExists{
				declare local towerIsClear to false.
				//launch straight up with no roll until we clear the tower
				declare local initialFacingRoll to ship:facing:roll.
				lock steering to up + r(0,0,initialFacingRoll).
				until(towerIsClear){
					//keep checking if we have cleared the tower
					set towerIsClear to ship:altitude - LaunchAltitude > towerHeight.
				}
				print("tower clear").
			}
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

		//roll program
		else if launchPhases[currLaunchPhaseIndex] = "rollProgram"{
			print("starting roll program...").
			declare local rollComplete to false.
			declare local maxRollErrorAngle to 1.
			declare local initialAzimuth to calculateThrustHeading(parkingOrbit,planeMatchVelocity).
			lock steering to heading(initialAzimuth,90).
			until(rollComplete){
				//see if we have rolled enough
				declare local currentRollErrorAngle to abs(initialAzimuth - ship:facing:roll)-180.
				if currentRollErrorAngle<=maxRollErrorAngle {
					set rollComplete to true.
				}
			}
			print("Roll complete.").	
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

		//main Ascent
		else if launchPhases[currLaunchPhaseIndex] = "mainAscent"{
			//we need to unlock steering before we begin our main ascent. Steering may have been locked by a previous launch phase.
			//if it's already locked then the steering will not be updated due to the code that allows the player to take over control at any time.
			unlock steering.
			//keep firing until our current apoapsis meets our target
			until (ship:orbit:apoapsis >= parkingOrbit:apoapsis){
				//check staging
				autoStage().
				//check if steering should be unlocked
				if (SAS or isPlayerTryingToSteer()){
					//the player can turn on SAS at any time to disengage the autopilot
					print("WARNING!! SAS mode is on, or player is trying to manually steer. autopilot disengaged") at (0,0).
					UNLOCK STEERING.
					UNLOCK THROTTLE.
				} else {
					//we know we should be steering. Next check if we currently *are* steering
					if (not steeringManager:enabled){
						lock steering to heading(calculateThrustHeading(parkingOrbit,calculateSpeedRequiredForApoapsis(parkingOrbit:apoapsis)),calculateCurrentRequiredPitchAngle(parkingOrbit)).
					}
				}
			}
			UNLOCK STEERING.
			print("Main Ascent complete.").	
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

		//coast to apoapsis and Circularize
		else if launchPhases[currLaunchPhaseIndex] = "coastAndCircularize"{
			//set throttle to 0.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
			//we need to unlock steering before we begin coasting. Steering may have been locked by a previous launch phase.
			//if it's already locked then the steering will not be updated due to the code that allows the player to take over control at any time.
			unlock steering.
			// //keep coasting until it is time to make the circularization burn.... but when will that be? i'll get to that...
			// until (ship:orbit:apoapsis >= parkingOrbit:apoapsis){
			// 	//check staging
			// 	autoStage().
			// 	//check if steering should be unlocked
			// 	if (SAS or isPlayerTryingToSteer()){
			// 		//the player can turn on SAS at any time to disengage the autopilot
			// 		print("WARNING!! SAS mode is on, or player is trying to manually steer. autopilot disengaged") at (0,0).
			// 		UNLOCK STEERING.
			// 		UNLOCK THROTTLE.
			// 	} else {
			// 		//we know we should be steering. Next check if we currently *are* steering
			// 		if (not steeringManager:enabled){
			// 			lock steering to prograde.
			// 		}
			// 	}
			// }
			// UNLOCK STEERING.
			// print("Coasting complete.").	
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

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






