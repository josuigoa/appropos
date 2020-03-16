package;

import utest.Assert;

@:arrayAccess
abstract AbsArray(Array<Float>) from Array<Float> {
	@:from static inline function fromString(s:String):AbsArray
		return [for (n in s.split(',')) Std.parseFloat(n)];
}

class MainTest extends utest.Test {
    
	@:v('app.props.test.float')
	static var numericFloat:Float;
    
	@:v('app.props.test.int')
    static var numericInt:Int;
    
	@:v('app.props.test.uint')
	static var numericUInt:UInt;
    
	@:v('app.props.test.bool')
	static var bool:Bool;
    
	@:v('app.props.test.string')
	static var string:String;
    
	@:v('app.props.test.string.spaces')
    static var stringSpaces:String;
    
	@:v('app.props.test.abstract')
    static var abstractArray:AbsArray;
    
	@:v('app.props.test.no.exists')
	static var notExists:String;
    
	@:v('app.props.test.no.exists:1.5')
	static var notExistsFloatWithDefault:Float;
	
	@:v('app.props.test.no.exists:20')
	static var notExistsIntWithDefault:Int;
    
	@:v('app.props.test.no.exists:default value')
	static var notExistsStringWithDefault:String;
    
	@:v('app.props.test.commented')
	static var commented:String;

	function testProperties() {
		Assert.floatEquals(10.5, numericFloat);
		Assert.equals(-10, numericInt);
		Assert.equals(10, numericUInt);
		Assert.isTrue(bool);
		Assert.equals("10_string", string);
		Assert.equals("this is a test", stringSpaces);
		
		var expectedArray = [1.32, 2.25, 3.98];
		for (i in 0...expectedArray.length)
			Assert.floatEquals(expectedArray[i], abstractArray[i]);

		Assert.equals(1.5, notExistsFloatWithDefault);
		Assert.equals(20, notExistsIntWithDefault);
		Assert.equals("default value", notExistsStringWithDefault);
		Assert.isNull(notExists);
		Assert.isNull(commented);
	}
}
