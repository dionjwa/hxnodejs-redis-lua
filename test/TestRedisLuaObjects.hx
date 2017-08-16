class TestRedisLuaObjects extends TestRedisBase
{
	@timeout(100)
	public function testLuaObjectMethods1() :Promise<Bool>
	{
		return RedisObjectTest.init(_redisClient)
			.pipe(function(_) {
				var input = 3;
				return RedisObjectTest.addOne(input)
					.then(function(result) {
						assertEquals(result, input + 1);
						return true;
					});
			});
	}

	@timeout(100)
	public function testLuaObjectMethods2() :Promise<Bool>
	{
		return RedisObjectTest.init(_redisClient)
			.pipe(function(_) {
				var input = 'polar bear';
				return RedisObjectTest.putValue(input)
					.pipe(function(_) {
						return RedisObjectTest.getValue()
							.then(function(result) {
								assertEquals(result, input);
								return true;
							});
					});
			});
	}

	public function new() {super();}
}