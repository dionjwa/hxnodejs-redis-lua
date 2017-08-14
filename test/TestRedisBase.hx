class TestRedisBase extends PromiseTest
{
	static function getRedisClient() :Promise<RedisClient>
	{
		var promise = new DeferredPromise();
		var client = RedisClient.createClient(6379, 'redis');
		client.on(RedisEvent.Error, function(err) {
			promise.boundPromise.reject(err);
		});
		client.on(RedisEvent.Ready, function() {
			promise.resolve(client);
		});
		return promise.boundPromise;
	}

	override public function setup() :Promise<Bool>
	{
		return getRedisClient()
			.then(function(client) {
				_redisClient = client;
				return true;
			});
	}

	override public function tearDown() :Promise<Bool>
	{
		if (_redisClient != null) {
			_redisClient.quit();
			_redisClient = null;
		}
		return Promise.promise(true);
	}

	var _redisClient :RedisClient;

	public function new() {}
}