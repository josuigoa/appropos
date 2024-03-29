package appropos;

import sys.io.File;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
#end

class Appropos {
	static var properties:Map<String, String>;

	static public function get(key:String, defaultValue:String) {
		if (properties == null || !properties.exists(key))
			return defaultValue;
		return properties.get(key);
	}

	static public function init(?filePath:String) {
		var approposPathIndex = Sys.args().indexOf('-appropos');
		if (approposPathIndex != -1) {
			trace("Reading props from: " + Sys.args()[approposPathIndex + 1]);
			filePath = Sys.args()[approposPathIndex + 1];
		} else if (filePath == null) {
			filePath = 'app.props';
		}

		try {
			properties = new Map();
			var props = File.getContent(filePath);
			var key, value;
			var ereg = ~/([#\w\._-]+)?(?==)=(.+\n?)/g;
			while (ereg.match(props)) {
				key = ereg.matched(1);
				value = ~/\r?\n/.replace(ereg.matched(2), '');
				if (key.startsWith('#')) {
					props = ereg.matchedRight();
					continue;
				}
				properties.set(key, value);
				props = ereg.matchedRight();
			}
		#if (haxe_ver >= 4.1)
		} catch (e:haxe.Exception)
		{
			trace('Exception: ${e.stack}');
		#else
		} catch (e:Dynamic)
		{
			trace('Exception: $e');
		#end
		}
	}

	#if macro
	static public function generate() {
		var fields = Context.getBuildFields();
		var fgets = [],
			valueId,
			valueKey,
			valueDefault,
			colonInd,
			pos = Context.currentPos();
		for (field in fields) {
			switch field.kind {
				case FVar(t, _):
					for (meta in field.meta) {
						switch meta.name {
							case ':value' | ':v':
								if (t == null)
									t = macro:String;
								valueId = extractKey(meta.params[0]);
								if (valueId == '')
									continue;
								colonInd = valueId.indexOf(':');
								if (colonInd != -1) {
									valueKey = valueId.substring(0, colonInd);
									valueDefault = valueId.replace(valueKey + ':', '');
									if (valueDefault == '')
										valueDefault = null;
								} else {
									valueKey = valueId;
									valueDefault = null;
								}
								field.kind = FProp('get', 'never', t);
								fgets.push({
									name: 'get_' + field.name,
									pos: pos,
									meta: [{name: ":dce", params: [], pos: pos}],
									kind: FFun({
										args: [],
										params: [],
										ret: t,
										expr: {expr: EReturn(getReturnExpr(t, valueKey, valueDefault)), pos: pos}
									}),
									access: field.access
								});
						}
					}
				case _:
			}
		}
		return fields.concat(fgets);
	}

	static function extractKey(expr:Expr) {
		return switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v) | CFloat(v): Std.string(v);
					case CString(s, kind): s;
					case _: '';
				}
			case _: '';
		}
	}

	static function getReturnExpr(t:ComplexType, valueKey:String, valueDefault:String) {
		return switch t {
			case TPath(p):
				switch p.name {
					case 'Float':
						macro Std.parseFloat(appropos.Appropos.get($v{valueKey}, $v{valueDefault}));
					case 'Bool':
						macro appropos.Appropos.get($v{valueKey}, $v{valueDefault}).toLowerCase() == 'true';
					case 'Int' | 'UInt':
						macro Std.parseInt(appropos.Appropos.get($v{valueKey}, $v{valueDefault}));
					case _:
						macro appropos.Appropos.get($v{valueKey}, $v{valueDefault});
				}
			case TOptional(t):
				getReturnExpr(t, valueKey, valueDefault);
			case TNamed(n, t):
				getReturnExpr(t, valueKey, valueDefault);
			case _:
				macro null;
		}
	}
	#end
}
