package net;

import hxbit.VisibilityGroup;
import hxbit.NetworkSerializable;

class Item implements hxbit.Serializable {
	@:s var id : Int;
	@:s var name : String;

	public function new(id, name) {
		this.id = id;
		this.name = name;
	}

	public function toString() {
		return '$id - $name';
	}
}

class Inventory implements hxbit.Serializable {
	@:s public var items : Array<Item>;

	public function new() {
		items = [];
	}

	public function add_item(item) {
		items.push(item);
	}
}

@:keepSub
class MultiplayerPlayer extends elk.net.MultiplayerClient {
	@:s @:visible(sameRoom) public var roomId(default, set) : Int = 0;
	@:s @:visible(self) public var inventory : Inventory;

	@:s @:visible(sameRoom) @:increment(5) public var x = 0.0;
	@:s @:visible(sameRoom) @:increment(5) public var y = 0.0;

	public var local_x : Float = 0.0;
	public var local_y : Float = .0;

	public var cursor : entities.Cursor;

	public function new(c, h) {
		super(c, h);

		#if sys
		var session = elk.newgrounds.NGWebSocketHandler.get_session_info(client);
		if( session != null ) {
			trace(session.username, session.session_id);
			// uid = session.username;
		}
		#end

		x = Std.random(200);
		y = Std.random(200);
		roomId = 1;
		inventory = new Inventory();
		inventory.add_item(new Item(50, 'test item'));

		trace('new playeree');
	}

	public override function alive() {
		trace("multiplyer alive..");
		MultiplayerHandler.instance.registerPlayer(this);
		super.alive();
		local_x = x;
		local_y = y;
		cursor = new entities.Cursor(elk.Elk.instance?.s2d, this);
		trace('Player alive. $x, $y');
		if( inventory != null ) {
			trace(inventory.items);
		}
	}

	@:rpc(server)
	public function changeRoom(id : Int) {
		this.roomId = id;
		#if hxbit_visibility
		var handler = net.MultiplayerHandler.instance;
		for (c in handler.players) {
			c.setVisibilityDirty(SameRoom);
		}
		for (c in handler.entities) {
			c.setVisibilityDirty(SameRoom);
		}
		#end
	}

	public override function networkAllow(op : hxbit.NetworkSerializable.Operation, propId : Int, client : hxbit.NetworkSerializable) : Bool {
		if( op == RPCServer ) {
			return client == this;
		}

		if( !super.networkAllow(op, propId, client) ) {
			return false;
		}

		var allow = client == this;
		return allow;
	}

	public override function evalVisibility(group : hxbit.VisibilityGroup, from : hxbit.NetworkSerializable) : Bool {
		if( group == Self ) {
			return from == this;
		}
		if( group == SameRoom ) {
			if( from is MultiplayerPlayer ) {
				var player = cast(from, MultiplayerPlayer);
				return roomId == player.roomId;
			}
			if( from is entities.NetworkEntity ) {
				var e = cast(from, entities.NetworkEntity);
				return roomId == e.roomId;
			}

			return false;
		}
		return true;
	}

	@:rpc(immediate)
	@:visible(sameRoom)
	public function blink() {
		cursor?.blink();
		if( host?.isAuth ) {
			var removed = 0;
			for (e in MultiplayerHandler.instance.entities) {
				if( e is entities.TestEntity ) {
					var te = cast(e, entities.TestEntity);
					var dx = x - te.posX;
					var dy = y - te.posY;
					if( dx * dx + dy * dy < 30 * 30 ) {
						e.remove();
						removed++;
					}
				}
			}
			trace('remvoed $removed guys');
			/*
				var e = new entities.TestEntity();
				e.changeRoom(this.roomId);
				e.posX = this.x;
				e.posY = this.y;
			 */
		}
	}

	override function on_disconnect() {
		super.on_disconnect();
		if( cursor != null ) {
			cursor.remove();
			cursor = null;
		}
	}

	function set_roomId(id) {
		return this.roomId = id;
	}
}
