@lazyGlobal off.

parameter upperTerminalRow.//the upper-most row in the terminal that this process is allowed to use for display purposes

function calculatePitchAngle{
	parameter targetOrbit.
	parameter maxAoA is 5.
	parameter theShip is ship.
	//parameter launchAltitude.


	declare local maxPitchoverAngle to 2.//the lowest pitch angle we will allow, for saftey reasons.

	//setup
	declare local currApo to theShip:apoapsis.//current apoapsis
	declare local targetApo to targetOrbit:periapsis.//target apoapsis. yes I know it's says "targetOrbit:PERIAPSIS", but this is intentional
	declare local fractionOfTgtApo to currApo/(targetApo). //fraction of the target apoapsis the current apoapsis is.
	declare local currentPitchAngle to 90 - vectorangle(up:vector,theShip:facing:forevector).//our current pitch angle
	declare local currentProgradePitchAngle to (90-vectorangle(up:vector,theShip:srfprograde:vector)).//the pitch angle of prograde

	//calculate what the pitch should be
	declare local calculatedPitchAngle to 90-(sqrt(fractionOfTgtApo))*90.//the pitch we should ideally have right now
	set calculatedPitchAngle to max(maxPitchoverAngle,calculatedPitchAngle).//adjust for maximum safe pitchover angle
	if (targetOrbit:body:atm:exists) {
		set calculatedPitchAngle to adjustForAoA(calculatedPitchAngle,currentProgradePitchAngle,maxAoA).//adjust for maximum angle-of-attack
	}

	//display data
	print "--------------------------------------------------" at (0,upperTerminalRow+0).
	print "Pitch Program: sqrt apoapsis percentage based." at (0,upperTerminalRow+1).
	print "Status - " at (0,upperTerminalRow+2).
	print "Apoapsis: "+round(theShip:apoapsis/1000,2)+"/"+targetApo/1000+" km ("+round(fractionOfTgtApo,2)*100+"%).	"at(0,upperTerminalRow+3).
	print "Calulated pitch angle is: "+round(calculatedPitchAngle,2)+" degrees."at(0,upperTerminalRow+4).
	print "Actual pitch angle is "+round(currentPitchAngle,2)+" degrees."at(0,upperTerminalRow+5).
	//print "Prograde pitch angle is "+round(90-vectorangle(up:vector,theShip:srfprograde:vector),2)+" degrees."at(0,upperTerminalRow+6).
    print "Prograde pitch angle is "+round(currentProgradePitchAngle,2)+" degrees."at(0,upperTerminalRow+6).
	//pitch offset info is printed here
	print "--------------------------------------------------" at (0,upperTerminalRow+8).
	return calculatedPitchAngle.
}

//a function that take a calulated, desired pitch. if the pitch is to severly different 
//from the prograde angle, we'll return an angle with the max AOA from the prograde angle 
//in the same direction as the origigal desired pitch.
function adjustForAoA{
	parameter desiredPitchAngle, currentProgradePitchAngle, maxAoA.

	//this is what we will return
	declare local AdjustedPitchAngle to 0.

	//how far off from prograde the desired pitch is
	declare local progradeOffset to desiredPitchAngle - currentProgradePitchAngle.
	print "calulated pitch is off from prograde by: "+round(progradeOffset,2)+" degrees" at (0,upperTerminalRow+7).

	//if we want to allow the rocket to pull up as hard as it can if we need to
	declare local allowHardPitchUp to true.

	//now we actually adjust
	//if we're trying to pitch too far down...
	if (progradeOffset < (-1*maxAoA) ){ 
		set AdjustedPitchAngle to currentProgradePitchAngle-maxAoA.

	//if we're trying to pitch to far up...
	} else if (progradeOffset > maxAoA and not allowHardPitchUp){
		set AdjustedPitchAngle to currentProgradePitchAngle+maxAoA.
	}

	//otherwise, we must be within acceptable AoA parameters. desired pitch angle is fine
	else {
		set AdjustedPitchAngle to desiredPitchAngle.
	}.

	return AdjustedPitchAngle.
}.

