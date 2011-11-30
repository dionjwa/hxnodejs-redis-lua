package redis;
import haxe.serialization.Serialization;

import utest.Assert;

import redis.support.RedisSerializableClass;

using Lambda;

/**
 * Serialization tests
 */
class RedisTest 
{
	#if nodejs
	var db :js.node.redis.RedisDB;
	#end
	
	public static function main () :Void
	{
		// var test = new RedisTest();
		// test.setup();
		
		// test.testRedisSerialization();
		// test.testNextId();
		// test.testObjectStore();
		// test.testUpdate();
		// test.testRm();
	}
	
	public function new() 
	{
		
	}
	
	@BeforeClass
	public function beforeClass():Void
	{
	}
	
	@AfterClass
	public function afterClass():Void
	{
	}
	
	@Before
	public function setup():Void
	{
		#if nodejs
		db = new js.node.redis.RedisDB();
		#end
	}
	
	@After
	public function tearDown():Void
	{
	}
	
	#if nodejs
	/**
	  * Redis can store objects as hashes (key, values).
	  */
	@Test
	public function testNextId () :Void
	{
		var f = function () :Void {
			db.nextID(RedisSerializableClass, function (prevId) {
				db.nextID(RedisSerializableClass, function (id) {
					Assert.isTrue(prevId < id);
				});
			});
		}
		
		var async = Assert.createAsync(f);
	   haxe.Timer.delay(async, 100);
		
	}
	
	@Test
	public function testObjectStore () :Void
	{
		
		var f = function () :Void {
			var var1Value = "testString";
			var var2Value = 7;
			
			var obj = new RedisSerializableClass();
			obj.var1 = var1Value;
			obj.var2 = var2Value;
			
			Assert.isTrue(true);
			
			db.create(obj, function (id) {
				db.conn.exists(id, function (err :Dynamic, exists :Int) :Void {
					Assert.isTrue(exists == 1);
					db.load(id, function (val :RedisSerializableClass) :Void {
						
						Assert.isTrue(val.var1 == obj.var1);
						Assert.isTrue(val.var2 == obj.var2);
					});
				});
			});
		}
		
		var async = Assert.createAsync(f);
	   haxe.Timer.delay(async, 200);
	   
	}
	
	@Test
	public function testUpdate () :Void
	{
		var f = function () :Void {
			
			var var1Value = "testString";
			var var2Value = 8;
			var var2Updated = 9;
			Assert.isTrue(var2Value != var2Updated); 
			
			var obj = new RedisSerializableClass();
			obj.var1 = var1Value;
			obj.var2 = var2Value;
			
			db.create(obj, function (id) {
				db.conn.exists(id, function (err :Dynamic, exists :Int) :Void {
					Assert.isTrue(exists == 1);
					obj.var2 = var2Updated;
					db.update(obj, function (done :Bool) {
						db.load(id, function (loaded :RedisSerializableClass) :Void {
							Assert.isTrue(loaded.var1 == obj.var1);
							Assert.isTrue(loaded.var2 == obj.var2);
						});
					});
				});
			});
		}
		
		var async = Assert.createAsync(f);
	   haxe.Timer.delay(async, 200);
	   
	}
	
	@Test
	public function testRm () :Void
	{
		var f = function () :Void {
			var var1Value = "testString";
			var var2Value = 8;
			
			var obj = new RedisSerializableClass();
			obj.var1 = var1Value;
			obj.var2 = var2Value;
			
			db.create(obj, function (id) {
				db.conn.exists(id, function (err :Dynamic, exists :Int) :Void {
					Assert.isTrue(exists == 1);
					db.rm(obj, function (done :Bool) {
						db.load(id, function (loaded :RedisSerializableClass) :Void {
							Assert.isNull(loaded);
						});
					});
				});
			});
		}
		
		var async = Assert.createAsync(f);
	   haxe.Timer.delay(async, 100);
	   
	}
	
	/**
	  * Redis can store objects as hashes (key, values).
	  */
	@Test
	public function testRedisSerialization():Void
	{
		var toSerialize = new RedisSerializableClass();
		
		var var1 = "someTestString";
		var var2 = 7;
		
		toSerialize.var1 = var1;
		toSerialize.var2 = var2;
		
		var array = Serialization.classToArray(toSerialize);
		
		Assert.isTrue(array.length == 4);
		
		var deserialized :RedisSerializableClass = Serialization.arrayToClass(array, RedisSerializableClass);
		
		Assert.isTrue(toSerialize.var1 == deserialized.var1);
		Assert.isTrue(toSerialize.var2 == deserialized.var2);
		
	}
	#end
}


