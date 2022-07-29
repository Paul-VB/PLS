@lazyGlobal off.

//given a number, return 1 but of the opposite sign.
//if the input is positive, return -1
//if the input is negative or 0, return +1
function getOppositeSign1{
	parameter num.
	if num < 0{
		return -1.
	} else {
		return 1.
	}
}

//clamp a value between a minimum and a maximum
function clamp{
	parameter value, minimum, maximum.
	return min(maximum,(max(minimum,value))).
}

//given a number, return it as a string with either a positive (+) or negative (-) sign before it
function toStringSigned{
	parameter number.
	declare local result to number:tostring.
	if number > 0 {
		set result to "+"+result.
	}
	return result.
}