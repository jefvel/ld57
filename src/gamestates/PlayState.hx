package gamestates;

import hxd.snd.effect.LowPass;
import hxd.snd.effect.Pitch;
import h2d.TileGroup;
import elk.graphics.Sprite;
import elk.Timeout;
import shader.DitherMask;
import h2d.Tile;
import h2d.Bitmap;
import h2d.RenderContext;
import h2d.Camera;
import entities.Man;
import elk.gamestate.GameState;
import elk.input.Joystick;
import h2d.Layers;
import h2d.Object;
import h2d.Text;
import haxe.io.Bytes;
import net.MultiplayerHandler;

class PlayState extends GameState {
	var time = 0.;
	var tickRateTxt : Text;

	var intX = new elk.util.InterpolatedFloat();

	public static var instance : PlayState;

	public var container = new Object();
	public var world = new Object();
	public var levelTiles = new Object();
	public var bgLayer = new Object();
	public var objects : Layers;

	public static var host : elk.net.Client;

	var spawnPoint : assets.LDTKProject.Entity_SpawnPoint;
	var man : Man;

	var camera : Camera;

	var dither : DitherMask;
	var bg : Bitmap;
	var lights : Object;
	var levelLights : Object = new Object();

	var tutorialContainer : Object;
	var tutorial : Sprite;

	var musicIndex = 0;
	var musics = [
		hxd.Res.music.music1,
		hxd.Res.music.music2,
		hxd.Res.music.music3,
		hxd.Res.music.music4,
		hxd.Res.music.music5,
	];

	var music_thresholds : Array<assets.LDTKProject.Entity_MusicChange> = [];
	var playing : Array<hxd.snd.Channel> = [];

	public var levels : Array<assets.LDTKProject.LDTKProject_Level> = [];

	public static var deaths = 0;
	public static var playTime = 0.0;

	public var runTime = 0.0;

	public static var candlePositions : Array<{x : Float, y : Float}> = [];

	public var winY = 999999.0;

	override function on_enter() {
		instance = this;

		world.addChild(bgLayer);
		world.addChild(levelTiles);
		container.addChild(world);

		bg = new Bitmap(Tile.fromColor(0x000000), this);
		bg.width = game.s2d.width;
		bg.height = game.s2d.height;

		lights = new Object(world);
		lights.addChild(levelLights);

		dither = new DitherMask(lights);
		dither.bias = 1;
		dither.smoothAlpha = true;

		addChild(container);
		container.filter = dither; // new h2d.filter.Nothing();
		this.filter = new elk.graphics.filter.RetroFilter(1.5, 0.2, 0.01);

		camera = game.s2d.camera;

		objects = new Layers(world);
		tutorialContainer = new Object(world);

		loadMap();

		#if debug
		hxd.Res.levels.map.watch(() -> {
			loadMap();
		});

		game.console.addCommand('l', '', [], () -> {
			if( container.filter != null ) container.filter = null;
			else container.filter = dither;
		});

		game.console.addCommand('bias', '', [{name : 'alpha', t : AFloat}], (a) -> {
			dither.bias = a;
		});

		game.console.addCommand('godmode', '', [], (a) -> {
			man.freeMove = !man.freeMove;
		});
		#end

		man = new Man(objects);
		man.teleport(spawnPoint.worldPixelX, spawnPoint.worldPixelY);

		lights.addChild(man.light);

		joystick = new Joystick(Left, this);

		// pitch = game.sounds.musicChannel.getEffect(LowPass);
		pitch = game.sounds.musicChannel.getEffect(Pitch);
		if( pitch == null ) {
			// pitch = new hxd.snd.effect.LowPass();
			pitch = new hxd.snd.effect.Pitch(1);
			game.sounds.musicChannel.addEffect(pitch);
		}
		pitch.value = 1.0;
		// pitch.gainHF = 1.0;

		// connect();
	}

