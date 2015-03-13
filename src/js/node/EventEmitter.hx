package js.node;

typedef NodeListener = Dynamic;
typedef NodeErr = Null<String>;

extern class NodeEventEmitter
{
	public function addListener(event:String,fn:NodeListener):Dynamic;
	public function on(event:String,fn:NodeListener):Dynamic;
	public function once(event:String,fn:NodeListener):Void;
	public function removeListener(event:String,listener:NodeListener):Void;
	public function removeAllListeners(event:String):Void;
	public function listeners(event:String):Array<NodeListener>;
	public function setMaxListeners(m:Int):Void;
	public function emit(event:String,?arg1:Dynamic,?arg2:Dynamic,?arg3:Dynamic):Void;
}