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
	@:s public var inventory : Inventory;

	@:s @:increment(5) public var x = 0.0;
	@:s @:increment(5) public var y = 0.0;

	public var local_x : Float = 0.0;
	public var local_y : Float = .0;

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
		trace('Player alive. $x, $y');
		if( inventory != null ) {
			trace(inventory.items);
		}
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

	override function on_disconnect() {
		super.on_disconnect();
	}
}
