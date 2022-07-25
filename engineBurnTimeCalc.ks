@lazyGlobal off.

//given a deltaV target, how long will it take this ship - with it's current stages and fuel - to burn the engines to get that amount of deltaV
function calculateEngineBurnTime{
	parameter targetDeltaV.
	
	declare local burnTimeTotal to 0.

	//we'll go through each stage 1 at a time. 
	//if a given stage does not have enough deltaV on it's own to meet our deltaV target, 
	//then we know we will need to use that entire stage, plus additional stage(es). 
	//we'll keep track of how much deltaV we still have left to achieve after we use a given stage
	declare local deltaVRemaining to targetDeltaV.

	//get the number of stages remaining
	declare local numberOfStages to ship:stagenum.

	//the cumulative masses of each stage
	declare local cumulativeStageMasses to calculateStageMassesCumulatively().

	//get the delta V for each stage
	FROM {local currStageIndex is numberOfStages.} UNTIL (currStageIndex = -1 or deltaVRemaining <= 0) STEP {set currStageIndex to currStageIndex-1.} DO {
		//is the current stage enough to finish off our deltaVremaining?
		declare local currentStageDeltaV to ship:stagedeltav(currStageIndex):vacuum.
		if (currentStageDeltaV > deltaVRemaining){
			//if we get here, we know that we'll only need to use PART of the current stage. exactly how much..? MATH
			//get a list of all engines in this stage
			declare local engines to getAllEnginesByStageNumber(currStageIndex).

			//get the average ISP vac of this stage
			declare local averageVacISP to averageVacISPMultipleEngines(engines).

			//get the iniital mass of this stage
			declare local massInital to cumulativeStageMasses[currStageIndex].

			//knowing how much DeltaV we have left to achieve, we can use some fun math to compute the weight of the fuel we need to burn
			//this insane formula is derived from the ideal rocket equasion.
			declare local massFinal to massInital/(constant:e^(deltaVRemaining/(averageVacISP*constant:g0))).
			declare local weightOfFuelBurned to massInital-massFinal.

			//we also need the sum of all the mass flows of the engines in this stage
			declare local sumOfMassFlows to 0.
			for engine in engines{
				set sumOfMassFlows to sumOfMassFlows + engine:maxmassflow.
			}

			//now that we know how much fuel will be burned, we can take the sum of the fuel burn rates of all engines in this stage and get the time it takes to burn that fuel
			declare local stageBurnTime to weightOfFuelBurned/sumOfMassFlows.

			//and add that time to our total
			set burnTimeTotal to burnTimeTotal + stageBurnTime.

		} else {
			//we know we'll need to use this whole stage.
			set burnTimeTotal to burnTimeTotal + ship:stagedeltav(currStageIndex):duration.	
		}
		set deltaVRemaining to deltaVRemaining - currentStageDeltaV.
	}
	return burnTimeTotal.
}

//given a stage number, return a list of all the engines in that stage
function getAllEnginesByStageNumber{
	parameter stageNum.
	declare local stageEngines to list().
	declare local allEngines to list().
	LIST ENGINES IN allEngines.
	for engine in allEngines{
		if (engine:stage = stageNum)
			stageEngines:add(engine).
	}
	return stageEngines.
}

//given a list of engines, compute the combined average specific impulse if all the engines were firing at max throttle in a vacuum.
function averageVacISPMultipleEngines{
	parameter engines.

	declare local runningTotalOfThrustDividedByISP to 0.
	declare local runningTotalOfMaxThrust to 0.
	for currEngine in engines{
		//save the initial activated state of the engine
		declare local thrust to currEngine:possibleThrustAt(0).
		set runningTotalOfThrustDividedByISP to runningTotalOfThrustDividedByISP + (thrust/currEngine:visp).
		set runningTotalOfMaxThrust to runningTotalOfMaxThrust + thrust.
	}
	//this is here to prevent divideBy0 errors
	declare local result to 1.
	if not runningTotalOfThrustDividedByISP = 0 {
		set result to runningTotalOfMaxThrust/runningTotalOfThrustDividedByISP.
	}
	return result.
}

//returns a lexicon of masses of each stage. the key of the lexicon corresponds to the stage number it represents.
function calculateStageMassesCumulatively{
	declare local masses to lexicon().

	//init the massesLexicon
	declare local numberOfStages to ship:stageNum.
	FROM {local currStageIndex is numberOfStages.} UNTIL currStageIndex = -1 STEP {set currStageIndex to currStageIndex-1.} DO {
		if not masses:haskey(currStageIndex){
			masses:add(currStageIndex,0).
		}
	}

	//loop through each part and add its mass to its stage's current runningTotal
	declare local allParts to list().
	list parts IN allParts.
	for part in allParts{
		declare local currPartStage to part:stage+1.//we add 1 here because the stage numbering is dum
		set masses[currPartStage] to masses[currPartStage] + part:mass.
	}

	//now loop through the masses, and add the upper stage masses to the lower stage masses
	FROM {local currStageIndex is 1.} UNTIL currStageIndex = numberOfStages+1 STEP {set currStageIndex to currStageIndex+1.} DO {
			set masses[currStageIndex] to masses[currStageIndex] + masses[currStageIndex-1].
	}
	return masses.
}