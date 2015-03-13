import haxe.unit.async.PromiseTestRunner;

import js.node.redis.RedisClient;

class Tests
{
	public static function main():Void
	{
		new PromiseTestRunner()
			.add(new TestRedis())
			.run();

		// var client = RedisClient.createClient(6379, "192.168.59.103");

		// client.on("error", function (err) {
		//     trace("Error " + err);
		// });

		// client.set("string key", "string val", untyped RedisClient.print);
		// client.hset("hash key", "hashtest 1", "some value", untyped RedisClient.print);
		// // client.hset(["hash key", "hashtest 2", "some other value"], untyped RedisClient.print);
		// client.hkeys("hash key", function (err, replies) {
		//     trace(replies.length + " replies:");
		//     for (i in 0...replies.length) {
		//     	var reply = replies[i];
		//     	trace("    " + i + ": " + reply);
		//     }
		//     // client.quit();
		// });
	}
}