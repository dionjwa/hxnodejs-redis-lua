
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

getHaxelibVersion ()
{
	CURRENT_HAXELIB_VERSION=$(haxelib info $1 \
		| grep Version \
		| head -1 \
		| awk -F: '{ print $2 }' \
		| sed 's/[",]//g' \
		| tr -d '[[:space:]]')
	return $CURRENT_HAXELIB_VERSION
}

getNextHaxelibVersion ()
{
	CURRENT_HAXELIB_VERSION=$(getHaxelibVersion $1)
	NEXT=$($DIR/increment_version.sh -p $CURRENT_HAXELIB_VERSION)
	return $NEXT
}

incrementLocalHaxelibVersion ()
{

}