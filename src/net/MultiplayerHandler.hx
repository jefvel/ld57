package net;

import elk.Elk;
import entities.NetworkEntity;
import net.MultiplayerPlayer;
import hxbit.NetworkHost.NetworkClient;
import hxbit.NetworkSerializable;

typedef NWEntity = NetworkEntity;
typedef MPClient = MultiplayerPlayer;

/**
 * Keeps track of connected players, both on client side and server (instantiated on host, and synced to clients.)
 */
class MultiplayerHandler implements hxbit.NetworkSerializable {
	public static var instance : MultiplayerHandler;

	@:s public var players : Array<MPClient> = [];

	@:s
	public var entities : Array<NWEntity> = [];

	public var host(default, null) : hxbit.NetworkHost = null;

	public var self : MPClient;

	private var elk : Elk;

	private static var own_uid : String = null;

	public dynamic function on_object_unregister(o : hxbit.NetworkSerializable) {}

	public function on_player_connected(p : MPClient) {}

	public function on_player_disconnected(p : MPClient) {}

	public function new(host : hxbit.NetworkHost) {
		instance = this;
		elk = Elk.instance;
		this.host = host;
		host.self.ownerObject = this;
		enableReplication = true;

		elk.entities.onEntityAdded.addListener(onHostEntityAdded);
		elk.entities.onEntityRemoved.addListener(onHostEntityRemoved);
	}

	function onHostEntityAdded(e) {
		if( e is NWEntity ) {
			var ce = cast(e, NWEntity);
			entities.push(ce);
		}
	}

	function onHostEntityRemoved(e) {
		if( e is NWEntity ) {
			var ne = cast(e, NWEntity);
			entities.remove(ne);
			ne.enableReplication = false;
		}
	}

	public function reset() {
		for (c in players) remove_player(c);
		for (e in entities) e.onUnregister();

		if( elk != null ) {
			elk.entities.onEntityAdded.removeListener(onHostEntityAdded);
			elk.entities.onEntityRemoved.removeListener(onHostEntityRemoved);
		}

		self = null;
		own_uid = null;
		host = null;
	}

	public function addClient(client : hxbit.NetworkHost.NetworkClient) {
		var player = new Main.MPClient(client, host);
		if( !players.contains(player) ) players.push(player);

		if( player.uid == own_uid ) {
			player.client = host.self;
			player.client.ownerObject = player;
			self = player;
		}

		client.sendMessage('uid:${player.uid}');
		client.sync();

		on_player_connected(player);
	}

	public function removeClient(client : hxbit.NetworkHost.NetworkClient) {
		var player = getPlayer(client);
		if( player == null ) return;
		remove_player(player);
	}

	function getPlayer(c : NetworkClient) {
		for (p in players) {
			if( p.client == c ) return p;
		}
		return null;
	}

	public function remove_player(c : MPClient) {
		if( host?.isAuth ) {
			if( c.enableReplication ) c.enableReplication = false;
			players.remove(c);
		}
		c.on_disconnect();
		on_player_disconnected(c);
	}

	public function registerPlayer(p : MPClient) {
		trace('${p.uid}, own: $own_uid');
		if( p.uid == own_uid ) {
			@:privateAccess p.is_self = true;
			self = p;
			host.self.ownerObject = p;
		}
	}

	public function alive() {
		instance = this;
		host = hxbit.NetworkHost.current;

		host.onUnregister = (e) -> {
			if( e is MPClient ) {
				remove_player(cast e);
			}
			if( e is NWEntity ) {
				cast(e, NWEntity).onUnregister();
			}
			on_object_unregister(e);
		}
	}

	public static function handleMessage(c : hxbit.NetworkHost.NetworkClient, m : Dynamic) {
		if( m is String && StringTools.startsWith(m, 'uid:') ) {
			var split = cast(m, String).split(':');
			var uid = split[1];
			set_own_uid(uid);
		}
	}

	public static function set_own_uid(uid : String) {
		own_uid = uid;
	}

	public function get_own_uid() {
		return own_uid;
	}
}
