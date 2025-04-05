package gamestates;

import elk.input.Input;
import net.MultiplayerPlayer;
import h2d.RenderContext;
import elk.graphics.Sprite;
import net.MultiplayerHandler;
import entities.Cursor;
import elk.input.Joystick;
import haxe.io.Bytes;
import elk.util.ResTools;
import h2d.Tile;
import h2d.Bitmap;
import h2d.Object;
import h2d.Layers;
import entities.TestEntity;
import hxd.res.DefaultFont;
import h2d.Text;
import elk.gamestate.GameState;

private class TT implements elk.util.RectPacker.RectPackNode {
	public var bmp : h2d.Bitmap;

	public var width = 1;
	public var height = 0;
	public var x : Int = 0;
	public var y : Int = 0;

	public function new(p) {
		width = Std.random(200) + 8;
		height = Std.random(200) + 8;
		bmp = new h2d.Bitmap(h2d.Tile.fromColor(Std.int(Math.random() * 0xffffff), width, height), p);
	}
}

class PlayState extends GameState {
	var time = 0.;
	var tickRateTxt : Text;

	var intX = new elk.util.InterpolatedFloat();

	public static var instance : PlayState;

	public var container = new Object();

	public var objects : Layers;

	public static var cursor : Cursor;

	public static var host : elk.net.Client;

	var txt : h2d.Text;

	override function on_enter() {
		instance = this;
		elk.Elk.instance.console.add('exit', () -> Sys.exit(0));
		addChild(container);
		// container.filter = new h2d.filter.Nothing();

		objects = new Layers(container);

		// createRectPack();

		var l = new assets.LDTKProject(hxd.Res.levels.map.entry.getJsonText());
		for (level in l.all_worlds.Default.levels) trace(level.identifier);

		tickRateTxt = new Text(DefaultFont.get(), container);
		tickRateTxt.textColor = 0xffffff;

		var b = new Bitmap(Tile.fromColor(0xff111111), this);
		b.alpha = 0.8;
		b.width = game.s2d.width;
		txt = new Text(hxd.Res.fonts.LibreBaskerville_Regular.toSdfFont(8, h2d.Font.SDFChannel.MultiChannel), this);
		txt.y = 4;
		txt.x = 4;
		txt.rotation = -0.02;
		txt.text = "-";
		b.height = txt.y * 2 + txt.textHeight;

		ResTools.load_named_pak(TestPak, () -> {
			trace('loaded pak');
			/*
				var b = new h2d.Bitmap(hxd.Res.additional_data.ball_copy_2.toTile(), container);
				b.y = 50;
				b.scale(0.04);
			 */
		}, (p : Float) -> {
			txt.text = 'additional loaded ${Math.round(p * 100)}%';
		});

		connect();

		elk.Elk.instance.console.add('he', () -> {
			trace('doing call');
			var req = new elk.net.http.AsyncHttpRequest('https://httpbin.org/delay/1');
			req.onResponse = (e, r) -> {
				trace('${r.statusCode}: ${e}');
			}
			req.run();
			trace('did call.');
		});

		joystick = new Joystick(Left, this);
		spri = hxd.Res.img.ball_copy.toSprite(container);
		spri.x = spri.y = 40;
		spri.animation.play("aaaa");
		blob = hxd.Res.img.blob.toSprite(container);
		blob.center_origin();
		spri.center_origin();

		// var s = hxd.Res.img.ab_avatar_24_squid_edits.toSprite(container);
		// s.x = s.y = 100;
		// spri.animation.play("ddd");
	}

	var spri : Sprite;
	var blob : Sprite;

	var joystick : Joystick;

	var rectContainer : h2d.Object;

