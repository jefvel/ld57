package haxe;

import h3d.impl.Driver;
import h3d.mat.Data.TextureFormat;

typedef GPUBuffer = {};
typedef Texture = {};
typedef Query = {};

class GraphicsDriver extends Driver {
	public function new(antiAlias:Int) {}

	public static var nativeFormat = TextureFormat.RGBA;

	public override function init(onCreate:Bool->Void, forceSoftware = false) {
		onCreate(false);
	}
}
