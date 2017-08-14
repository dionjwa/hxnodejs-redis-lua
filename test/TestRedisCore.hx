class TestRedisCore extends TestRedisBase
{

	public function testGetSet() :Promise<Bool>
	{
		var promise = new DeferredPromise();

		var key = "TESTKEY1_" + Math.floor(Math.random() * 100000);
		var value = "value1";
		_redisClient.set(key, value, function(err, success) {
			if (err != null) {
				promise.boundPromise.reject(err);
			} else {
				_redisClient.get(key, function(err, result) {
					if (err != null) {
						promise.boundPromise.reject(err);
					} else {
						promise.resolve(result == value);
					}
				});
			}
		});

		return promise.boundPromise;
	}

	public function new() {super();}
}