	function createRectPack() {
		var packer = new elk.util.RectPacker<TT>(256, 256);
		if( rectContainer == null ) {
			rectContainer = new h2d.Object(container);
			rectContainer.scale(0.5);
		}
		rectContainer.removeChildren();
		for (i in 0...300) {
			var r = new TT(rectContainer);
			packer.add(r);
		}

		for (i in 0...300) {
			var r = new TT(rectContainer);
			r.width = 16 + Std.random(16);
			r.height = 16 + Std.random(16);
			r.bmp.width = r.width;
			r.bmp.height = r.height;
			packer.add(r);
		}

		for (r in @:privateAccess packer.nodes) {
			r.bmp.x = r.x;
			r.bmp.y = r.y;
			// r.bmp.visible = false;
			r.bmp.alpha = 0.3;
		}

		for (r in @:privateAccess packer.freeRects) {
			var bmp = new h2d.Bitmap(h2d.Tile.fromColor(0xffffff, r.width, r.height, 0.2));
			bmp.x = r.x;
			bmp.y = r.y;
			// rectContainer.addChild(bmp);
		}
		trace('packer size: ${packer.width}x${packer.height}');
	}

	public function connect() {
		cursor = null;
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
			txt.text = "Connected :)";
		}
		host.onDisconnected = () -> {
			txt.text = "Disconnected.";
			MultiplayerHandler.instance?.reset();
		}
		host.onConnectionFailure = () -> {
			txt.text = "Failed to connect.";
		}

		host.onMessage = (client, m) -> {
			MultiplayerHandler.handleMessage(client, m);
		}

		host.connect(addr);
	}

	var elapsed = 0.0;

	public static var event = new hxd.WaitEvent();

	override function draw(ctx : RenderContext) {
		super.draw(ctx);
		if( spri == null ) return;
		var sli = spri.animation.getSlice("top");
		if( sli != null ) {
			blob.x = sli.x + spri.x - spri.originX + intX.value;
			blob.y = sli.y + spri.y - spri.originY;
		}
	}

	override function update(dt : Float) {
		super.update(dt);
		if( Input.isKeyDown(hxd.Key.U) ) {
			elk.Elk.instance.timeScale += (0.5 - elk.Elk.instance.timeScale) * 0.1;
		} else {
			elk.Elk.instance.timeScale += (1 - elk.Elk.instance.timeScale) * 0.1;
		}
	}

	override function tick(dt : Float) {
		elapsed += dt;
		event.update(dt);
		spri.rotation = Math.sin(elapsed) * 0.1;
		intX.value = Math.sin(elk.Elk.instance.scaledTime) * 100 + 100;

		var self = MultiplayerHandler.instance?.self;
		if( self != null ) {
			cursor = self?.cursor;
			if( Input.isKeyPressed(hxd.Key.T) ) {
				self.changeRoom(self.roomId + 1);
			}
		}

		super.tick(dt);
		time += dt;

		if( Input.isKeyPressed(hxd.Key.R) ) {
			connect();
		}

		if( Input.isKeyPressed(hxd.Key.F) ) createRectPack();

		if( cursor != null && self != null ) {
			/*
				self.x = game.s2d.mouseX;
				self.y = game.s2d.mouseY;
			 */
			var d = Input.getVector(hxd.Key.A, hxd.Key.D, hxd.Key.W, hxd.Key.S);
			if( d.lengthSq() == 0 ) {
				d.x = joystick.mx;
				d.y = joystick.my;
			}
			self.local_x += d.x * self.cursor.max_speed;
			self.local_y += d.y * self.cursor.max_speed;
			if( Input.isKeyPressed(hxd.Key.SPACE) ) {
				self.blink();
			}
		}

		if( host != null && elapsed > 0.1 ) {
			elapsed -= 0.1;
			host.flush();
		}

		tickRateTxt.text = CastleDB.texts.get(Hello).Text;
		tickRateTxt.x = game.s2d.width - tickRateTxt.textWidth - 4;
		tickRateTxt.y = game.s2d.height - tickRateTxt.textHeight - 2;
		objects.ysort(0);
	}
}
