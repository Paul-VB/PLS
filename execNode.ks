@lazyGlobal off.

//import statements
// #include "utils/orbitTools.ks"
// #include "utils/navigationDegreeTools.ks"
// #include "utils/extraMath.ks"
// #include "utils/shipTools.ks"
// #include "gui/warpPrompt.ks"
// #include "engineBurnTimeCalc.ks"

runOncePath("PLS/init.ks").

Main().

function Main{
	executeNextNode().
}

//executes the next maneuver node
function executeNextNode{
	//first make sure we even have a maneuver node
	if hasNode {
		executeNode(nextNode).
	} else {
		print("No Maneuver Node to execute!").
	}
}

//warps to and executes a given maneuver node
function executeNode{
	parameter node.

	//set throttle to 0.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

	//aim the ship at the next node
	lock steering to node.

	//figure out how long it will take this ship to burn half the deltaV in the node
	declare local halfBurnTime to calculateEngineBurnTime(node:deltav:mag/2).

	//when we should start burning
	declare local burnStartTimeStamp to timestamp(node:time - halfBurnTime).



	//next warp to the start of the burn
	warpToWithCountdown(burnStartTimeStamp,"warping to next maneuver node: ").

	//how long until we should stop burning?
	declare local lock burnTimeRemaining to calculateEngineBurnTime(node:deltav:mag).

	//keep track of the lowest deltaV remaining on the burn. 
	//This way if we have a very low TWR ship that makes large maneuver nodes inacurate, we can avoid situations where we get "pretty close"
	//to finishing off the burn, but then the DV remainign starts creeping up
	declare local smallestDeltaVRemaining to node:deltav:mag.

	//whether or not we should keep burning the engines for this node.
	function shouldKeepBurning{
		set smallestDeltaVRemaining to min(smallestDeltaVRemaining,node:deltav:mag).
		return (node:deltav:mag > 0.001) and (node:deltav:mag <= smallestDeltaVRemaining).
	}

	unlock steering.

	//start the burn
	until (not shouldKeepBurning()){
		lockSteeringToWithManualOverride({return node.}).

		//use the time remaining on the burn to set the throttle. 
		//If time remaining is more than 1 second, then we use full throttle.
		//if burn time is less than 1 second, then we'll creep up on the end of the burn.
		SET SHIP:CONTROL:PILOTMAINTHROTTLE TO max(burnTimeRemaining,0.05).
	}

	//set throttle to 0.
	SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
	unlock steering.
}