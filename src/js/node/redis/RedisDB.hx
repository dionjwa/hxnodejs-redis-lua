package js.node.redis;

import js.node.redis.Redis;

typedef PRef = String;
typedef PIndex = { name:String, filter:Dynamic->String };
typedef PObj = {_id :String}

/**
  * Adapted from Ritchie's PDrvRedis.  Does not require stored
  * objects to extend PObj.
  */
class RedisDB
{
	static var ALL = "all:";
	static var HASH = "h_";
	static var ZSET = "z_";
	static var SET = "s_";
	static var SERIAL = "serial:";
	static var TEXT = "t_";
	static var OBJECT = "object";
	
	public static function ignore(e,v) {}
	
	#if debug public #end
	var conn :RedisClient;
	
	public function new() 
	{
		conn = Redis.newClient();
	}
	
	public function nextID (kls :Class<Dynamic>, cb:PRef->Void) 
	{
		var klsName = Type.getClassName(kls);
		conn.incr(SERIAL+klsName, function(e,id) {
			cb(Std.string(id));	
		});
	}
	
	public function create(instance :PObj, cb :String->Void)
	{
		var kls = Type.getClass(instance);
		var klsName = Type.getClassName(kls);
		var insert = function(id :String) {
			 var sid = klsName + ":" + id;
			 
			 if (instance._id == null) {
				instance._id = sid;
			 }
			
			var o :Dynamic = {};
			
			Reflect.setField(o, OBJECT, haxe.Serializer.run(instance));
			
			conn.rpush(ALL+klsName,sid,function(e,v) {
				Reflect.setField(o, "position", Std.string(v));
				conn.hmset(sid, o, function(e, v) {
					indexEntry(conn, kls, klsName, instance, function (err) :Void {
						if (cb != null) {
							cb(sid);
						}
					});
					
				});
			});
		}
		
		if (instance._id == null) {
			nextID(kls, insert);
		} else {
			insert(instance._id);
		}
	}

	public function get <T>(klsName :String, index :Int, cb:T->Void) {
		var self = this;
		conn.lindex(ALL+klsName, index, function(e, v) {
			errCheck(e);
			self.load(v, cb);
		});
	}
	
	/**
	  * id: The internal Redis key, NOT the per object id
	  */
	public function load<T>(id :String, fn :T->Void) :Void
	{
		conn.hget(id, OBJECT, function(err, v) {
			errCheck(err);
			if (v != null) {
				var obj = haxe.Unserializer.run(new String(v));
				fn(obj);
			} else {
				fn(null);
			}
		});
	}

	public function sync(instance :PObj, cb :Bool->Void)
	{
		var kls = Type.getClass(instance);
		load(Std.string(instance._id), function(newObj) {
			for (f in Reflect.fields(instance)) {
				var nval = Reflect.field(newObj, f);
				Reflect.setField(instance,f,nval);
			}
			cb(true);
		});
	}

	public function find <T>(klsName :String, index :String, key :String, cb :T->Void)
	{
		var me = this;
		conn.hget(indexName(klsName, index), key, function(err, id) {
			if (id != null) {
				me.load(id,cb);
			} else {
				cb(null);
			}
		});
	}
	
	public function update(instance :PObj, cb :Bool->Void) 
	{
		var kls = Type.getClass(instance);
		var klsName = Type.getClassName(kls);
		var obj = haxe.Serializer.run(instance);

		conn.hset(instance._id, OBJECT, obj, function(e,v) {
			if (e == null) {
				indexEntry(conn, kls, klsName, instance, function (err) {
					errCheck(err);
					cb(err == null);
				});
			} else {
				cb(false);
			}
		});
	}

	public function rm (instance :PObj, cb :Bool->Void) 
	{
		var id = instance._id;
		// this should be MULTI/EXEC when it exists
		conn.lrem(ALL+Type.getClassName(Type.getClass(instance)), 1, id, function(e,v) {
			delIndexEntry(instance, function (done :Bool) {
				conn.del(instance._id, function (e, v) {
					errCheck(e);
					cb(e == null);
				});
			});
		});
	}
	
