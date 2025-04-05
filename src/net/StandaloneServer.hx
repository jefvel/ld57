package net;

import entities.TestEntity;
import entities.Cursor;
import elk.net.MultiplayerClient;

#if (sys || hxnodejs)
class StandaloneServer extends elk.Elk {
	var running = false;

	static var instance : StandaloneServer;

	final max_users = 100;
	final bind_address = '0.0.0.0';
	var bind_port = 9999;

	var db : elk.db.Database = null;

	var server : elk.net.Server;
	var handler : MultiplayerHandler;

	public override function init() {
		super.init();
		var port_str = Sys.environment().get("PORT");
		if( port_str != null ) {
			bind_port = Std.parseInt(port_str);
		}

		server = new elk.net.Server(bind_address, bind_port, 100, true);
		handler = new MultiplayerHandler(server.host);

		#if hxbit_visibility
		server.host.rootObject = handler;
		#end

		db = new elk.db.Database({type : SQLite, file : 'data/database.db'});

		server.on_client_connected = (player) -> {
			trace('server: client connect: ${player}');
			handler.addClient(player);
		}

		server.on_client_disconnected = (player) -> {
			trace('server: client disconnect: $player');
			handler.removeClient(player);
		}

		for (i in 0...1000) {
			var e = new TestEntity();
			e.posX = Std.random(400);
			e.posY = Std.random(400);
		}

		Sys.println('✅ Listening on $bind_address:$bind_port');
	}

	public function exit(code : Int = 0) {
		if( server != null ) server.stop();
		if( db != null ) db.close();

		running = false;

		Sys.println('Server shutdown gracefully');
		Sys.exit(code);
	}

	static function handleError(e : String) {
		var exitCode = 1;
		if( !StringTools.startsWith(e, "SIGNAL") ) {
			trace(e);
		} else {
			var signal = Std.parseInt(e.split(" ")[1]);
			if( signal == 15 || signal == 2 ) {
				exitCode = 0;
			}
		}

		if( instance != null ) {
			instance.exit(exitCode);
		} else {
			Sys.exit(exitCode);
		}
	}

	var lastTime = 0.0;

	override function update(dt : Float) {
		super.update(dt);
		var newTime = haxe.Timer.stamp();
		dt = newTime - lastTime;
		lastTime = newTime;

		if( server == null ) {
			Sys.sleep(1.0);
			return;
		}

		server.update(dt);
		// Sleep long if no players are connected.
		if( server.host.clients.length == 0 ) {
			Sys.sleep(1.0 / 10.0);
		} else {
			Sys.sleep(1.0 / 60.0);
		}
	}

	public static function main() {
		try {
			haxe.System.errorHandler = handleError;
			hxd.Res.initEmbed({includedPaths : ['db', 'data.cdb']});
			elk.Elk.type = Dedicated;
			instance = new StandaloneServer();
		} catch (e) {
			handleError(e.toString());
		}
	}
}
#else
class StandaloneServer {}
#end
