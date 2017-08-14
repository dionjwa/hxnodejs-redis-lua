package t9.redis;
/**
 * Melds Lua scripting with Haxe/Node.js objects.
 */

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

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

		var luaFunctionToCodeMap : Array<Expr> = [];

		for (field in fields) {
			var luaScript = getLuaScriptFromField(field, pos);
			if (luaScript != null) {
				insertLuaScriptCallInFunction(field, luaScript, pos);
				//Add the code to an internal map
				luaFunctionToCodeMap.push(macro $v{field.name} => $v{luaScript});
			}
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
					kind: FieldType.FVar(macro : js.npm.RedisClient, null),
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

		// if (!fields.exists(function(f) return f.name == VAR_NAME_SCRIPT_SHAS)) {
		// 	fields.push(
		// 		{
		// 			name: VAR_NAME_SCRIPT_SHAS_TOIDS,
		// 			access: [Access.AStatic],
		// 			kind: FieldType.FVar(macro : Map<String, String>, macro new Map()),
		// 			pos: pos,
		// 		}
		// 	);
		// }
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
				name: 'init',
				access: [Access.AStatic, Access.APublic],
				kind: FFun({
					args: [
						{
							name: 'redis',
							type: macro: js.npm.RedisClient,
							opt: false
						}
					],
					expr: Context.parse(
					'{
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
