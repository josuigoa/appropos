package;

import utest.Assert;

class MainTest extends utest.Test {
    
	@:v('app.props.test.float')
	static var numericFloat:Float;
    
	@:v('app.props.test.int')
    static var numericInt:Int;
    
	@:v('app.props.test.uint')
	static var numericUInt:UInt;
    
	@:v('app.props.test.string')
	static var string:String;
    
	@:v('app.props.test.string.spaces')
    static var stringSpaces:String;
    
	@:v('app.props.test.no.exists')
	static var notExists:String;
    
	@:v('app.props.test.no.exists:default value')
	static var notExistsWithDefault:String;
    
	@:v('app.props.test.commented')
	static var commented:String;

	function testFieldNumericFloat() {
		Assert.equals(10.5, numericFloat);
		Assert.equals(-10, numericInt);
		Assert.equals(10, numericUInt);
		Assert.equals("10_string", string);
		Assert.equals("this is a test", stringSpaces);
		Assert.equals("default value", notExistsWithDefault);
		Assert.isNull(notExists);
		Assert.isNull(commented);
	}
}
