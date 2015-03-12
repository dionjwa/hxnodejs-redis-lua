import haxe.unit.async.PromiseTest;

import promhx.Promise;
import promhx.Deferred;

import js.node.redis.RedisClient;

class TestRedis extends PromiseTest
{

	public function new()
	{
		var client = RedisClient.createClient();
		// trace("client:" + client);
	}

	override public function setup() :Promise<Bool>
	{
		return Promise.promise(true);
	}

	override public function tearDown() :Promise<Bool>
	{
		return Promise.promise(true);
	}

	public function testThis1() :Promise<Bool>
	{
		return Promise.promise(true);
	}
}