package appropos;

import sys.io.File;
using StringTools;
#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
#end

class Appropos {
	
	static var properties:Map<String, Any>;
	
	static public function get(key:String) {
		if (properties == null)
			return null;
		return properties.get(key);
	}
	
	static macro function _init(_basePackage:ExprOf<String>) {
		var basePackage = switch _basePackage.expr {
			case EConst(c):
				switch c {
					case CString(s, kind): s;
					case _: '';
				}
			case _: '';
		}
		Compiler.addGlobalMetadata(basePackage, '@:build(appropos.Appropos.generate())');
		return macro null;
	}
	
	static public function init(basePackage:String = '') {
		
		_init(basePackage);
		
		try {
			properties = new Map();
			var props = File.getContent('app.props');
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
		} catch (e:Dynamic) {
			trace('error: $e');
		}
	}
	
	#if macro
	static public function generate() {
		var fields = Context.getBuildFields();
		var fgets = [], valueId, pos = Context.currentPos();
		for (field in fields) {
			for (meta in field.meta) {
				switch meta.name {
					case ':value' | ':v':
						switch field.kind {
							case FVar(t, _):
								if (t == null)
									t = macro :String;
								valueId = extractKey(meta.params[0]);
								if (valueId == '')
									continue;
								field.kind = FProp('get', 'never', t);
								fgets.push({
									name: 'get_' + field.name,
									pos: pos,
									meta: [{ name : ":dce", params : [], pos : pos }],
									kind: FFun({
										args: [],
										params: [],
										ret: t,
										expr: {expr: getReturnExpr(t, valueId), pos:pos}
									}),
									access: field.access
								});
							case _:
						}
						
	
				}
			}
		}
		return fields.concat(fgets);
	}
	
	static function extractKey(expr:Expr) {
		return switch expr.expr {
			case EConst(c):
				switch c {
					case CInt(v) | CFloat(v):
						Std.string(v);
					case CString(s, kind):
						s;
					case _:
						'';
				}
			case _:
				'';
		}
	}
	
	static function getReturnExpr(t:ComplexType, valueId:String) {
		return switch t {
			case TPath(p):
				switch p.name {
					case 'Float':
						EReturn(macro Std.parseFloat(appropos.Appropos.get($v{valueId})));
					case 'Int' | 'UInt':
						EReturn(macro Std.parseInt(appropos.Appropos.get($v{valueId})));
					case _:
						EReturn(macro appropos.Appropos.get($v{valueId}));
				}
			case TOptional(t):
				getReturnExpr(t, valueId);
			case TNamed(n, t):
				getReturnExpr(t, valueId);
			case _:
				EReturn(macro null);
		}
	}
	#end
	
	static function main() {}
}
