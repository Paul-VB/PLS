@lazyGlobal off.

//given a deltaV target, how long will it take a ship - with it's current stages and fuel - to burn the engines to get that amount of deltaV
function calculateEngineBurnTime{
	parameter targetDeltaV, theShip to ship.
	
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
		//How much deltaV does the current stage have to expend?
		declare local currentStageDeltaVMax to theShip:stagedeltav(currStageIndex):vacuum.

		//how much deltaV does the current stage *need* to expend?
		//If the current stage enough to finish off our deltaVRemaining, then we just need to spend deltaVRemaining.
		//otherwise, we need to use this whole stage
		declare local currentStageDeltaVRequirement to min(currentStageDeltaVMax,deltaVRemaining).

		declare local averageVacISP to 0.
		declare local massInital to 0.
		declare local massFinal to 0.


		//how long will this stage burn for at max thrust?
		declare local stageBurnTime to 0.{
			//We only need to calculate the burn time for stages that actually have deltaV
			if currentStageDeltaVMax > 0 {


				//get a list of all engines in this stage
				declare local engines to getAllEnginesByStageNumber(currStageIndex).

				//get the average ISP vac of this stage
				set averageVacISP to averageVacISPMultipleEngines(engines).

				//get the initital mass of this stage
				set massInital to cumulativeStageMasses[currStageIndex].

				//knowing how much DeltaV we have left to achieve, we can use some fun math to compute the weight of the fuel we need to burn
				//this insane formula is derived from the ideal rocket equation.
				set massFinal to massInital/(constant:e^(currentStageDeltaVRequirement/(averageVacISP*constant:g0))).
				declare local weightOfFuelBurned to massInital-massFinal.

				//we also need the sum of all the mass flows of the engines in this stage
				declare local sumOfMassFlows to 0.
				for engine in engines{
					set sumOfMassFlows to sumOfMassFlows + engine:maxmassflow.
				}

				//now that we know how much fuel will be burned, we can take the sum of the fuel burn rates of all engines in this stage and get the time it takes to burn that fuel
				set stageBurnTime to weightOfFuelBurned/sumOfMassFlows.
			}
		}

		//add that time to our total
		set burnTimeTotal to burnTimeTotal + stageBurnTime.

		//now subtract the deltaV that this stage will expend from deltaVRemaining
		set deltaVRemaining to deltaVRemaining - currentStageDeltaVRequirement.

		declare local lineToStartPrinting to 36.
		declare local currLineToPrint to lineToStartPrinting+currStageIndex.
		//print("for stage number: "+currStageIndex+",engine ISP = "+round(averageVacISP,1):toString+" InitialMass = "+round(massInital,1):toString+", finalMass = "+round(massFinal,1):toString+", DeltaV(built in) = "+round(theShip:stageDeltaV(currStageIndex):vacuum,0):toString+" BurnTime = "+round(stageBurnTime,2):toString+"s. ") at (0,currLineToPrint).
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

	//loop through each part and add its mass to its stage's current runningTotal
	declare local allParts to list().
	list parts IN allParts.
	for part in allParts{
		declare local currPartStage to part:stage+1.//we add 1 here because the stage numbering is dum
		if not masses:haskey(currPartStage){
			masses:add(currPartStage,0).
		}
		set masses[currPartStage] to masses[currPartStage] + part:mass.
	}

	//now loop through the masses, and add the upper stage masses to the lower stage masses
	FROM {local currStageIndex is 1.} UNTIL currStageIndex = numberOfStages+1 STEP {set currStageIndex to currStageIndex+1.} DO {
			set masses[currStageIndex] to masses[currStageIndex] + masses[currStageIndex-1].
	}
	return masses.
}

// //given a list of parts, return all the engines in that list
// function getAllEnginesInListOfParts{
// 	parameter parts.

// 	declare local engines to list().
// 	for part in parts{
// 		if (part:hassuffix("thrust")){
// 			engines:add(part).
// 		}
// 	}
// 	return engines.
// }

// //given a list of parts, returns all the parts that contain 

// //given a list of parts, return the sum of their current masses
// function sumOfMasses{
// 	parameter parts.
// 	declare local result to 0.
// 	for part in parts{
// 		set result to result + part:mass.
// 	}
// 	return result.

// }

// //given a list of parts, return the sum of their empty (without fuel) masses
// function sumOfDryMasses{
// 	parameter parts.
// 	declare local result to 0.
// 	for part in parts{
// 		set result to result + part:dryMass.
// 	}
// 	return result.
// }

// //returns a lexicon of all the parts in a ship.
// //the key of the lexicon being the stage number that part is associated with.
// //the value is a list of parts in that stage
// function getLexiconOfPartsByStageNumber{
// 	parameter theShip to ship.

// 	declare local partsLexicon to initializeLexiconOfEmptyListsByStageNumber(theShip).

// 	//loop over every part in the ship and add it to it's
// 	for part in theShip:parts{
// 		declare local currPartStage to part:stage+1.//we add 1 here because the stage numbering is dum
// 		if not partsLexicon:haskey(currPartStage){
// 			partsLexicon:add(currPartStage,list()).
// 		}
// 		partsLexicon[currPartStage]:add(part).
// 	}
// 	return partsLexicon.	
// }

// //given a lexicon of parts by stage number, returns a lexicon of equal length that holds the mass of each stage
// function getLexiconOfPartMassesByStageNumber{
// 	parameter partsLexicon.

// 	declare local masses to lexicon().
// 	//loop over the stage in the lexicon of parts and sum the masses of those parts.
// 	for currStageKey in partsLexicon:keys{
// 		masses:add(currStageKey,list()).
// 		set masses[currStageKey] to sumOfMasses(partsLexicon[currStageKey]).
// 	}
// 	return masses.
// }

// //returns a lexicon of stage numbers and lists.
// //the keys are the numbers of all the stages in a ship.
// //the values are just empty lists. 
// //these lists are meant to hold different types of parts in a ship (i.e. engines, fuel tanks, all parts in general, etc.)
// //this design pattern (a lexicon of parts by stage number) is only here to increase performance. 
// //Looping over every single part in a ship to is computationally expensive, so the idea is to just loop over the parts once and cache the result.
// function initializeLexiconOfEmptyListsByStageNumber{
// 	parameter theShip to ship.

// 	declare local partsLexicon to lexicon().

// 	//get the number of stages remaining
// 	declare local numberOfStages to theShip:stageNum.

// 	//initialize the lexicon's keys
// 	FROM {local currStageIndex is numberOfStages.} UNTIL (currStageIndex) STEP {set currStageIndex to currStageIndex-1.} DO {
// 		partsLexicon:add(currStageIndex,list()).
// 	}
// 	return partsLexicon.
// }