	function loadMap() {
		levelTiles.removeChildren();
		levelLights.removeChildren();
		bgLayer.removeChildren();
		levels = [];
		music_thresholds = [];

		var smallLight = hxd.Res.img.small_light.toTile().center();
		var l = new assets.LDTKProject(hxd.Res.levels.map.entry.getJsonText());
		for (level in l.all_worlds.Default.levels) {
			bgLayer.addChild(level.l_Tiles.render());
			var tg = level.l_AutoLayer.render();
			for (e in level.l_Entities.all_SpawnPoint) {
				spawnPoint = e;
			}
			levels.push(level);

			tg.x = level.worldX;
			tg.y = level.worldY;
			levelTiles.addChild(tg);
			for (l in level.l_Entities.all_Light) {
				var li = new Bitmap(smallLight, levelLights);
				li.x = l.worldPixelX;
				li.y = l.worldPixelY;
				var c = hxd.Res.img.candle.toSprite(objects);
				c.set_origin(0.5, 0.6);
				c.x = li.x;
				c.y = li.y;
				c.animation.play('idle');
			}

			for (c in level.l_Entities.all_Cake) {
				var cao = new Bitmap(hxd.Res.img.cake.toTile(), objects);
				cao.x = c.worldPixelX;
				cao.y = c.worldPixelY;
			}

			for (w in level.l_Entities.all_FinishLine) {
				winY = w.worldPixelY;
			}

			if( deaths < 5 ) for (t in level.l_Entities.all_Tutorial) {
				tutorial = hxd.Res.img.tutorial.toSprite(tutorialContainer);
				tutorial.x = t.worldPixelX;
				tutorial.y = t.worldPixelY;
				var tutorialMask = hxd.Res.img.tutorial.toSprite();
				lights.addChild(tutorialMask);
				tutorial.animation.pause = true;
				tutorialMask.animation.pause = true;
				tutorialMask.x = tutorial.x;
				tutorialMask.y = tutorial.y;
				tutorial.animation.currentFrameIndex = switch (t.f_TutorialStep) {
					case TutorialStep0: 0;
					case TutorialStep1: 1;
					case TutorialStep2: 2;
					case TutorialStep3: 3;
				}
				tutorialMask.animation.currentFrameIndex = tutorial.animation.currentFrameIndex;

				tutorialMask.alpha = 1.0;
			}

			for (c in candlePositions) createCandle(c.x, c.y, smallLight);

			for (m in level.l_Entities.all_MusicChange) music_thresholds.push(m);
		}

		music_thresholds.sort((a, b) -> a.worldPixelY - b.worldPixelY);
	}

	var pitch : Pitch;

	var joystick : Joystick;

	public function connect() {
		var handler = MultiplayerHandler.instance;
		if( handler != null ) {
			handler.reset();
			handler = null;
		}

		if( host != null ) {
			host.dispose();
			host = null;
			return;
		}

		var port = 9999;
		var addr = '127.0.0.1:$port';
		var useTLS = false;

		// addr = '192.168.0.123';

		#if !local_server
		addr = 'gameserver.jefvel.net/server';
		useTLS = true;
		#end

		var username = "jefvel";
		var session = "20892566.55b7121d34087661d89b21f26d3fbf78a1a322189729f0";
		var hash = haxe.crypto.Base64.urlEncode(Bytes.ofString('$username:$session'));

		host = new elk.net.Client();
		host.useTLS = useTLS;

		host.websocketProtocols = ['auth_token', hash];
		host.onConnected = () -> {
			game.console.log("Connected :)");
		}
		host.onDisconnected = () -> {
			MultiplayerHandler.instance?.reset();
		}
		host.onConnectionFailure = () -> {}

		host.onMessage = (client, m) -> {
			MultiplayerHandler.handleMessage(client, m);
		}

		host.connect(addr);
	}

	var elapsed = 0.0;

	public static var event = new hxd.WaitEvent();

	var curMusic : hxd.snd.Channel = null;

