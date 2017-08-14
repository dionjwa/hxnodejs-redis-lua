@:build(t9.redis.RedisObject.build())
class RedisObjectTest
{
	@redis({
		lua:'
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