import haxe.unit.async.PromiseTest;

import promhx.Promise;
import promhx.Deferred;

import js.node.redis.RedisClient;

class TestRedis extends PromiseTest
{
	public function new()
	{
	}

	override public function setup() :Promise<Bool>
	{
		var deferred = new Deferred();
		var promise = deferred.promise();
		//This is tied to boot2docker. Must remove this dependency
		_redisClient = RedisClient.createClient(6379, "192.168.59.103");
		_redisClient.on(RedisClient.EVENT_ERROR, function (err) {
			promise.reject(err);
	    });
	    _redisClient.on(RedisClient.EVENT_READY, function () {
	       deferred.resolve(true);
	    });
		return promise;
	}

	override public function tearDown() :Promise<Bool>
	{
		if (_redisClient != null) {
			_redisClient.removeAllListeners(RedisClient.EVENT_ERROR);
			_redisClient.removeAllListeners(RedisClient.EVENT_READY);
			_redisClient.quit();
			_redisClient = null;
		}
		return Promise.promise(true);
	}

	public function testThis1() :Promise<Bool>
	{
		var deferred = new Deferred();
		var promise = deferred.promise();

		haxe.Timer.delay(function() {
			deferred.resolve(true);
		}, 100);

		return promise;
	}

	public function testGetSet() :Promise<Bool>
	{
		var deferred = new Deferred();
		var promise = deferred.promise();

		var key = "TESTKEY1_" + Math.floor(Math.random() * 100000);
		var value = "value1";
		_redisClient.set(key, value, function(err, success) {
			if (err != null) {
				promise.reject(err);
			} else {
				_redisClient.get(key, function(err, result) {
					if (err != null) {
						promise.reject(err);
					} else {
						deferred.resolve(result == value);
					}
				});
			}
		});

		return promise;
	}

	var _redisClient :RedisClient;
}