	override function update(dt : Float) {
		super.update(dt);
		if( man != null && game.timeScale > 0 ) {
			game.timeScale = man.slowdown.value;
			pitch.value = Math.max(1 / (3 / 2), game.timeScale);
			// var p = Math.max(1 + (game.timeScale - 1) * 2, 0.05);
			// pitch.gainHF = p;
		}
	}

	override function draw(ctx : RenderContext) {
		super.draw(ctx);

		if( man == null ) return;

		var w = Math.round(game.s2d.width * 0.5);
		var h = Math.round(game.s2d.height * 0.5);

		var manX = man.obj.x;
		var manY = man.obj.y;

		var camX = (-manX + w);
		var camY = (-manY + h);
		dither.offset.set(-camX, -camY);
		world.setPosition(camX, camY);
	}

	public function reset() {
		stopMusic();
		game.states.change(new PlayState());
	}

	override function on_leave() {
		super.on_leave();
		container.remove();
		man.remove();
		stopMusic();
	}

	public function freeze(time : Float = 0.1) {
		elk.Elk.instance.timeScale = 0.0;
		var t = new Timeout(time, () -> elk.Elk.instance.timeScale = 1.0);
		t.ignoreTimeScale = true;
	}

	public function createCandle(x : Float, y : Float, ?t : Tile) {
		var smallLight = t != null ? t : hxd.Res.img.small_light.toTile().center();
		var li = new Bitmap(smallLight, lights);
		li.x = x;
		li.y = y;
		var c = hxd.Res.img.candle.toSprite(objects);
		c.set_origin(0.5, 0.6);
		c.x = li.x;
		c.y = li.y;
		c.animation.play('idle');
	}

	public function spawnCandle(x : Float, y : Float) {
		for (c in candlePositions) {
			var dx = x - c.x;
			var dy = y - c.y;
			if( Math.sqrt(dx * dx + dy * dy) < 32 ) {
				candlePositions.remove(c);
			}
		}

		candlePositions.push({x : x, y : y});
		createCandle(x, y);
	}

	public var won = false;

	override function tick(dt : Float) {
		elapsed += dt;
		event.update(dt);
		objects.ysort(0);
		dither.bias += (0.01 - dither.bias) * 0.1;
		if( man.started && !man.dead && !won ) {
			runTime += dt;
		}

		var thr = music_thresholds[musicIndex];
		if( thr != null ) {
			if( thr.worldPixelY < man.y ) {
				var immediate = true;
				if( curMusic != null ) {
					var cc = curMusic;
					cc.fadeTo(0.0, 0.7, () -> cc.stop());
					immediate = false;
				}
				if( immediate ) {
					for (m in musics) playing.push(m.play(true, 0.0, game.sounds.musicChannel));
				}

				curMusic = playing[musicIndex];
				curMusic.fadeTo(0.54, immediate ? 0.0 : 1.0);

				musicIndex++;
			}
		}

		if( man.y > winY ) showWin();
		// lights.alpha += (1 - lights.alpha) * 0.1;

		if( man.dead && man.deadTime > 0.8 && !man.evaporated ) {
			man.evaporate();
			spawnCandle(man.x, man.y + 3);
		}

		if( man.dead && man.deadTime > 1.0 && man.dashPressed() ) {
			reset();
		}

		if( hxd.Key.isPressed(hxd.Key.R) ) {
			reset();
		}
	}

	function stopMusic() {
		for (m in musics) m.stop();
	}

	public function onDie() {
		stopMusic();
		deaths++;
	}

	var winText : Text;

	public function showWin() {
		if( won ) return;
		won = true;
		winText = new Text(hxd.Res.fonts.marumonica.toFont(), this);
		var timeStr = runTime.toTimeString(false);
		winText.text = 'YOU WON, CONGRATULATIONS!\n Time taken: ${timeStr} \n Tries: ${PlayState.deaths + 1}\nThanks for playing :)';
		winText.textAlign = Center;
		winText.y = 24;
		winText.x = Math.round(game.s2d.width * 0.5);
	}
}
