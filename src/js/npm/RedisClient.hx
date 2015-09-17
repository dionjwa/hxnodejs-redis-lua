package js.npm;

import js.Node;
import js.node.events.EventEmitter;
import js.support.Error;

typedef Channel = String;
typedef ChannelCount = Int;
typedef IntegerReply = Error->Int->Void;
typedef BooleanReply = Error->Bool->Void;
typedef StatusReply = Error->String->Void;
typedef SubscribeReply = Channel->ChannelCount->Void;
typedef MessageReply = Channel->String->Void;
typedef BulkReply = Error->Dynamic->Void;
typedef MultiReply = Error->Array<Dynamic>->Void;
typedef MultiCommand = Array<Dynamic>;

typedef Multi = {
  function exec(cb :MultiReply) :Void;
}

@:native("RedisClient")
extern class RedisClient extends js.node.events.EventEmitter
  implements npm.Package.Require<"redis","*">
{
  inline public static var EVENT_READY :String = "ready";
  inline public static var EVENT_CONNECT :String = "connect";
  inline public static var EVENT_END :String = "end";
  inline public static var EVENT_DRAIN :String = "drain";
  inline public static var EVENT_IDLE :String = "idle";
  inline public static var EVENT_ERROR :String = "error";
  inline public static var EVENT_SUBSCRIBE :String = "subscribe";
  inline public static var EVENT_PSUBSCRIBE :String = "psubscribe";
  inline public static var EVENT_UNSUBSCRIBE :String = "unsubscribe";
  inline public static var EVENT_PUNSUBSCRIBE :String = "punsubscribe";
  inline public static var EVENT_MESSAGE :String = "message";
  inline public static var EVENT_PMESSAGE :String = "pmessage";

  public static function createClient(?port :Int, ?address :String, ?options :Dynamic):RedisClient;
  public static function print(?arg1 :Dynamic, ?arg2 :Dynamic, ?arg3 :Dynamic, ?arg4 :Dynamic):Void;
  // control
  /** Forcibly close the connection to the Redis server. Note that this does not wait until all replies have been parsed. */
  public function end():Void;
  /** Exit cleanly. */
  public function quit():Void;
  public function info(cb:BulkReply):Void;
  public function save(cb:StatusReply):Void;
  public function bgsave(cb:StatusReply):Void;
  public function lastsave(cb:IntegerReply):Void;
  public function unref():Void;

  // all
  public function exists(k:String,cb:IntegerReply):Void;
  public function del(k:String,cb:IntegerReply):Void;
  public function type(k:String,cb:StatusReply):Void;
  public function keys(pattern:String,cb:MultiReply):Void;
  public function randomkey(k:String,cb:StatusReply):Void;
  public function rename(k:String,nk:String,cb:StatusReply):Void;
  public function renamenx(k:String,nk:String,cb:StatusReply):Void;
  public function dbsize(cb:IntegerReply):Void;
  public function expire(k:String,secs:Int,cb:IntegerReply):Void;
  public function ttl(k:String,cb:IntegerReply):Void;
  public function select(index:Int,cb:StatusReply):Void;
  public function move(k:String,index:Int,cb:IntegerReply):Void;
  public function flushdb(cb:StatusReply):Void;
  public function flushall(cb:StatusReply):Void;

  // strings
  public function set(k:String,v:String,cb:BooleanReply):Void;
  public function get(k:String,cb:StatusReply):Void;
  public function incr(k:String,cb:IntegerReply):Void;
  public function incrby(k:String,by:Int,cb:IntegerReply):Void;
  public function decr(k:String,cb:IntegerReply):Void;
  public function decrby(k:String,by:Int,cb:IntegerReply):Void;
  public function setnx(k:String,v:String,cb:BooleanReply):Void;
  public function mset(ks:Array<Dynamic>,cb:BooleanReply):Void;
  public function msetnx(ks:Array<Dynamic>,cb:BooleanReply):Void;
  public function mget(ks:Array<String>,cb:Error->Array<String>->Void):Void;
  public function getset(k:String,v:String,cb:StatusReply):Void;
  public function append(k:String,v:String,cb:IntegerReply):Void;
  public function substr(k:String,s:Int,e:Int,cb:StatusReply):Void;
  public function setex(k:String,t:Int,v:Dynamic,cb:StatusReply):Void;

  // lists
  public function lpush(k:String,v:String,cb:IntegerReply):Void;
  public function rpush(k:String,v:String,cb:IntegerReply):Void;
  public function llen(k:String,cb:IntegerReply):Void;
  public function lrange(k:String,s:Int,e:Int,cb:MultiReply):Void;
  public function ltrim(k:String,s:Int,e:Int,cb:StatusReply):Void;
  public function lindex(l:String,i:Int,cb:BulkReply):Void;
  public function lset(k:String,i:Int,v:String,cb:StatusReply):Void;
  public function lrem(k:String,c:Int,v:String,cb:IntegerReply):Void;
  public function lpop(k:String,cb:MultiReply):Void;
  public function rpop(k:String,cb:MultiReply):Void;
  public function blpop(k:String,s:Int,cb:MultiReply):Void;
  public function brpop(k:String,s:Int,cb:MultiReply):Void;
  public function rpoplpush(sk:String,dk:String,cb:BulkReply):Void;

  // sets
  public function sadd(k:String,v:String,cb:IntegerReply):Void;
  public function srem(k:String,v:String,cb:IntegerReply):Void;
  public function spop(k:String,cb:BulkReply):Void;
  public function smove(sk:String,dk:String,member:String,cb:IntegerReply):Void;
  public function scard(k:String,cb:IntegerReply):Void;
  public function sismember(k:String,m:String,cb:IntegerReply):Void;
  public function sinter(k1:String,k2:String,cb:MultiReply):Void;
  public function sinterstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  public function sunion(k1:String,k2:String,cb:MultiReply):Void;
  public function sunionstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  public function sdiff(k1:String,k2:String,cb:MultiReply):Void;
  public function sdiffstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  public function smembers(k:String,cb:MultiReply):Void;
  public function srandmember(k:String,cb:BulkReply):Void;

  // hash
  @:overload(function(args:Array<String>, cb:IntegerReply):Void {})
  public function hset(k:String,f:String,v:String,cb:IntegerReply):Void;
  public function hget(k:String,f:String,cb:BulkReply):Void;
  public function hsetnx(k:String,f:String,v:String,cb:IntegerReply):Void;
  @:overload(function(k:String,f:Dynamic<String>,cb:StatusReply):Void {})
  public function hmset(k:String, f:Array<String>,cb:StatusReply):Void;
  public function hmget(k:Array<String>,cb:MultiReply):Void;
  public function hincrby(k:String,f:String,v:Int,cb:IntegerReply):Void;
  public function hexists(k:String,f:String,cb:IntegerReply):Void;
  public function hdel(k:String,f:String,cb:IntegerReply):Void;
  public function hlen(k:String,cb:IntegerReply):Void;
  public function hkeys(k:String,cb:MultiReply):Void;
  public function hvals(k:String,cb:MultiReply):Void;
  public function hgetall(k:String,cb:MultiReply):Void;

  // sorted sets
  public function zadd(k:String,s:Int,m:String,cb:IntegerReply):Void;
  public function zrem(k:String,m:String,cb:IntegerReply):Void;
  public function zincrby(k:String,i:Int,m:String,cb:IntegerReply):Void;
  public function zrank(k:String,m:String,cb:BulkReply):Void;
  public function zrankrev(k:String,m:String,cb:BulkReply):Void;
  public function zrange(k:String,s:Int,e:Int,?scores:Bool,cb:MultiReply):Void;
  public function zrevrange(k:String,s:Int,e:Int,cb:MultiReply):Void;
  public function zrangebyscore(k:String,min:Int,max:Int,cb:MultiReply):Void;
  public function zremrangebyrank(k:String,s:Int,e:Int,cb:IntegerReply):Void;
  public function zremrangebyscore(k:String,min:Int,max:Int,cb:IntegerReply):Void;
  public function zcard(k:String,cb:IntegerReply):Void;
  public function zscore(k:String,e:String,cb:BulkReply):Void;
  public function zunionstore(prms:Array<Dynamic>,cb:IntegerReply):Void;
  public function zinterstore(prms:Array<Dynamic>,cb:IntegerReply):Void;
  public function sort(prms:Array<Dynamic>,cb:MultiReply):Void;

  // pubsub
  public function subscribe(c:Channel):Void;
  public function publish(c:Channel,m:String):Void;

  // Misc
  public function multi(?prms:Array<MultiCommand>):Multi;

  private function new();
}
