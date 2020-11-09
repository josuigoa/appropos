# Appropos

Inspired by [Spring Value annotation](https://www.baeldung.com/spring-value-annotation) to get runtime values from a external properties file. By default is called `app.props` and it must be in the same folder as the executing file.

## Usage

Use the `:v` or `:value` annotation to bind the [class variables](https://haxe.org/manual/class-field-variable.html) to a value from a properties file. 

```haxe
@:v('app.props.test.float') // same as @:value('app.props.test.float')
static var numericFloat:Float;
```

This piece of code injects at *runtime* the `app.props.test.float` value from the properties file into the class variable. You can give a default value with after a `:`, if there is no this key in the `app.props` file.

```haxe
@:v('app.props.test.float:100')
static var default100:Float;
```

### More complex types

The handled types by default are Float/Int/String/Bool. If you need a more complex type you can alwasy use an abstract:

```haxe
@:arrayAccess
abstract AbsArray(Array<Float>) from Array<Float> {
    @:from static inline function fromString(s:String):AbsArray
        return [for (n in s.split(',')) Std.parseFloat(n)];
}
...

@:v('app.props.test.abstract') // 1.32,2.25,3.98
static var abstractArray:AbsArray; // [1.32, 2.25, 3.98]
```

To get this running, you need to call to the build macro `@:build(appropos.Appropos.generate())` in the classes where you are using `:v` annotations. And is necessary to initialize with `appropos.Appropos.init();`

There is a complete example of the usage in the `test/MainTest.hx` file.

## How it works

`appropos.Appropos.init();` is called to read the file content and fills a `Map<String, String>` with the keys and values from the given property file at *runtime*. This file by default is `app.props` and is in the same folder as the executable. The path of this file can be passed as parameter to de `appropos.Appropos.init();` function.

A macro creates all the code needed to read the file and inject the values in properties. The created code basically is:

* Take every class variable marked with `:v` or `:value`.
* Extract the `key`.
* Each variable is set to [class property](https://haxe.org/manual/class-field-property.html).
* Create a getter called `get_xxx` (where xxx is the variable name). This getter returns the value attached to the `key` in the `appropos.Appropos.properties`. The setter is disabled.
