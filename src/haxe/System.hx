package haxe;

import hxd.Event;

class System {
	public static var width = 1;
	public static var height = 1;
	public static var vsync = false;

	public static var name = "Dummy";

	public static var errorHandler:String->Void = null;

	public static function init() {
		return true;
	}

	public static function beginFrame() {}

	public static function reportError(err) {
		// trace('err rep: $err');
		if (errorHandler != null)
			errorHandler(err);
	}

	public static function emitEvents(onEvent:Event->Bool) {
		return true;
	}
}