	static inline function indexName (klsName, name) :String
	{
		return "index:"+klsName+":"+name;
	}
	
	static function indexEntry(conn:RedisClient, kls:Class<Dynamic>, klsName:String, instance :PObj, cb :Err->Void) 
	{
		var kls = Type.getClass(instance);
		var foundIndices = false;
		for (kf in Type.getClassFields(kls)) {
			if (kf == "_indexOn") {
				foundIndices = true;
				var indexes:Array<PIndex> = Reflect.field(kls,kf);
				var indexer = function (index :PIndex, onElementFinish :Void->Void) :Void {
					if (index.filter == null) throw "An index must have a filter function";
					var val = index.filter(instance);
					if (val != null) {
						conn.hset(indexName(klsName, index.name), val, instance._id, function (err :Err, done :Int) :Void {
							errCheck(err);
							conn.set(val,instance._id, function (err :Err, done :Bool) :Void {
								errCheck(err);
								onElementFinish();
							});
						});
					} else {
						onElementFinish();
					}
				}
				AsyncLambda.iter(indexes, indexer, cb);
			}
		}
		
		if (!foundIndices) {
			cb(null);
		}
	}

	function delIndexEntry(instance :PObj, cb :Bool->Void) 
	{
		var kls = Type.getClass(instance);
		var foundIndices = false;
		for (kf in Type.getClassFields(kls)) {
			if (kf == "_indexOn") {
				foundIndices = true;
				var indexes:Array<PIndex> = Reflect.field(kls,kf);
				var indexer = function (index :PIndex, onElementFinish :Void->Void) :Void {
					conn.hdel(indexName(Type.getClassName(Type.getClass(instance)), index.name), instance._id, function (e, v) {
						errCheck(e);
						onElementFinish();
					});
				}
				AsyncLambda.iter(indexes, indexer, function (err) {cb(err == null);});
				break;
			}
		}
		
		if (!foundIndices) {
			cb(true);
		}
	}
	
	// static function eachIndex(instance:PObj, cb:PIndex->Void) 
	// {
	// 	var kls = Type.getClass(instance);
	// 	for (kf in Type.getClassFields(kls)) {
	// 		if (kf == "_indexOn") {
	// 			var indexes:Array<PIndex> = Reflect.field(kls,kf);
	// 			for (index in indexes) {
	// 				cb(index);
	// 			}
	// 		}
	// 	}
	// }

	// public function linked<T>(inKls:Class<T>,forObject:PRef,start:Int,end:Int,cb:Array<T>->Void) {
	// 	var
	// 		klsName = Type.getClassName(inKls),
	// 		spec = [forObject+":children:"+klsName,"limit",start,end,"get","*->"+OBJECT];
	// 	sorted(spec,cb);
	// }

	// public function indexed(klsName:String,start:Int,end:Int,index:String,cb:Array<Dynamic>->Void) {
	// 	var spec = ["index:"+klsName+":"+index,"by","nosort","limit",start,end,"get","*->"+OBJECT];
	// 	sorted(spec,cb);
	// }

	// public function range<T>(klsName:String,start:Int,end:Int,cb:Array<T>->Void) {
	// 	pool.use(function(conn) {
	// 			sorted([ALL+klsName,"limit",start,end,"get","*->"+OBJECT],cb);
	// 		});
	// }

	// static function sorted<T>(spec:Array<T>,cb:Array<T>->Void) {
	// 	trace("spec is "+spec);
	// 	pool.use(function(conn) {
	// 			conn.sort(spec,function(e,members) {
	// 					getObjects(members,cb);
	// 			});
	// 		});
	// }

	// static function getObjects<T>(members:Array<Dynamic>,cb:Array<T>->Void) {
	// 	if (members != null) {
	// 		var objArr:Array<T> = new Array();
	// 		while(members.length > 0) {
	// 			objArr.push(haxe.Unserializer.run(new String(members.shift())));
	// 		}
	// 		cb(objArr);
	// 	}
	// }
	
	inline static function errCheck (err :Dynamic) :Void 
	{
		if (err != null) {
			trace("err=" + err);
		}
	}
}
