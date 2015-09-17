import haxe.unit.async.PromiseTestRunner;

class Tests
{
	public static function main():Void
	{
		new PromiseTestRunner()
			.add(new TestRedis())
			.run();
	}
}