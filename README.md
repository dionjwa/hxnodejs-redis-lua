# Lua script decorated methods that are executed in Redis (Haxe Nodejs)

Node and Redis are a great combination: a flexible, scalable web server combined with a powerful memcache on steroids.

One of the great features of Redis is Lua scripting. It gets you closer to the data, and can prevent concurrency issues. However, managing your scripts in code can be a pain, especially if you start re-using pieces of scripts.

This library uses Haxe macros allowing you to decorate methods with Lua scripts. It handles uploading the Lua scripts, etc.


Example:

```
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
```

The content of the function is replaced at compile time to something like:

```
	@redis({
		lua:'
			local input = ARGV[1]
			local n = tonumber(input)
			return n + 1
		'
	})
	public static function addOne(input :Int) :Promise<Int>
	{
		var promise = new promhx.DeferredPromise();
		return REDIS_CLIENT.evalsha(...., function(err, result) {
			if (err != null) {
				promise.boundPromise.reject(err);
			} else {
				promise.resolve(err);
			}
		});
		return promise.boundPromise;
	}
```

See the `test` folder for the example of the `RedisObjectTest.hx` object.

## Running the tests

Install `docker`, then:

	docker-compose up --abort-on-container-exit

