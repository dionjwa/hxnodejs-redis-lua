/**
  * Source: https://github.com/blackdog66/bdog-redis
  */

package js.node.redis;

import js.Node;

typedef Err = Dynamic;
typedef IntegerReply = Err->Int->Void;
typedef StatusReply = Err->String->Void;
typedef BulkReply = Err->Dynamic->Void;
typedef MultiReply = Err->Array<Dynamic>->Void;

typedef RedisClient = {

  // control
  function shutdown(cb:StatusReply):Void;
  function info(cb:BulkReply):Void;
  function save(cb:StatusReply):Void;
  function bgsave(cb:StatusReply):Void;
  function lastsave(cb:IntegerReply):Void;
  
  // all
  function exists(k:String,cb:IntegerReply):Void;
  function del(k:String,cb:IntegerReply):Void;
  function type(k:String,cb:StatusReply):Void;
  function keys(pattern:String,cb:MultiReply):Void;
  function randomkey(k:String,cb:StatusReply):Void;
  function rename(k:String,nk:String,cb:StatusReply):Void;
  function renamenx(k:String,nk:String,cb:StatusReply):Void;
  function dbsize(cb:IntegerReply):Void;
  function expire(k:String,secs:Int,cb:IntegerReply):Void;
  function ttl(k:String,cb:IntegerReply):Void;
  function select(index:Int,cb:StatusReply):Void;
  function move(k:String,index:Int,cb:IntegerReply):Void;
  function flushdb(cb:StatusReply):Void;
  function flushall(cb:StatusReply):Void;
  
  // strings
  function set(k:String,v:String,cb:Err->Bool->Void):Void;
  function get(k:String,cb:StatusReply):Void;
  function incr(k:String,cb:IntegerReply):Void;
  function incrby(k:String,by:Int,cb:IntegerReply):Void;
  function decr(k:String,cb:IntegerReply):Void;
  function decrby(k:String,by:Int,cb:IntegerReply):Void;
  function setnx(k:String,v:String,cb:Err->Bool->Void):Void;
  function mset(ks:Array<Dynamic>,cb:Err->Bool->Void):Void;
  function msetnx(ks:Array<Dynamic>,cb:Err->Bool->Void):Void;
  function mget(ks:Array<String>,cb:Err->Array<String>->Void):Void;
  function getset(k:String,v:String,cb:StatusReply):Void;
  function append(k:String,v:String,cb:IntegerReply):Void;
  function substr(k:String,s:Int,e:Int,cb:StatusReply):Void;
  function setex(k:String,t:Int,v:Dynamic,cb:StatusReply):Void;

  // lists
  function lpush(k:String,v:String,cb:IntegerReply):Void;
  function rpush(k:String,v:String,cb:IntegerReply):Void;
  function llen(k:String,cb:IntegerReply):Void;
  function lrange(k:String,s:Int,e:Int,cb:MultiReply):Void;
  function ltrim(k:String,s:Int,e:Int,cb:StatusReply):Void;
  function lindex(l:String,i:Int,cb:BulkReply):Void;
  function lset(k:String,i:Int,v:String,cb:StatusReply):Void;
  function lrem(k:String,c:Int,v:String,cb:IntegerReply):Void;
  function lpop(k:String,cb:MultiReply):Void;
  function rpop(k:String,cb:MultiReply):Void;
  function blpop(k:String,s:Int,cb:MultiReply):Void;
  function brpop(k:String,s:Int,cb:MultiReply):Void;
  function rpoplpush(sk:String,dk:String,cb:BulkReply):Void;

  // sets
  function sadd(k:String,v:String,cb:IntegerReply):Void;
  function srem(k:String,v:String,cb:IntegerReply):Void;
  function spop(k:String,cb:BulkReply):Void;
  function smove(sk:String,dk:String,member:String,cb:IntegerReply):Void;
  function scard(k:String,cb:IntegerReply):Void;
  function sismember(k:String,m:String,cb:IntegerReply):Void;
  function sinter(k1:String,k2:String,cb:MultiReply):Void;
  function sinterstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  function sunion(k1:String,k2:String,cb:MultiReply):Void;
  function sunionstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  function sdiff(k1:String,k2:String,cb:MultiReply):Void;
  function sdiffstore(dst:String,k1:String,k2:String,cb:StatusReply):Void;
  function smembers(k:String,cb:MultiReply):Void;
  function srandmember(k:String,cb:BulkReply):Void;

  // hash
  function hset(k:String,f:String,v:String,cb:IntegerReply):Void;
  function hget(k:String,f:String,cb:BulkReply):Void;
  function hsetnx(k:String,f:String,v:String,cb:IntegerReply):Void;
  function hmset(k:String, f:Array<String>,cb:StatusReply):Void;
  function hmget(k:Array<String>,cb:MultiReply):Void;
  function hincrby(k:String,f:String,v:Int,cb:IntegerReply):Void;
  function hexists(k:String,f:String,cb:IntegerReply):Void;
  function hdel(k:String,f:String,cb:IntegerReply):Void;
  function hlen(k:String,cb:IntegerReply):Void;
  function hkeys(k:String,cb:MultiReply):Void;
  function hvals(k:String,cb:MultiReply):Void;
  function hgetall(k:String,cb:MultiReply):Void;

  // sorted sets
  function zadd(k:String,s:Int,m:String,cb:IntegerReply):Void;
  function zrem(k:String,m:String,cb:IntegerReply):Void;
  function zincrby(k:String,i:Int,m:String,cb:IntegerReply):Void;
  function zrank(k:String,m:String,cb:BulkReply):Void;
  function zrankrev(k:String,m:String,cb:BulkReply):Void;
  function zrange(k:String,s:Int,e:Int,?scores:Bool,cb:MultiReply):Void;
  function zrevrange(k:String,s:Int,e:Int,cb:MultiReply):Void;
  function zrangebyscore(k:String,min:Int,max:Int,cb:MultiReply):Void;
  function zremrangebyrank(k:String,s:Int,e:Int,cb:IntegerReply):Void;
  function zremrangebyscore(k:String,min:Int,max:Int,cb:IntegerReply):Void;
  function zcard(k:String,cb:IntegerReply):Void;
  function zscore(k:String,e:String,cb:BulkReply):Void;
  function zunionstore(prms:Array<Dynamic>,cb:IntegerReply):Void;
  function zinterstore(prms:Array<Dynamic>,cb:IntegerReply):Void;
  function sort(prms:Array<Dynamic>,cb:MultiReply):Void;
}


class Redis {
  
 public static function newClient() :RedisClient 
 {
 	 var c = Node.require('redis');
    return untyped __js__("c.createClient()");
  }

}
