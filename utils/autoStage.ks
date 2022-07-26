@lazyGlobal off.

//automatically stages the ship if necessary
function autoStage{
	if stage:ready and shouldStage() {
		stage.
	}
}

//determines whether or not we should stage
function shouldStage{
	//first, check if we even have any active engines. If we don't, we should stage.
	if ship:maxthrust = 0 {
		return true.
	} 

	declare local result to false.
	//we know we have some active engines.
	declare local allEngines to list().
	LIST ENGINES IN allEngines. 
	//check every engine
	for currEngine in allEngines{
		//check if the current engine is active and flamed out. If so, its probably outtaGas
		if currEngine:ignition and currEngine:flameOut {
			//whether or not the current engine is out of fuel. this is separated out to account for multi-mode engines like the rapier
			declare local outtaGas to false.
			if currEngine:multiMode {
				//the engine is multimode. check if we can re-ignite by changing modes
			} else {
				//the engine is NOT multimode. it must be outtaGas
				set outtaGas to true.
			}
			if outtaGas {
				set result to true.
				break.
			}
		}
	}
	return result.
}
