package t9.redis;

/**
 * Just a holder for the two redis clients you'll for each server, one for
 * normal tasks, the other for listening to subscribed channels.
 */

import js.npm.redis.RedisClient;
import js.npm.Redis;
import promhx.Promise;
import promhx.RetryPromise;
import promhx.Stream;
import promhx.deferred.DeferredPromise;
import promhx.deferred.DeferredStream;

typedef RedisLogger = {
	var debug :Dynamic->?haxe.PosInfos->Void;
	var info :Dynamic->?haxe.PosInfos->Void;
	var warn :Dynamic->?haxe.PosInfos->Void;
	var error :Dynamic->?haxe.PosInfos->Void;
}

typedef RedisOpts = {
	var port :Int;
	var host :String;
	@:optional var opts :Dynamic;
	@:optional var Log :RedisLogger;
}

class ServerRedisClient
{
	public static function createClient(opts :RedisOpts) :Promise<ServerRedisClient>
	{
		return getRedisClient(opts)
			.pipe(function(c1) {
				return getRedisClient(opts)
					.then(function(c2) {
						return new ServerRedisClient(c1, c2);
					});
			});
	}
	public var client (get, null):RedisClient;
	public var subscribeClient (get, null):RedisClient;
	var Log :RedisLogger;

	var _client :RedisClient;
	var _subscribeClient :RedisClient;
	var _subscriptions :Map<String, Array<Stream<String>>> = new Map();

	function new(c1 :RedisClient, c2 :RedisClient, ?logger :RedisLogger)
	{
		_client = c1;
		_subscribeClient = c1;
		Log = logger != null ? logger : {
			debug :function(val, ?pos :haxe.PosInfos) trace(val),
			info :function(val, ?pos :haxe.PosInfos) trace(val),
			warn :function(val, ?pos :haxe.PosInfos) trace(val),
			error :function(val, ?pos :haxe.PosInfos) trace(val)
		};
	}

	function get_client() :RedisClient
	{
		return _client;
	}

	function get_subscribeClient() :RedisClient
	{
		return _subscribeClient;
	}

	static function getRedisClient(opts :RedisOpts) :Promise<RedisClient>
	{
		return promhx.RetryPromise.pollDecayingInterval(getRedisClientInternal.bind(opts), 6, 500, 'getRedisClient');
	}

	static function getRedisClientInternal(opts :RedisOpts) :Promise<RedisClient>
	{
		var Log = opts.Log;
		var redisParams = {
			port: opts.port,
			host: opts.host
		}
		var client = Redis.createClient(opts.port, opts.host, opts.opts);
		var promise = new DeferredPromise();
		client.once(RedisEvent.Connect, function() {
			if (Log != null) {
				Log.debug({event:RedisEvent.Connect, redisParams:redisParams});
			}
			//Only resolve once connected
			if (!promise.boundPromise.isResolved()) {
				promise.resolve(client);
			} else {
				if (Log != null) {
					Log.error({log:'Got redis connection, but our promise is already resolved ${redisParams.host}:${redisParams.port}'});
				}
			}
		});
		client.on(RedisEvent.Error, function(err) {
			if (!promise.boundPromise.isResolved()) {
				client.end(true);
				promise.boundPromise.reject(err);
			} else {
				if (Log != null) {
					Log.warn({event:'redis.${RedisEvent.Error}', error:err});
				} else {
					trace(err);
				}
			}
		});
		client.on(RedisEvent.Reconnecting, function(msg) {
			if (Log != null) {
				Log.warn({event:'redis.${RedisEvent.Reconnecting}', delay:msg.delay, attempt:msg.attempt});
			} else {
				trace('Redis reconnecting');
			}
		});
		client.on(RedisEvent.End, function() {
			if (Log != null) {
				Log.warn({event:RedisEvent.End, redisParams:redisParams});
			}
		});

		client.on(RedisEvent.Warning, function(warningMessage) {
			if (Log != null) {
				Log.info({event:'redis.${RedisEvent.Warning}', warning:warningMessage});
			} else {
				trace(warningMessage);
			}
		});

		return promise.boundPromise;
	}
}