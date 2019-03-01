package t9.redis;
/**
 * Melds Lua scripting with Haxe/Node.js objects.
 */

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;
using StringTools;

class RedisObject
{
	static var META_KEY_REDIS = 'redis';
	static var META_KEY_LUA = 'lua';
	static var VAR_NAME_REDIS_CLIENT = 'REDIS_CLIENT';
	static var VAR_NAME_SCRIPTS = 'SCRIPTS';
	static var VAR_NAME_SCRIPT_SHAS = 'SCRIPT_SHAS';
	static var VAR_NAME_SCRIPT_SHAS_TOIDS = 'SCRIPT_SHAS_TOIDS';
	static var VAR_NAME_EVALUATE_SCRIPT = 'EVALULATE_SCRIPT';

	macro static public function build() :Array<Field>
	{
		var fields = Context.getBuildFields();

		var pos = haxe.macro.Context.currentPos();

		createScriptsFields(fields, pos);
		var luaScripts = new Map<String,String>();

		for (field in fields) {
			var luaScript = getLuaScriptFromField(field, pos);
			if (luaScript != null) {
				//Add the code to an internal map
				luaScripts.set(field.name, luaScript);
				insertLuaScriptCallInFunction(field, luaScript, pos);
			}
		}
		//Either add the lua scripts to an existing map variable,
		//or create a new var
		var scriptsField = fields.find(function(f) return f.name == VAR_NAME_SCRIPTS);
		if (scriptsField != null) {
			switch(scriptsField.kind) {
				case FVar(t, e):
					switch(t) {
						case TPath(pathData):
							if (pathData.name != 'Map') {
								Context.error('${Context.getLocalModule()}: VAR_NAME_SCRIPTS variable must be a Map<String,String>', pos);
							}
						default:
							Context.error('${Context.getLocalModule()}: VAR_NAME_SCRIPTS variable must be a Map<String,String>', pos);
					}
					switch(e.expr) {
						case EArrayDecl(arrayOfExpr):
							for (name in luaScripts.keys()) {
								arrayOfExpr.push(macro $v{name} => $v{luaScripts.get(name)});
							}
						default:
							Context.error('${Context.getLocalModule()}: VAR_NAME_SCRIPTS variable must be a Map<String,String> declared inline: https://haxe.org/manual/std-Map.html', pos);
					}
				default:
					Context.error('${Context.getLocalModule()}: VAR_NAME_SCRIPTS variable must be a Map<String,String>', pos);
				}
		} else {
			if (luaScripts.keys().hasNext()) {
				var luaFunctionToCodeMap : Array<Expr> = [];
				for (name in luaScripts.keys()) {
					luaFunctionToCodeMap.push(macro $v{name} => $v{luaScripts.get(name)});
				}
				fields.push({
					// The line position that will be referenced on error
					pos: pos,
					// Field name
					name: VAR_NAME_SCRIPTS,
					// Attached metadata (we are not adding any)
					meta: null,
					// Field type is Map<String, String>, `luaFunctionToCodeMap` is the map
					kind: FieldType.FVar(macro : Map<String, String>, macro $a{luaFunctionToCodeMap}),
					// Documentation (we are not adding any)
					doc: null,
					// Field visibility
					access: [Access.AStatic]
				});
			}
		}

		return fields;
	}

#if macro
	static function insertLuaScriptCallInFunction(field :Field, script :String, pos :Position)
	{
		switch(field.kind) {
			case FFun(func):
				var argString = func.args == null ? '' : func.args.map(function(arg) {
					return arg.name;
				}).join(', ');
				argString = '[ $argString ]';
				func.expr = Context.parse(
					'{
						return $VAR_NAME_EVALUATE_SCRIPT("${field.name}", $argString);
					}', pos);
			default:
				Context.error('${Context.getLocalModule()}: @redis({lua:...}) metadata can only be applied to a function.', pos);
		}
	}

	static function getLuaScriptFromField(field :Field, pos :Position) :String
	{
		if (field.meta != null) {
			for (metaEntry in field.meta) {
				if (metaEntry.name == META_KEY_REDIS) {
					if (field.access != null && field.access.indexOf(Access.AStatic) == -1) {
						Context.error('${Context.getLocalModule()}: @redis(...) can only be added to static fields, since multiple redis clients per server makes little sense', pos);
					}
					if (metaEntry.params != null) {
						for (metaEntryParam in metaEntry.params) {
							switch(metaEntryParam.expr) {
								case EObjectDecl(metaEntryParamFields):
									for (metaEntryParamField in metaEntryParamFields) {
										var fieldName = metaEntryParamField.field;
										var fieldExpr = metaEntryParamField.expr;
										if (fieldName == META_KEY_LUA) {
											switch(fieldExpr.expr) {
												case EConst(const):
													switch(const) {
														case CString(s):
															return s;
															// trace('s=${s}');
														default:
															Context.error('${Context.getLocalModule()}: @redis({lua:...}) expects an object declaration with a "lua" field that contains a string', pos);
													}
												default:
													Context.error('${Context.getLocalModule()}: @redis({lua:...}) expects an object declaration with a "lua" field that contains a string', pos);
											}
										} else {
											Context.error('${Context.getLocalModule()}: @redis({}) expects an object declaration with a "lua" field', pos);
										}
									}
								default:
									Context.error('${Context.getLocalModule()}: @redis(...) expects an object declaration', pos);
							}
						}
					} else {
						Context.error('${Context.getLocalModule()}: @redis needs a lua key', pos);
					}
				}
			}
		}
		return null;
	}

