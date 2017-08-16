@:build(t9.redis.RedisObject.build())
class RedisObjectTest
{
	static var INLINE_INTERPOLATED_STRING :String = 'print("${RedisObjectScriptDependency.Value1}")';

	/**
	 * This contains a manually interpolated string. Metadata cannot do
	 * interpolated strings, so the string manually has the content of
	 * ${...} entries replaced with the content. The replaced keys
	 * must be either static class string vars, or entries in the
	 * SCRIPTS map (that is created at compile time).
	 */
	@redis({
		lua:'
			${INLINE_INTERPOLATED_STRING}
			local input = ARGV[1]
			local n = tonumber(input)
			return n + 1
		'
	})
	public static function addOne(input :Int) :Promise<Int>
	{
		return null;
	}

	@redis({
		lua:'
			local input = ARGV[1]
			redis.call("HSET", "foo", "key", input)
		'
	})
	public static function putValue(input :String) :Promise<Int>
	{
		return null;
	}

	@redis({
		lua:'
			local input = ARGV[1]
			return redis.call("HGET", "foo", "key")
		'
	})
	public static function getValue() :Promise<String>
	{
		return null;
	}
}