package gamestates;

import h2d.Object;
import elk.util.EasedFloat;
import elk.gamestate.GameState;

class PreloaderState extends GameState {
	var bm : h2d.Bitmap;
	var progress_txt : h2d.Text;
	var progress : EasedFloat = new EasedFloat(0.0, 0.4);
	var padding = 20.0;
	var bar : h2d.Bitmap;
	var bar_container : Object;

	var alpha_eased = EasedFloat.smootherstep_in_out(0, 2.8);

	public function new() {
		super();
	}

	override function on_enter() {
		super.on_enter();
		this.filter = new h2d.filter.Nothing();
		alpha_eased.value = 1.0;
		alpha = 0.0;

		var t = hxd.Res.preloader.placeholder.toTile();
		bm = new h2d.Bitmap(t.center(), this);
		bm.scale(100);

		progress_txt = new h2d.Text(hxd.res.DefaultFont.get(), this);
		progress_txt.textAlign = Center;

		bar_container = new Object(this);
		bar = new h2d.Bitmap(hxd.Res.preloader.progressbar.toTile(), bar_container);
		bar.height = 16;
		on_progress(0);
	}

	public function on_progress(p : Float) {
		progress_txt.text = 'Loaded ${(p * 100).toFixed(0)}%';
		progress.value = p;
	}

	override function update(dt : Float) {
		super.update(dt);
		bm.rotation += dt;
		bm.x = game.s2d.width * 0.5;
		bm.y = game.s2d.height * 0.5;
		progress_txt.x = Math.round(bm.x);
		progress_txt.y = Math.round(bm.y - progress_txt.textHeight * 0.5);
		bar.x = padding;
		bar.y = game.s2d.height - padding - bar.height;
		bar.width = (game.s2d.width - padding * 2) * progress.value;

		alpha = alpha_eased.value;
	}
}
