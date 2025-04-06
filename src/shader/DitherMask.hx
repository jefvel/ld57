package shader;

import h3d.Vector;
import h3d.mat.Texture;
import h2d.RenderContext;
import h2d.filter.AbstractMask;

class DitherMask extends AbstractMask {
	var pass : h3d.pass.ScreenFx<DitherShader>;

	/**
		Enables masking Object alpha merging. Otherwise causes unsmoothed masking of non-zero alpha areas.
	**/
	public var smoothAlpha(get, set) : Bool;

	public var bias(get, set) : Float;
	public var offset(get, set) : Vector;

	var bayer : Texture;

	public function new(mask, maskVisible = false, smoothAlpha = false) {
		super(mask);
		pass = new h3d.pass.ScreenFx(new DitherShader());
		this.maskVisible = maskVisible;
		this.smoothAlpha = smoothAlpha;
		bayer = hxd.Res.img.bayer8.toTexture();
		bayer.filter = Nearest;
		bayer.wrap = Repeat;
	}

	function get_smoothAlpha()
		return pass.shader.smoothAlpha;

	function set_smoothAlpha(v)
		return pass.shader.smoothAlpha = v;

	function get_bias()
		return pass.shader.bias;

	function set_bias(v)
		return pass.shader.bias = v;

	function get_offset()
		return pass.shader.offset;

	function set_offset(v)
		return pass.shader.offset = v;

	override function draw(ctx : RenderContext, t : h2d.Tile) {
		var mask = getMaskTexture(ctx, t);
		if( mask == null ) {
			if( this.mask == null ) throw "Mask filter has no mask object";
			return null;
		}

		var game = elk.Elk.instance;
		pass.shader.screenSize.set(game.s2d.width, game.s2d.height);
		ctx.globals.set('ditherMatrix', bayer);

		var out = ctx.textures.allocTileTarget("maskTmp", t);
		ctx.engine.pushTarget(out);
		pass.shader.texture = t.getTexture();
		pass.shader.mask = getMaskTexture(ctx, t);
		pass.shader.maskMatA.set(maskMatrix.a, maskMatrix.c, maskMatrix.x);
		pass.shader.maskMatB.set(maskMatrix.b, maskMatrix.d, maskMatrix.y);
		pass.render();
		ctx.engine.popTarget();
		return h2d.Tile.fromTexture(out);
	}
}
