package t9.redis;

/**
 * Wraps up a pair of redis connections (for sending and listened)
 * and exposes a bunch of methods for getting and sending objects
 * mostly with streams listening on the redis channels.
 */
import js.npm.RedisClient;
import promhx.Promise;
import promhx.deferred.DeferredPromise;

abstract class RedisStreams(ServerRedisClient) from ServerRedisClient
{
	inline public function new(s:ServerRedisClient)
	{
		this = s;
	}

	/**
	 * Returns a stream of the channel. The stream is destroyed
	 * when the returned stream is end()'ed
	 * @param  channelKey :String       [description]
	 * @return            [description]
	 */
	public function subscribe(channelKey :String) :Stream<String>
	{
		var deferred = new DeferredStream<T>();

		//Send a null message when the channel is subscribed
		//if no message has yet been sent, this helps downstream
		//by notifying the streams that the channel is now
		//listened to
		var hasRecievedMessage = false;
		if (!this._subscriptions.exists(channelKey)) {
			this._subscribeClient.subscribe(channelKey);
			this._subscriptions.set(channelKey, []);
			this._subscribeClient.once(RedisClient.EVENT_SUBSCRIBE, function (channel, count) {
				if (channel == channelKey) {
					if (!hasRecievedMessage) {
						hasRecievedMessage = true;
						this._subscriptions.get(channelKey).iter(function(stream) {
							deferred.resolve(null);
						});
					}
				}
			});
		}

		this._subscriptions.get(channelKey).push(deferred);

		this._subscribeClient.addListener(RedisClient.EVENT_MESSAGE, function (channel, message) {
			if (channel == channelKey) {
				hasRecievedMessage = true;
				deferred.resolve(message);
			}
		});

		deferred.boundStream.endThen(function(_) {
			//Remove the stream from the channelKey map
			this._subscriptions.get(channelKey).splice(_subscriptions.get(channelKey).indexOf(deferred), 1);
			if (this._subscriptions.get(channelKey).length == 0) {
				this._subscribeClient.unsubscribe(channelKey);
			}
		});

		return deferred;
	}

	public function createStreamCustom<T>(channelKey :String, getter :Dynamic->Promise<T>) :Stream<T>
	{
		Assert.notNull(channelKey);

		var subscribeStream = this.subscribe(channelKey);

		var deferred = new DeferredStream<T>();

		//End the primary stream if the returned stream is ended
		deferred.boundStream.endThen(function(_) {
			subscribeStream.end();
		});

		function getAndSend(message :Dynamic) {
			var promise = getter(message);
			if (promise != null) {
				promise.then(function(val :T) {
					if (val != null) {
						deferred.resolve(val);
					}
				});
			} else {
				this.Log.error('createStreamCustomInternal channelKey=$channelKey getter returned null');
			}
		}

		subscribeStream.then(function(val) {
			getAndSend(val);
		});

		return deferred.boundStream;
	}

	/**
	 * This ensures you get the latest value from the hash set.
	 * It will get the current value, then also it will get the
	 * current value whenever the channel (from the channelKey)
	 * is updated.
	 */
	public function createStreamFromHash<T>(channelKey :String, hashKey :String, hashField :String) :Stream<T>
	{
		return this.createStreamCustom(channelKey, function(_) {
			return cast RedisPromises.hget(this._client, hashKey, hashField);
		});
	}

	public function createJsonStreamFromHash<T>(channelKey :String, hashKey :String, hashField :String) :Stream<T>
	{
		return this.createStreamCustom(channelKey, function(_) {
			return RedisPromises.hget(this._client, hashKey, hashField)
				.then(function(s) {
					return Json.parse(s);
				});
		});
	}

	public function createJsonStream<T>(channelKey :String, ?redisKey :String, ?usePatterns :Bool = false #if debug ,?pos:haxe.PosInfos #end) :Stream<T>
	{
		if (redisKey == null) {
			redisKey = channelKey;
		}
		return this.createStreamCustom(channelKey, function(message) {
				var promise = new DeferredPromise<T>(#if debug pos #end);
				this._client.get(redisKey, function(err :Dynamic, val) {
					if (err != null) {
						promise.boundPromise.reject(err);
						return;
					}
					promise.resolve(Json.parse(val));
				});
				return promise.boundPromise;
		});
	}

	public function sendJsonStreamedValue(key :String, val :Dynamic) :Promise<Bool>
	{
		var deferred = new DeferredPromise<Bool>();
		var s = Json.stringify(val);
		return sendStreamedValue(key, s);
	}

	public function sendStreamedValue(key :String, val :Dynamic) :Promise<Bool>
	{
		var deferred = new DeferredPromise<Bool>();
		this._client.set(key, val, function(err, success) {
			if (err != null) {
				deferred.boundPromise.reject(err);
				return;
			}
			this._client.publish(key, val);
			deferred.resolve(true);
		});
		return deferred.boundPromise;
	}
}