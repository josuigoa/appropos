package appropos;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;
#end

class Appropos {
	static var propsFilePath:String;
	static var properties:Map<String, String>;

	static public function get(key:String, defaultValue:String) {
		if (properties == null || !properties.exists(key))
			return defaultValue;
		return properties.get(key);
	}

	static public function init(?filePath:String) {
		propsFilePath = (filePath != null) ? filePath : 'app.props';

		try {
			properties = new Map();
			var props = sys.io.File.getContent(propsFilePath);
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

	@:noCompletion
	static public function updateProps(propsArray:Array<{key:String, value:String}>) {
		var propsContent = sys.io.File.getContent(propsFilePath);
		var lines = ~/\r?\n/g.split(propsContent);
		var found = false;

		for (p in propsArray) {
			found = false;
			for (i in 0...lines.length) {
				if (lines[i].startsWith(p.key)) {
					found = true;
					lines[i] = '${p.key}=${p.value}';
					break;
				}
			}
			if (!found)
				lines.push('${p.key}=${p.value}');
		}

		sys.io.File.saveContent(propsFilePath, lines.join('\n'));
	}

	#if macro
	static public function generate() {
		var readOnlyValue = Context.definedValue('appropos_read_only');
		if (readOnlyValue == null)
			readOnlyValue = 'true';
		var readOnly = readOnlyValue == 'true';
		var fields = Context.getBuildFields();
		var fgets = [], valueId, valueKey, valueDefault, colonInd, pos = Context.currentPos();
		for (field in fields) {
			switch field.kind {
				case FVar(t, _):
					for (meta in field.meta) {
						switch meta.name {
							case ':value' | ':v':
								if (t == null)
									t = macro :String;
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
								field.kind = FProp('get', readOnly ? 'never' : 'set', t);
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

								if (!readOnly) {
									field.meta.push({name: ':isVar', pos: pos});
									fgets.push({
										name: 'set_' + field.name,
										pos: pos,
										meta: [{name: ":dce", params: [], pos: pos}],
										kind: FFun({
											args: [
												{
													name: 'newValue'
												}
											],
											params: [],
											ret: t,
											expr: macro {
												appropos.Appropos.updateProps([{key: $v{valueKey}, value: '$newValue'}]);
												return $i{field.name} = newValue;
											}
										}),
										access: field.access
									});
								}
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
