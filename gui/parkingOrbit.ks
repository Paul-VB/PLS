@lazyGlobal off.

// #include "guiSkin.ks"
// #include "../utils/navigationDegreeTools.ks"

//the numeric backing variables
declare local orbitAltitude to 0.
declare local inclination to 0.
declare local LAN to 0.

//displayes and prompts the user to enter the parking orbit parameters
function promptUserForParkingOrbit{
	//define the gui window
	declare local window to gui(600).
	set window:skin to getSkin().
	declare local headerBox to window:addHBox().
	declare local titleLabel to headerBox:addLabel("Paul's Launch Script").

	declare local bodyBox to window:addvbox().
	{
		declare local subTitleLabel to bodyBox:addlabel("Please specify parking orbit parameters.").
		declare local bodyRow0 to bodyBox:addhbox().{
			addNumberFieldWidget(bodyRow0,"Altitude",setAltitude@).
			addNumberFieldWidget(bodyRow0,"Inclination",setInclination@).
			addNumberFieldWidget(bodyRow0,"LAN",setLAN@).
		}
		declare local finishedButton to bodyBox:addbutton("Finished").
		set finishedButton:onclick to finish@.
	}
	window:SHOW().

	//until we are done entering data, wait
	declare local finished to false.
	function finish{
		set finished to true.
	}
	until finished{
		wait 0.
	}
	window:hide().
	declare local parkingOrbit to createOrbit(inclination,0,body:radius+orbitAltitude,LAN,0,0,0,body).
	return parkingOrbit.
}



function setAltitude{
	parameter value.
	set orbitAltitude to value.
	return orbitAltitude.
}

function setInclination{
	parameter value.
	set inclination to value.
	set inclination to clampAngleBetween0and360(inclination).
	if inclination>180{
		set inclination to inclination -180.
	}
	return inclination.
}

function setLAN{
	parameter value.
	set LAN to value.
	set LAN to mod(LAN+360,360).
	return LAN.
}

//this function adds a custom widget that is similar to a textField, only it is limited to numeric inputs.
//also, the onConfirmDelegate should accept 1 parameter (the new value) AND it should return that value.
//the onConfirmDelegate can change the value any way you like, such as clamping it between two valid values
function addNumberFieldWidget{
	parameter box, titleText, onConfirmDelegate.
	//lets create the containing "div"
	declare local innerBox to box:addvbox().
	declare local titleLabel to innerBox:addLabel(titleText).
	declare local numericValue to 0.
	declare local entryTextField to innerBox:addtextfield().
	set entryTextField:onConfirm to confirm@.
	
	function confirm{
		parameter value.
		set numericValue to value:toScalar(numericValue).
		set entryTextField:text to onConfirmDelegate:call(numericValue):tostring.
	}
}