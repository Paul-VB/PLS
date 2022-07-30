@lazyGlobal off.

// #include "guiSkin.ks"

declare local answer to true.
declare local finished to false.

//displays and prompts the user to either confirm or cancel a warp to the next launch window
function confirmWarpToLaunchWindow{
	//define the gui window
	declare local window to gui(600).
	set window:skin to getSkin().
	declare local headerBox to window:addHBox().
	declare local titleLabel to headerBox:addLabel("Paul's Launch Script").

	declare local bodyBox to window:addvbox().
	{
		declare local subTitleLabel to bodyBox:addlabel("Do you want to warp to the next launch window?").
		declare local bodyRow0 to bodyBox:addhbox().{
			declare local yesButton to bodyRow0:addbutton("Yes").
			set yesButton:onClick to selectYes@.
			declare local noButton to bodyRow0:addbutton("No").
			set noButton:onClick to selectNo@.
		}

	}
	window:SHOW().

	//until we are done entering data, wait
	until finished{
		wait 0.
	}
	window:hide().
	return answer.
}

function selectYes{
	set answer to true.
	set finished to true.
}

function selectNo{
	set answer to false.
	set finished to true.
}