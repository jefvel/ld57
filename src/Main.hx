import gamestates.PlayState;
import gamestates.PreloaderState;

typedef MPClient = net.MultiplayerPlayer;

class Main extends elk.Elk {
	static var app : elk.Elk;

	var preloader : PreloaderState;

	override function on_ready() {
		super.on_ready();

		app.states.change(new PlayState());
	}

	override function init() {
		super.init();

		if( !is_ready ) {
			preloader = new PreloaderState();
			app.states.change(preloader);
		}
	}

	override public function on_load_progress(p : Float) {
		preloader.on_progress(p);
	}

	override function update(dt : Float) {
		super.update(dt);
	}

	public static function main() {
		#if sys
		sys.ssl.Socket.DEFAULT_VERIFY_CERT = false;
		#end
		app = new Main(60, 3);
	}
}
