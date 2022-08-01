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

//given a list of numbers, return an equal-length list of numbers, but where each number is the cumulative sum of all the numbers before it
//example input = [1,2,3,4,5]
//example output = [1,3,6,10,15]
function cumulativeSum{
	parameter theList.
	declare local returnList to theList:copy().

	//iterate over each index in the returnList
	FROM {local currIndex is 1.} UNTIL (currIndex = returnList:length) STEP {set currIndex to currIndex+1.} DO {
		set returnList[currIndex] to returnList[currIndex] + returnList[currIndex-1].
	}
	return returnList.
}