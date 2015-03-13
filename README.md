# [Haxe](http://haxe.org) [Node.js](http://nodejs.org/) bindings for Redis

[Haxe](http://haxe.org) bindings for the [Node.js](http://nodejs.org/) [Redis](http://redis.io/) client https://github.com/mranney/node_redis.


Usage:

	var redisClient = RedisClient.createClient(6379, "192.168.59.103");
	var key = "TESTKEY1_" + Math.floor(Math.random() * 100000);
	var value = "value1";

	redisClient.set(key, value, function(err, success) {
		if (err != null) {
			trace('Err: ' + err);
		} else {
			redisClient.get(key, function(err, result) {
				if (err != null) {
					trace('Err: ' + err);
				} else {
					trace('Success: ' + (result == value));
				}
			});
		}
	});
	redisClient.quit();