	/**
	 * Adds: static var scripts :Map<String, String>
	 */
	static function createScriptsFields(fields :Array<Field>, pos :Position)
	{
		if (!fields.exists(function(f) return f.name == VAR_NAME_REDIS_CLIENT)) {
			fields.push(
				{
					name: VAR_NAME_REDIS_CLIENT,
					access: [Access.AStatic],
					kind: FieldType.FVar(macro : js.npm.redis.RedisClient, null),
					pos: pos,
				}
			);
		}
		if (!fields.exists(function(f) return f.name == VAR_NAME_SCRIPT_SHAS)) {
			fields.push(
				{
					name: VAR_NAME_SCRIPT_SHAS,
					access: [Access.AStatic],
					kind: FieldType.FVar(macro : Map<String, String>, macro new Map()),
					pos: pos,
				}
			);
		}
		if (!fields.exists(function(f) return f.name == VAR_NAME_SCRIPT_SHAS_TOIDS)) {
			fields.push(
				{
					name: VAR_NAME_SCRIPT_SHAS_TOIDS,
					access: [Access.AStatic],
					kind: FieldType.FVar(macro : Map<String, String>, macro new Map()),
					pos: pos,
				}
			);
		}

		fields.push(
			{
				name: VAR_NAME_EVALUATE_SCRIPT,
				access: [Access.AStatic],
				kind: FFun({
					args: [
						{
							name: 'scriptKey',
							type: macro : String,
							opt: false
						},
						{
							name: 'args',
							type: macro: Array<Dynamic>,
							opt: true
						},
					],
					expr: Context.parse(
						"{\n" +
							'return t9.redis.RedisLuaTools.evaluateLuaScript($VAR_NAME_REDIS_CLIENT, $VAR_NAME_SCRIPT_SHAS[scriptKey], null, args, $VAR_NAME_SCRIPT_SHAS_TOIDS, $VAR_NAME_SCRIPTS);\n' +
						"}"
						, pos),
					params: [{name:'T'}],
					ret: ComplexType.TPath({name:'Promise',pack:['promhx'], params:[TypeParam.TPType(ComplexType.TPath({name:'T',pack:[]}))]}),
				}),
				pos: pos,
			}
		);
		fields.push(
			{
				name: 'scriptsToString',
				access: [Access.APublic, Access.AStatic],
				kind: FFun({
					args: [],
					expr: Context.parse(
						'{
							var obj = {};\n
							for (k in $VAR_NAME_SCRIPTS.keys()) {
								Reflect.setField(obj, k, $VAR_NAME_SCRIPTS.get(k));\n
							}
							return "" + obj;//haxe.Json.stringify(obj, null, "  ");\n
						}'
						, pos),
					params: [],
					ret: ComplexType.TPath({name:'String',pack:[]}),
				}),
				pos: pos,
			}
		);
		var scriptReplaceEreg = '.*(\\\\$${?[a-zA-Z0-9_]+}?).*';
		fields.push(
			{
				name: 'init',
				access: [Access.AStatic, Access.APublic],
				kind: FFun({
					args: [
						{
							name: 'redis',
							type: macro: js.npm.redis.RedisClient,
							opt: false
						}
					],
					expr: Context.parse(
					'{
						if (redis == null) {
							throw "redis argument null";
						}
						for (key in $VAR_NAME_SCRIPTS.keys()) {
							var script = $VAR_NAME_SCRIPTS.get(key);
							for (classFieldName in Type.getClassFields(${Context.getLocalModule()})) {
								var classFieldContent = Reflect.field(${Context.getLocalModule()}, classFieldName);
								script = StringTools.replace(script, "$${" + classFieldName + "}", classFieldContent);
							}

							for (key2 in $VAR_NAME_SCRIPTS.keys()) {
								var otherScript = $VAR_NAME_SCRIPTS.get(key2);
								script = StringTools.replace(script, "$${" + key2 + "}", otherScript);
							}

							$VAR_NAME_SCRIPTS.set(key, script);
						}
						$VAR_NAME_REDIS_CLIENT = redis;
						return t9.redis.RedisLuaTools.initLuaScripts($VAR_NAME_REDIS_CLIENT, $VAR_NAME_SCRIPTS)
							.then(function(scriptIdsToShas :Map<String, String>) {
								$VAR_NAME_SCRIPT_SHAS = scriptIdsToShas;
								//This helps with debugging the lua scripts, uses the name instead of the hash
								$VAR_NAME_SCRIPT_SHAS_TOIDS = new Map();
								for (key in ${VAR_NAME_SCRIPT_SHAS}.keys()) {
									$VAR_NAME_SCRIPT_SHAS_TOIDS[$VAR_NAME_SCRIPT_SHAS[key]] = key;
								}
								return $VAR_NAME_SCRIPT_SHAS != null;
							});
					}', pos),
					ret: ComplexType.TPath({name:'Promise',pack:['promhx'], params:[TypeParam.TPType(ComplexType.TPath({name:'Bool',pack:[]}))]}),
				}),
				pos: pos,
			}
		);
	}
#end
}
