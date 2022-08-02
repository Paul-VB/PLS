@lazyGlobal off.
clearScreen.

//"import" statements
// #include "utils/orbitTools.ks"
// #include "ApoLaunchPitchProgram.ks"
// #include "azCalc.ks"
// #include "launchWindowCalc.ks"
// #include "constantAltitudeBurnCalc.ks"
// #include "gui/parkingOrbit.ks"
// #include "gui/hudStuff.ks"
// #include "gui/warpPrompt.ks"
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

	print("-").
	print("Parking Orbit Summary: ").
	print("Parking Orbit Altitude: "+parkingOrbit:periapsis).
	print("Parking Orbit Inclination: "+parkingOrbit:inclination).
	print("Parking Orbit LAN: "+parkingOrbit:LAN).

	//next, lets define the launchPhases, aka runmodes.
	declare local launchPhases to list().
	launchPhases:add("clearTheTower").
	launchPhases:add("rollProgram").
	launchPhases:add("mainAscent").
	launchPhases:add("coastToApoapsis").
	launchPhases:add("circularize").
	launchPhases:add("done").

	//should we warp to the launch window?
	if confirmWarpToLaunchWindow(){
		//how long we want the countdown to be
		declare local countdownTime to 10.

		//how much leeway (in seconds) we want to have for checking if now is a launch window
		declare local launchWindowLeeway to 1.

		//are we close to the launch window time?
		local lock timeRemainingUntilLaunch to time:seconds - nextLaunchWindowTimestamp:seconds.
		
		//now we just need to wait until the next launch window, or dont wait if we're already in the air
		warpTo(nextLaunchWindowTimestamp:seconds - countdownTime).
		hudPrint0("Warping to launch time: "+timestamp(nextLaunchWindowTimestamp:seconds - countdownTime):full, countdownTime).
		until(timeRemainingUntilLaunch*-1 <= countdownTime or not isShipLanded()){
			wait 1.
		}
		//count down until liftoff, or dont if we're already in the air
		declare local timeStep to 1.
		until((0<timeRemainingUntilLaunch and timeRemainingUntilLaunch < launchWindowLeeway)or not isShipLanded()){
			hudPrint0("T"+round(timeRemainingUntilLaunch,0),timeStep).
			wait timeStep.
		}
	}

	//things that must happen immediately upon launch
	//turn SAS off. There is a known bug in KOS with SAS and cooked controls
	SAS off.
	//set throttle to max.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
	//lets light this candle!
	autoStage().
	print("Liftoff!").
	

	//the index of the current launch phase we are in
	declare local currLaunchPhaseIndex to 0.

	//the launch loop
	until launchPhases[currLaunchPhaseIndex] = "done"{


		//clear the tower
		if launchPhases[currLaunchPhaseIndex] = "clearTheTower"{
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
				lockSteeringToWithManualOverride({return heading(calculateThrustHeading(parkingOrbit,calculateSpeedRequiredForApoapsis(parkingOrbit:apoapsis)),calculateCurrentRequiredPitchAngle(parkingOrbit)).}).
			}
			UNLOCK STEERING.
			print("Main Ascent complete.").	
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

		//coast to apoapsis
		else if launchPhases[currLaunchPhaseIndex] = "coastToApoapsis"{
			//set throttle to 0.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
			//we need to unlock steering before we begin coasting. Steering may have been locked by a previous launch phase.
			//if it's already locked then the steering will not be updated due to the code that allows the player to take over control at any time.
			unlock steering.
			//coast prograde
			lock steering to prograde.

			//now lets figure out the circularization burn. 
			//technically this variable isn't really needed anymore, but i'll keep it cuz its fun to see the estimated burn duration
			//this is a 'lock' because it is to be continually recomputed.
			local lock circularizationBurnDuration to calculateEngineBurnTime(calculateApoapsisCircularizationDeltaV(ship:orbit)).

			//keep coasting until we pass apoapsis
			until (180<=ship:orbit:trueanomaly and ship:orbit:trueanomaly < 360){
				print ("circularization Burn Duration: "+round(circularizationBurnDuration,2):toString) at (0,26).
				print ("time Remaining until Circularization: "+round(ship:orbit:eta:apoapsis,2):toString) at (0,27).
				lockSteeringToWithManualOverride({return prograde.}).
			}
			UNLOCK STEERING.
			print("Coasting complete.").
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

		//circularize
		else if launchPhases[currLaunchPhaseIndex] = "circularize"{ 
			UNLOCK STEERING.
			
			print("Starting Circularization Burn.").
			//full throttle.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 1.
			//how do we know if we're "done" with the Circularization Burn? when our periapsis whips around and changes places with the apoapsis
			until (ship:orbit:trueanomaly<=90 or 270<=ship:orbit:trueanomaly){
				//check staging
				autoStage().
				lockSteeringToWithManualOverride({return heading(calculateCurrentProgradeCompassHeading(),calculateConstantAltitudeBurnPitch()).}).
			}
			//set throttle to 0.
			SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
			print("Circularization complete.").
			UNLOCK STEERING.
			UNLOCK THROTTLE.
			set currLaunchPhaseIndex to currLaunchPhaseIndex +1.
		}

	}
}

//the mighty apo turn! used to calculate pitch
//this is separated out to make it a little easier to switch pitch algorithms.
function calculateCurrentRequiredPitchAngle{
	parameter targetOrbit.
	return calculatePitchAngle(targetOrbit).
}






