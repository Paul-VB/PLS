@lazyGlobal off.

function getSkin{
	declare local skin to gui(0):skin.
	set skin:label:align to "CENTER".
	set skin:label:HSTRETCH to TRUE.
	return skin.
}