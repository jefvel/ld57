package entities;

@:keepSub
class NetworkEntity implements hxbit.NetworkSerializable extends elk.entity.Entity {
	@:s public var roomId = 0;

	private var isAlive = false;

	public function new() {
		super();
		roomId = 1;
		enableReplication = true;
	}

	public function onAlive() {
		isAlive = true;
		elk.Elk.instance.entities.add(this);
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

	public function evalVisibility(group : hxbit.VisibilityGroup, from : hxbit.NetworkSerializable) : Bool {
		if( group == Self ) {
			return from == this;
		}
		if( group == SameRoom ) {
			if( from is net.MultiplayerPlayer ) {
				var player = cast(from, net.MultiplayerPlayer);
				return roomId == player.roomId;
			}
			if( from is NetworkEntity ) {
				var e = cast(from, NetworkEntity);
				return roomId == e.roomId;
			}

			return false;
		}
		return true;
	}

	public function onUnregister() {}

	public function alive() {
		#if (target.threaded)
		haxe.MainLoop.runInMainThread(onAlive);
		#else
		onAlive();
		#end
	}
}
