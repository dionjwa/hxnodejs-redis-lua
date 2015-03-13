import haxe.unit.async.PromiseTestRunner;

import js.node.redis.RedisClient;

class Tests
{
	public static function main():Void
	{
		new PromiseTestRunner()
			.add(new TestRedis())
			.run();
	}
}