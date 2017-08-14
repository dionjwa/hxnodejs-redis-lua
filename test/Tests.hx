import haxe.unit.async.PromiseTestRunner;

class Tests
{
	public static function main():Void
	{
		trace('Running tests');
		new PromiseTestRunner()
			.add(new TestRedisCore())
			.add(new TestRedisLuaObjects())
			.run();

#if (nodejs && !travis)
		try {
			untyped __js__("if (require.resolve('source-map-support')) {require('source-map-support').install(); console.log('source-map-support installed');}");
		} catch (e :Dynamic) {}
#end
	}
}