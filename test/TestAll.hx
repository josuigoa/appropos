package;

import appropos.Appropos;

class TestAll {
	public static function main() {
        Appropos.init();
		utest.UTest.run([new MainTest()]);
	}
}
